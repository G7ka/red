import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _supabase = Supabase.instance.client;
  final _countRefreshController = StreamController<int>.broadcast();

  static bool _parseIsRead(dynamic value) {
    if (value == true) return true;
    if (value == false || value == null) return false;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('to_uid', user.id)
        .order('created_at', ascending: false);
  }

  int _localUnreadOffset = 0;

  Future<int> getUnreadCount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0;

    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('to_uid', user.id)
          .eq('is_read', false);

      int actualCount = (response as List).length;
      return (actualCount + _localUnreadOffset) >= 0 ? (actualCount + _localUnreadOffset) : 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  Stream<int> getUnreadCountStream() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value(0);

    final dbStream = _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('to_uid', user.id)
        .map((events) =>
            events.where((e) => !_parseIsRead(e['is_read'])).length);

    return Stream.multi((controller) {
      late StreamSubscription<int> dbSub;
      late StreamSubscription<int> refreshSub;

      dbSub = dbStream.listen(
        controller.add,
        onError: controller.addError,
      );
      refreshSub = _countRefreshController.stream.listen(
        controller.add,
        onError: controller.addError,
      );

      controller.onCancel = () async {
        await dbSub.cancel();
        await refreshSub.cancel();
      };
    });
  }

  Future<void> _refreshUnreadCount() async {
    final count = await getUnreadCount();
    if (!_countRefreshController.isClosed) {
      _countRefreshController.add(count);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      _localUnreadOffset--;
      await _refreshUnreadCount();
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      // reset offset if we successfully wrote to DB
      _localUnreadOffset++;
      await _refreshUnreadCount();
    } catch (e) {
      _localUnreadOffset++;
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final unreadCount = await getUnreadCount();
      _localUnreadOffset -= unreadCount;
      await _refreshUnreadCount();

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('to_uid', user.id)
          .eq('is_read', false);
          
      _localUnreadOffset += unreadCount;
      await _refreshUnreadCount();
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  Future<void> markChatNotificationsAsRead(String chatId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final unread = await _supabase
          .from('notifications')
          .select('id, data')
          .eq('to_uid', user.id)
          .eq('is_read', false)
          .eq('type', 'message');

      for (final notif in unread) {
        final data = notif['data'] as Map<String, dynamic>?;
        if (data != null && data['chatId'] == chatId) {
          await markAsRead(notif['id'] as String);
        }
      }
    } catch (e) {
      print('Error marking chat notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  Future<void> deleteAllNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('to_uid', user.id);
    } catch (e) {
      print('Error deleting all notifications: $e');
      rethrow;
    }
  }
}
