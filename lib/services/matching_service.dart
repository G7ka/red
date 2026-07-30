import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'chat_service.dart';

class MatchingService {
  MatchingService._();
  static final MatchingService instance = MatchingService._();

  final _supabase = Supabase.instance.client;
  final _chatService = ChatService.instance;

  // Stream subscription for checking if we got matched while queuing
  RealtimeChannel? _queueChannel;

  /// Starts searching for an anonymous partner.
  ///
  /// Strategy:
  /// 1. Save preferences to queue entry.
  /// 2. Try to find a match from existing queue entries that fit our preferences.
  /// 3. If match found -> Create Chat -> Return Chat ID.
  /// 4. If no match -> Insert self to queue -> Listen for Chat Invite.
  Future<String?> startAnonymousSearch({
    String genderPreference = 'Everyone',
    int minAge = 18,
    int maxAge = 80,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      // Get my profile info for matching
      final myData = await _supabase
          .from('users')
          .select('gender, dob')
          .eq('id', user.id)
          .single();

      final myGender = myData['gender'] as String?;
      final myDob = myData['dob'] as String?;
      final myAge = _calculateAge(myDob);
      
      // Strict matching rule: Must have a gender to match
      if (myGender == null || myGender.isEmpty || (myGender.toLowerCase() != 'male' && myGender.toLowerCase() != 'female')) {
        print('User has no valid gender for strict matching: $myGender');
        return null; // Cannot match if gender isn\'t clearly male or female
      }

      final requiredOtherGender = myGender.toLowerCase() == 'male' ? 'Female' : 'Male';

      // 1. Try local matching from queue
      final queueEntries = await _supabase
          .from('matching_queue')
          .select('user_id, users(gender, dob, preferred_age_min, preferred_age_max)')
          .neq('user_id', user.id)
          .order('created_at', ascending: true);

      for (final entry in queueEntries) {
        final otherUserId = entry['user_id'] as String;
        final otherUserData = entry['users'] as Map<String, dynamic>?;
        if (otherUserData == null) continue;

        final otherGender = otherUserData['gender'] as String?;
        final otherDob = otherUserData['dob'] as String?;
        final otherAge = _calculateAge(otherDob);

        // Strict heterosexual match check
        if (otherGender == null || otherGender.toLowerCase() != requiredOtherGender.toLowerCase()) {
          continue; // Skip if not the opposite gender
        }

        // Other person's age preferences
        final otherPrefMinAge =
            (otherUserData['preferred_age_min'] as num?)?.toInt() ?? 18;
        final otherPrefMaxAge =
            (otherUserData['preferred_age_max'] as num?)?.toInt() ?? 80;

        // Check: do I match their age requirement?
        final iMatchThem = _isAgeMatch(otherPrefMinAge, otherPrefMaxAge, myAge);

        // Check: do they match my age requirement?
        final theyMatchMe = _isAgeMatch(minAge, maxAge, otherAge);

        if (iMatchThem && theyMatchMe) {
          // Remove them from queue
          await _supabase
              .from('matching_queue')
              .delete()
              .eq('user_id', otherUserId);

          // Create anonymous chat
          return await _chatService.createChat(
              [user.id, otherUserId], isAnonymous: true);
        }
      }

      // 3. No match found, add self to queue with preferences
      await _addToQueue(user.id, minAge, maxAge);

      // 4. Listen for match
      return await _waitForMatch(user.id);
    } catch (e) {
      print('Error in startAnonymousSearch: $e');
      return null;
    }
  }

  bool _isAgeMatch(int minAge, int maxAge, int? otherAge) {
    if (otherAge == null) return true; // Unknown age, allow
    return otherAge >= minAge && otherAge <= maxAge;
  }

  int? _calculateAge(String? dobString) {
    if (dobString == null) return null;
    final dob = DateTime.tryParse(dobString);
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _addToQueue(
      String userId, int minAge, int maxAge) async {
    await _supabase.from('matching_queue').upsert({
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Also save preferences to user profile for cross-reference
    try {
      await _supabase.from('users').update({
        'preferred_age_min': minAge,
        'preferred_age_max': maxAge,
      }).eq('id', userId);
    } catch (_) {}
  }

  Future<String?> _waitForMatch(String userId) async {
    final completer = Completer<String>();

    _queueChannel = _supabase.channel('public:chats');
    _queueChannel?.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chats',
      callback: (payload) {
        final newChat = payload.newRecord;
        final participants =
            List<String>.from(newChat['participants'] ?? []);
        if (participants.contains(userId)) {
          if (!completer.isCompleted) {
            completer.complete(newChat['id'] as String);
          }
        }
      },
    ).subscribe();

    try {
      final chatId = await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw 'Timeout',
      );
      return chatId;
    } catch (e) {
      await stopSearching();
      return null;
    } finally {
      _stopListening();
    }
  }

  Future<void> stopSearching() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _stopListening();

    try {
      await _supabase
          .from('matching_queue')
          .delete()
          .eq('user_id', user.id);
    } catch (e) {
      print('Error stopping search: $e');
    }
  }

  void _stopListening() {
    if (_queueChannel != null) {
      _supabase.removeChannel(_queueChannel!);
      _queueChannel = null;
    }
  }

  // Legacy method signature support
  Future<void> startSearching() async {
    await startAnonymousSearch();
  }
}
