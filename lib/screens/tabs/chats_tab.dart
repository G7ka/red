import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/chat_service.dart';
import '../chat/anonymous_chat_screen.dart';
import '../chat/friends_chat_screen.dart';

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final chatService = ChatService.instance;
    final currentUserId = supabase.auth.currentUser?.id;

    if (currentUserId == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 24,
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        title: const Text(
          'Chats',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: chatService.getUserChatsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF7C3AED).withOpacity(0.12),
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        size: 36,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No connection',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your connection and try again.',
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final allChats = snapshot.data ?? [];
          final chats = allChats.where((chat) {
            final type = chat['type'] as String? ?? 'anonymous';
            if (type == 'anonymous') {
              final isActive =
                  chat['is_anonymous_active'] as bool? ?? true;
              return isActive;
            }
            return true;
          }).toList();

          if (chats.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF7C3AED).withOpacity(0.12),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 36,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No chats yet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start an anonymous search to meet new people!',
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(top: 4, bottom: 100),
            itemCount: chats.length,
            separatorBuilder: (_, __) => Padding(
              padding: const EdgeInsets.only(left: 82),
              child: Divider(
                  color: Colors.white.withOpacity(0.05), height: 1),
            ),
            itemBuilder: (context, index) {
              final chatData = chats[index];
              final participants =
                  List<String>.from(chatData['participants'] ?? []);
              final chatType =
                  chatData['type'] as String? ?? 'anonymous';
              final otherUserId = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );

              if (otherUserId.isEmpty) return const SizedBox.shrink();

              return FutureBuilder<Map<String, dynamic>?>(
                future: supabase
                    .from('users')
                    .select()
                    .eq('id', otherUserId)
                    .maybeSingle(),
                builder: (context, userSnapshot) {
                  final userData = userSnapshot.data;
                  final userName =
                      userData?['display_name'] as String? ?? 'Unknown';
                  final userImage =
                      userData?['image_url'] as String?;
                  final isAnonymous = chatType == 'anonymous';

                  return _ChatTile(
                    chatId: chatData['id'] as String,
                    userName: isAnonymous ? 'Anonymous Penguin' : userName,
                    userImage: isAnonymous ? null : userImage,
                    isAnonymous: isAnonymous,
                    otherUserId: otherUserId,
                    currentUserId: currentUserId,
                    chatService: chatService,
                    onTap: () {
                      if (isAnonymous) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AnonymousChatScreen(
                              chatId: chatData['id'] as String,
                            ),
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FriendsChatScreen(
                              chatId: chatData['id'] as String,
                              otherUserId: otherUserId,
                              otherUserName: userName,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String chatId;
  final String userName;
  final String? userImage;
  final bool isAnonymous;
  final String otherUserId;
  final String currentUserId;
  final ChatService chatService;
  final VoidCallback onTap;

  const _ChatTile({
    required this.chatId,
    required this.userName,
    required this.userImage,
    required this.isAnonymous,
    required this.otherUserId,
    required this.currentUserId,
    required this.chatService,
    required this.onTap,
  });

  String _formatTime(String? createdAt) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0 && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: chatService.getMessagesStream(chatId),
          builder: (context, msgSnapshot) {
            final messages = msgSnapshot.data ?? [];
            final lastMsg = messages.isNotEmpty ? messages.last : null;

            // Get last message text
            String previewText = 'No messages yet';
            String timeText = '';
            bool hasUnread = false;
            int unreadCount = 0;

            if (lastMsg != null) {
              final type = lastMsg['type'] as String? ?? 'text';
              if (type == 'image') {
                previewText = '📷 Photo';
              } else if (type == 'audio') {
                previewText = '🎤 Voice message';
              } else if (type == 'call') {
                previewText = '📞 Call';
              } else {
                previewText = lastMsg['text'] as String? ?? '';
              }
              timeText = _formatTime(lastMsg['created_at'] as String?);

              // Count unread (messages from other user)
              for (final msg in messages) {
                if (msg['sender_id'] != currentUserId) {
                  unreadCount++;
                }
              }
              // Simple heuristic: show unread dot if last message is from other user
              if (lastMsg['sender_id'] != currentUserId) {
                hasUnread = true;
              }
            }

            return Row(
              children: [
                // Avatar - 54×54
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isAnonymous
                        ? const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isAnonymous ? null : const Color(0xFF1A1A2E),
                    border: isAnonymous
                        ? null
                        : Border.all(
                            color: const Color(0xFF7C3AED).withOpacity(0.3),
                            width: 2,
                          ),
                    image: userImage != null
                        ? DecorationImage(
                            image: NetworkImage(userImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: userImage == null
                      ? Icon(
                          isAnonymous ? Icons.pets : Icons.person,
                          color: Colors.white.withOpacity(0.8),
                          size: 24,
                        )
                      : null,
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Name + Time
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeText,
                            style: TextStyle(
                              color: hasUnread
                                  ? const Color(0xFF7C3AED)
                                  : Colors.white.withOpacity(0.35),
                              fontSize: 12,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Row 2: Preview + Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              previewText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: hasUnread
                                    ? Colors.white.withOpacity(0.6)
                                    : Colors.white.withOpacity(0.35),
                                fontSize: 14,
                                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Badge or Anon pill
                          if (isAnonymous)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${messages.length}/10',
                                style: const TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else if (hasUnread)
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: Color(0xFF7C3AED),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
