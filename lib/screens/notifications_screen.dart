import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/notification_service.dart';
import '../services/friend_service.dart';
import 'chat/friends_chat_screen.dart';
import 'chat/anonymous_chat_screen.dart';
import 'welcome_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _supabase = Supabase.instance.client;
  final _notificationService = NotificationService.instance;
  final _friendService = FriendService.instance;

  // Local set of notification IDs that have been marked as read this session.
  // This ensures the UI updates instantly even if the Supabase stream is slow.
  final Set<String> _locallyMarkedRead = {};

  bool _parseIsRead(dynamic value) {
    if (value == true) return true;
    if (value == false || value == null) return false;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  Future<void> _markRead(String notifId) async {
    setState(() {
      _locallyMarkedRead.add(notifId);
    });
    try {
      await _notificationService.markAsRead(notifId);
    } catch (_) {
      if (mounted) {
        setState(() {
          _locallyMarkedRead.remove(notifId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'Read all',
              style: TextStyle(color: Color(0xFF7C3AED), fontSize: 13),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF7C3AED),
              ),
            );
          }

          final notifications = snapshot.data ?? [];
          _currentNotifications = notifications;
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'You\'ll see notifications here when you receive likes, comments, or friend requests',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index];
              final notifId = data['id'] as String? ?? '';
              final type = data['type'] as String? ?? '';
              // Use the local override if we've tapped it, otherwise use the DB value
              final isRead = _locallyMarkedRead.contains(notifId) ||
                  _parseIsRead(data['is_read']);
              final notificationData =
                  data['data'] as Map<String, dynamic>? ?? {};
              final fromName = notificationData['fromName'] as String? ??
                  (type == 'welcome' ? 'Team Penguin' : 'Someone');

              final createdAt = data['created_at'] as String?;
              String timeAgo = '';
              if (createdAt != null) {
                final dt = DateTime.tryParse(createdAt);
                if (dt != null) {
                  final diff = DateTime.now().toUtc().difference(dt);
                  if (diff.inMinutes < 1) {
                    timeAgo = 'Just now';
                  } else if (diff.inMinutes < 60) {
                    timeAgo = '${diff.inMinutes}m ago';
                  } else if (diff.inHours < 24) {
                    timeAgo = '${diff.inHours}h ago';
                  } else {
                    timeAgo = '${diff.inDays}d ago';
                  }
                }
              }

              String title = '';
              String subtitle = '';
              IconData icon = Icons.notifications;
              Color iconBgColor = const Color(0xFF7C3AED);

              switch (type) {
                case 'welcome':
                  title = 'Welcome to Penguin! 🐧';
                  subtitle = 'Tap to learn how to get started';
                  icon = Icons.celebration;
                  iconBgColor = const Color(0xFFDB2777);
                  break;
                case 'friend_request':
                  title = '$fromName sent a friend request';
                  subtitle = 'Tap to accept or reject';
                  icon = Icons.person_add;
                  iconBgColor = const Color(0xFF0EA5E9);
                  break;
                case 'like':
                  title = '$fromName liked your post';
                  subtitle = 'Tap to view';
                  icon = Icons.favorite;
                  iconBgColor = const Color(0xFFEF4444);
                  break;
                case 'comment':
                  title = '$fromName commented on your post';
                  subtitle = 'Tap to view';
                  icon = Icons.comment;
                  iconBgColor = const Color(0xFF10B981);
                  break;
                case 'message':
                  title = 'New message from $fromName';
                  subtitle = 'Tap to open chat';
                  icon = Icons.message;
                  iconBgColor = const Color(0xFF7C3AED);
                  break;
              }

              return Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isRead
                      ? Colors.transparent
                      : const Color(0xFF7C3AED).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor:
                        isRead ? Colors.grey[800] : iconBgColor,
                    radius: 24,
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              color:
                                  isRead ? Colors.white38 : Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (timeAgo.isNotEmpty)
                          Text(
                            timeAgo,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  trailing: isRead
                      ? null
                      : Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                  onTap: () => _onNotificationTap(
                      notifId, type, isRead, notificationData, fromName),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      for (final n in _currentNotifications) {
        final id = n['id'] as String?;
        if (id != null && !_parseIsRead(n['is_read'])) {
          _locallyMarkedRead.add(id);
        }
      }
    });
    try {
      await _notificationService.markAllAsRead();
    } catch (_) {
      if (mounted) setState(() => _locallyMarkedRead.clear());
    }
  }

  List<Map<String, dynamic>> _currentNotifications = [];

  Future<void> _onNotificationTap(String notifId, String type, bool isRead,
      Map<String, dynamic> notificationData, String fromName) async {
    if (!isRead) {
      await _markRead(notifId);
    }

    if (type == 'welcome') {
      // Navigate to the beautiful animated welcome screen
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    } else if (type == 'friend_request') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1B2E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Friend Request',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '$fromName wants to be your friend',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final fromUid =
                    (notificationData['from_uid'] as String?) ?? '';
                if (fromUid.isNotEmpty) {
                  await _friendService.removeFriendOrRequest(fromUid);
                }
              },
              child:
                  const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final fromUid =
                    (notificationData['from_uid'] as String?) ?? '';
                if (fromUid.isNotEmpty) {
                  await _friendService.acceptFriendRequest(fromUid);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('You are now friends with $fromName!')),
                    );
                  }
                }
              },
              child: const Text(
                'Accept',
                style: TextStyle(color: Color(0xFF7C3AED)),
              ),
            ),
          ],
        ),
      );
    } else if (type == 'like' || type == 'comment') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This post is no longer available.')),
        );
      }
    } else if (type == 'message') {
      final chatId = notificationData['chatId'] as String?;
      if (chatId != null) {
        _supabase
            .from('chats')
            .select('type')
            .eq('id', chatId)
            .maybeSingle()
            .then((chat) {
          if (chat != null && mounted) {
            if (chat['type'] == 'anonymous') {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => AnonymousChatScreen(chatId: chatId)));
            } else {
              final fromUid =
                  (notificationData['fromUid'] as String?) ?? '';
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => FriendsChatScreen(
                      chatId: chatId,
                      otherUserId: fromUid,
                      otherUserName: fromName)));
            }
          }
        });
      }
    }
  }
}
