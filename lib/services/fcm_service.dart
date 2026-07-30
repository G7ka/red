import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages here
  print('Handling background message: ${message.messageId}');
}

class FCMService {
  FCMService._();
  static final FCMService instance = FCMService._();

  final _messaging = FirebaseMessaging.instance;
  final _supabase = Supabase.instance.client;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);

    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveFCMTokenToUser(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveFCMTokenToUser);

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _initialized = true;
  }

  Future<void> _saveFCMTokenToUser(String token) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('users').update({
      'fcm_token': token,
      'fcm_token_updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);
  }

  // Show welcome notification
  // Show welcome notification
  Future<void> showWelcomeNotification({
    String title = 'Welcome to Penguin! 🐧',
    String body = 'Thanks for joining! Start exploring and making new friends.',
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'welcome_channel',
      'Welcome Notifications',
      channelDescription: 'Notifications for new users',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      0,
      title,
      body,
      details,
    );
  }

  // Send push notification to a user
  Future<void> sendPushNotification({
    required String toUid,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // We insert into 'notifications' table.
    // Database triggers or Edge Functions would handle the actual FCM sending.
    
    await _supabase.from('notifications').insert({
      'to_uid': toUid,
      'type': data?['type'] ?? 'general',
      'data': {
        'title': title,
        'body': body,
        ...?data,
      },
      'is_read': false,
    });
  }
}



