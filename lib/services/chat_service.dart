import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

import 'fcm_service.dart';

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final _supabase = Supabase.instance.client;

  // Typing channels cache
  final Map<String, RealtimeChannel> _typingChannels = {};

  // ============ CREATE CHAT ============

  Future<String?> createChat(List<String> participants,
      {bool isAnonymous = false}) async {
    try {
      final res = await _supabase
          .from('chats')
          .insert({
            'participants': participants,
            'type': isAnonymous ? 'anonymous' : 'friend',
            'is_anonymous_active': isAnonymous,
          })
          .select()
          .single();
      return res['id'] as String;
    } catch (e) {
      print('Error creating chat: $e');
      return null;
    }
  }

  // ============ SEND MESSAGES ============

  Future<void> sendTextMessage({
    required String chatId,
    required String toUid,
    required String text,
    required bool isAnonymous,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('messages').insert({
      'chat_id': chatId,
      'sender_id': user.id,
      'text': text,
      'type': 'text',
      'read_by': [],
    });

    // Update chat last message timestamp
    try {
      await _supabase.from('chats').update({
        'last_message': text,
        'last_message_time': DateTime.now().toIso8601String(),
      }).eq('id', chatId);
    } catch (_) {}

    // Send push notification
    final fromUser = await _supabase
        .from('users')
        .select('display_name')
        .eq('id', user.id)
        .maybeSingle();
    final fromName = fromUser?['display_name'] as String? ?? 'Someone';

    await FCMService.instance.sendPushNotification(
      toUid: toUid,
      title: isAnonymous ? 'Anonymous penguin' : fromName,
      body: text,
      data: {
        'type': 'message',
        'chatId': chatId,
        'fromUid': user.id,
      },
    );
  }

  Future<void> sendImageMessage({
    required String chatId,
    required String toUid,
    required File imageFile,
    required bool isAnonymous,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${user.id}.jpg';
    final storagePath = 'chat_images/$fileName';

    await _supabase.storage.from('chat-images').upload(storagePath, imageFile);
    final url =
        _supabase.storage.from('chat-images').getPublicUrl(storagePath);

    await _supabase.from('messages').insert({
      'chat_id': chatId,
      'sender_id': user.id,
      'text': '',
      'type': 'image',
      'media_url': url,
      'read_by': [],
    });

    try {
      await _supabase.from('chats').update({
        'last_message': '📷 Photo',
        'last_message_time': DateTime.now().toIso8601String(),
      }).eq('id', chatId);
    } catch (_) {}
  }

  Future<void> sendVoiceMessage({
    required String chatId,
    required String toUid,
    required File audioFile,
    required bool isAnonymous,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${user.id}.m4a';
    final storagePath = 'chat_audio/$fileName';

    await _supabase.storage.from('chat-audio').upload(storagePath, audioFile);
    final url =
        _supabase.storage.from('chat-audio').getPublicUrl(storagePath);

    await _supabase.from('messages').insert({
      'chat_id': chatId,
      'sender_id': user.id,
      'text': '',
      'type': 'audio',
      'media_url': url,
      'read_by': [],
    });

    try {
      await _supabase.from('chats').update({
        'last_message': '🎤 Voice message',
        'last_message_time': DateTime.now().toIso8601String(),
      }).eq('id', chatId);
    } catch (_) {}
  }

  // ============ MARK AS SEEN ============

  Future<void> markMessagesAsSeen(String chatId, String userId) async {
    try {
      // Get unread messages sent TO this user
      final messages = await _supabase
          .from('messages')
          .select('id, read_by')
          .eq('chat_id', chatId)
          .neq('sender_id', userId)
          .limit(50);

      for (final msg in messages) {
        final readBy = List<String>.from(msg['read_by'] ?? []);
        if (!readBy.contains(userId)) {
          readBy.add(userId);
          await _supabase
              .from('messages')
              .update({'read_by': readBy}).eq('id', msg['id']);
        }
      }
    } catch (e) {
      print('Error marking messages as seen: $e');
    }
  }

  // ============ MESSAGE COUNT ============

  Future<int> getMessageCount(String chatId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('id')
          .eq('chat_id', chatId);
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // ============ EXIT ANONYMOUS CHAT ============

  Future<void> exitAnonymousChat(String chatId) async {
    await _supabase
        .from('chats')
        .update({'is_anonymous_active': false}).eq('id', chatId);
  }

  // ============ STREAMS ============

  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true);
  }

  Stream<List<Map<String, dynamic>>> getUserChatsStream() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((chats) {
      // Filter to only chats where user is a participant
      return chats.where((chat) {
        final participants = List<String>.from(chat['participants'] ?? []);
        return participants.contains(user.id);
      }).toList();
    });
  }

  // ============ TYPING INDICATORS (Realtime Broadcast) ============

  Future<void> setTyping(String chatId, String userId, bool isTyping) async {
    final channel = _getOrCreateTypingChannel(chatId);
    channel.sendBroadcastMessage(
      event: 'typing',
      payload: {'user_id': userId, 'is_typing': isTyping},
    );
  }

  Stream<Map<String, dynamic>> getTypingStream(String chatId) {
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    final channel = _getOrCreateTypingChannel(chatId);
    channel.onBroadcast(
      event: 'typing',
      callback: (payload) {
        controller.add(payload as Map<String, dynamic>);
      },
    );
    return controller.stream;
  }

  RealtimeChannel _getOrCreateTypingChannel(String chatId) {
    if (_typingChannels.containsKey(chatId)) {
      return _typingChannels[chatId]!;
    }
    final channel = _supabase.channel('typing:$chatId');
    channel.subscribe();
    _typingChannels[chatId] = channel;
    return channel;
  }

  void leaveTypingChannel(String chatId) {
    final channel = _typingChannels.remove(chatId);
    if (channel != null) {
      _supabase.removeChannel(channel);
    }
  }

  // ============ ONLINE STATUS ============

  Future<void> updateOnlineStatus(bool isOnline) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('users').update({
        'is_online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  Stream<Map<String, dynamic>> getOnlineStatusStream(String userId) {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) {
      if (data.isNotEmpty) return data.first;
      return {};
    });
  }

  // ============ MUTUAL ADD REQUEST SYSTEM ============

  /// Updates the current user's add request decision on a chat.
  /// The `add_requests` column is a jsonb like: {"userId1": true, "userId2": false}
  Future<void> updateAddRequest(String chatId, bool accepted) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Fetch current add_requests
      final chat = await _supabase
          .from('chats')
          .select('add_requests')
          .eq('id', chatId)
          .single();

      final addRequests = Map<String, dynamic>.from(chat['add_requests'] ?? {});
      addRequests[user.id] = accepted;

      await _supabase
          .from('chats')
          .update({'add_requests': addRequests})
          .eq('id', chatId);
    } catch (e) {
      print('Error updating add request: $e');
    }
  }

  /// Stream the chat document itself (for listening to add_requests changes)
  Stream<Map<String, dynamic>> getChatStream(String chatId) {
    return _supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .eq('id', chatId)
        .map((data) {
      if (data.isNotEmpty) return data.first;
      return {};
    });
  }

  /// Check if both users have agreed to add each other
  bool isMutualAdd(Map<String, dynamic> addRequests, List<String> participants) {
    if (addRequests.isEmpty) return false;
    for (final uid in participants) {
      if (addRequests[uid] != true) return false;
    }
    return true;
  }

  /// Convert an anonymous chat to a friend chat (mutual reveal)
  Future<void> convertToFriendChat(String chatId) async {
    await _supabase.from('chats').update({
      'type': 'friend',
      'is_anonymous_active': false,
    }).eq('id', chatId);
  }

  /// Send a system message (e.g., "User left the chat", "You are now friends!")
  Future<void> sendSystemMessage(String chatId, String text) async {
    await _supabase.from('messages').insert({
      'chat_id': chatId,
      'sender_id': 'system',
      'text': text,
      'type': 'system',
      'read_by': [],
    });

    try {
      await _supabase.from('chats').update({
        'last_message': text,
        'last_message_time': DateTime.now().toIso8601String(),
      }).eq('id', chatId);
    } catch (_) {}
  }
}
