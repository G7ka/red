import 'package:supabase_flutter/supabase_flutter.dart';
import 'fcm_service.dart';

class CallService {
  CallService._();
  static final CallService instance = CallService._();

  final _supabase = Supabase.instance.client;

  // Daily limit in seconds (15 minutes)
  static const int dailyLimitSeconds = 15 * 60;

  /// Gets usage info for the current user.
  /// Returns a map with 'usedSeconds' and 'remainingSeconds'.
  Future<Map<String, int>> getUsageInfo() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return {
        'usedSeconds': 0,
        'remainingSeconds': dailyLimitSeconds,
      };
    }

    try {
      final data = await _supabase
          .from('profiles')
          .select('call_seconds_used, last_call_date')
          .eq('id', user.id)
          .single();

      int used = (data['call_seconds_used'] as num?)?.toInt() ?? 0;
      final lastDateStr = data['last_call_date'] as String?;
      
      // Reset if different day (naive check)
      if (lastDateStr != null) {
        final lastDate = DateTime.parse(lastDateStr);
        final now = DateTime.now();
        if (lastDate.day != now.day || lastDate.month != now.month || lastDate.year != now.year) {
          used = 0;
          // Optionally update DB to reset used seconds lazily here or do it in addUsage
        }
      }

      int remaining = dailyLimitSeconds - used;
      if (remaining < 0) remaining = 0;

      return {
        'usedSeconds': used,
        'remainingSeconds': remaining,
      };
    } catch (e) {
      print('Error getting usage info: $e');
      return {
        'usedSeconds': 0,
        'remainingSeconds': dailyLimitSeconds,
      };
    }
  }

  /// Adds [seconds] to the user's daily usage.
  Future<void> addUsageSeconds(int seconds) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Use RPC for atomic increment if available, or just update
      // For simplicity in this plan, we will just update.
      // Ideally, create an RPC: increment_call_usage(seconds)
      
      final info = await getUsageInfo();
      final currentUsed = info['usedSeconds'] ?? 0;
      final newUsed = currentUsed + seconds;
      
      await _supabase.from('profiles').update({
        'call_seconds_used': newUsed,
        'last_call_date': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      
    } catch (e) {
      print('Error adding usage seconds: $e');
    }
  }

  /// Records the final duration of a specific call log.
  /// This is for the 'messages' table log, not user quota.
  Future<void> recordCallDuration(String callMessageId, int seconds) async {
    try {
      await _supabase.from('messages').update({
        'call_duration_seconds': seconds
      }).eq('id', callMessageId);
    } catch (e) {
       print('Error recording call duration: $e');
    }
  }
  // ================= CALL SIGNALING =================

  /// Start a call. Returns callRoomId if successful/ringing, null if failed/offline.
  Future<String?> startCall(String receiverId, String callerName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    // 1. Check if user is online
    try {
      final userRes = await _supabase.from('users').select('is_online').eq('id', receiverId).single();
      final isOnline = userRes['is_online'] as bool? ?? false;

      if (!isOnline) {
        // Send Missed Call Notification
        await FCMService.instance.sendPushNotification(
          toUid: receiverId,
          title: 'Missed Call',
          body: '$callerName tried to call you.',
          data: {'type': 'missed_call', 'fromUid': user.id, 'fromName': callerName},
        );
        return null;
      }

      // 2. Create Call Room
      final res = await _supabase.from('call_rooms').insert({
        'caller_id': user.id,
        'receiver_id': receiverId,
        'status': 'offering',
        'caller_name': callerName,
      }).select().single();

      return res['id'] as String;

    } catch (e) {
      print('Error starting call: $e');
      return null;
    }
  }

  /// Listen for incoming calls
  Stream<Map<String, dynamic>> listenForIncomingCalls() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();

    return _supabase
        .from('call_rooms')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', user.id)
        .order('created_at', ascending: false)
        .map((events) {
          // Find first offering
          final offers = events.where((e) => e['status'] == 'offering');
          if (offers.isNotEmpty) {
            return offers.first;
          }
          return {};
        });
  }

  Future<void> acceptCall(String roomId) async {
    await _supabase.from('call_rooms').update({'status': 'accepted'}).eq('id', roomId);
  }

  Future<void> rejectCall(String roomId) async {
    await _supabase.from('call_rooms').update({'status': 'rejected'}).eq('id', roomId);
  }

  Future<void> endCall(String roomId) async {
    await _supabase.from('call_rooms').update({'status': 'ended'}).eq('id', roomId);
  }
}
