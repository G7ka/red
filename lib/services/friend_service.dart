import 'package:supabase_flutter/supabase_flutter.dart';
import 'fcm_service.dart';

class FriendService {
  FriendService._();
  static final FriendService instance = FriendService._();

  final _supabase = Supabase.instance.client;

  /// Sends a friend request to [toUid].
  /// Returns true if successful.
  Future<bool> sendFriendRequest({
    required String toUid,
    String? chatId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null || user.id == toUid) return false;

    try {
      // Check if relationship already exists
      final existing = await _supabase
          .from('relationships')
          .select()
          .or('and(sender_id.eq.${user.id},receiver_id.eq.$toUid),and(sender_id.eq.$toUid,receiver_id.eq.${user.id})')
          .maybeSingle();

      if (existing != null) {
        // Already friends or pending
        return false;
      }

      await _supabase.from('relationships').insert({
        'sender_id': user.id,
        'receiver_id': toUid,
        'status': 'pending',
      });

      // Send Notification
      final fromUser = await _supabase.from('users').select('display_name').eq('id', user.id).single();
      final fromName = fromUser['display_name'] as String? ?? 'Someone';

      await FCMService.instance.sendPushNotification(
        toUid: toUid,
        title: 'New Friend Request',
        body: '$fromName sent you a friend request',
        data: {
          'type': 'friend_request',
          'from_uid': user.id,
          'fromName': fromName,
        },
      );
      
      return true;
    } catch (e) {
      print('Error sending friend request: $e');
      return false;
    }
  }

  /// Accepts a friend request from [fromUid].
  Future<bool> acceptFriendRequest(String fromUid) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      await _supabase
          .from('relationships')
          .update({'status': 'accepted'})
          .match({
            'sender_id': fromUid, 
            'receiver_id': user.id,
            'status': 'pending'
          });

      // Update any existing anonymous chat to 'friend' type
      // We search for chats containing BOTH users
      try {
        // Need to find chat with generic participants check. 
        // Postgrest 'contains' works for array columns.
        await _supabase.from('chats').update({
          'type': 'friend',
          'is_anonymous_active': false, // Convert to non-anonymous
        }).contains('participants', [user.id, fromUid]);
      } catch (e) {
        print('Error updating chat type: $e');
      }

      return true;
    } catch (e) {
      print('Error accepting friend request: $e');
      return false;
    }
  }

  /// Rejects or cancels a friend request.
  Future<bool> removeFriendOrRequest(String otherUid) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      await _supabase
          .from('relationships')
          .delete()
          .or('and(sender_id.eq.${user.id},receiver_id.eq.$otherUid),and(sender_id.eq.$otherUid,receiver_id.eq.${user.id})');
      return true;
    } catch (e) {
      print('Error removing friend: $e');
      return false;
    }
  }

  /// Blocks a user.
  Future<void> blockUser(String blockedUid) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Upsert to ensure we overwrite any existing relationship
      // Note: This logic assumes a unique constraint on (sender_id, receiver_id) might not handle both directions easily
      // A better block system usually involves a separate 'blocks' table, but adhering to the plan using 'relationships'
      
      // First delete any existing relationship
      await removeFriendOrRequest(blockedUid);

      // Insert block
      await _supabase.from('relationships').insert({
        'sender_id': user.id,
        'receiver_id': blockedUid,
        'status': 'blocked',
      });
    } catch (e) {
      print('Error blocking user: $e');
    }
  }

  /// Stream of pending friend requests received by the current user.
  /// Returns a stream of profiles who sent the request.
  Stream<List<Map<String, dynamic>>> getPendingFriendRequestsStream() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('relationships')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', user.id)
        .asyncMap((data) async {
          // Filter for pending requests manually since stream() has filter limitations
          final pendingRequests = data.where((r) => r['status'] == 'pending').toList();
          
          if (pendingRequests.isEmpty) return [];
          
          final senderIds = pendingRequests.map((e) => e['sender_id'] as String).toList();
          if (senderIds.isEmpty) return [];

          try {
            final profiles = await _supabase
                .from('users')
                .select()
                .inFilter('id', senderIds);
            
            // Map profile data back to the request structure or just return profiles with request ID
            return List<Map<String, dynamic>>.from(profiles.map((p) {
               final req = data.firstWhere((r) => r['sender_id'] == p['id']);
               return {
                 ...p,
                 'request_id': req['id'],
                 'created_at': req['created_at'],
               };
            }));
          } catch (e) {
            print('Error fetching request profiles: $e');
            return [];
          }
        });
  }

  /// Checks if [targetUserId] is a friend.
  Future<bool> isFriend(String targetUserId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final res = await _supabase
          .from('relationships')
          .select()
          .eq('status', 'accepted')
          .or('and(sender_id.eq.${user.id},receiver_id.eq.$targetUserId),and(sender_id.eq.$targetUserId,receiver_id.eq.${user.id})')
          .maybeSingle();
      return res != null;
    } catch (e) {
      return false;
    }
  }
}
