import 'package:supabase_flutter/supabase_flutter.dart';

// TEMPORARY STUB - Needs full Supabase migration
class ReportService {
  ReportService._();
  static final ReportService instance = ReportService._();

  final _supabase = Supabase.instance.client;

  Future<void> reportUser({
    required String reportedUserId,
    required String reason,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('reports').insert({
      'reporter_id': user.id,
      'reported_user_id': reportedUserId,
      'reason': reason,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> reportPost({
    required String postId,
    required String reason,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('reports').insert({
      'reporter_id': user.id,
      'reported_post_id': postId,
      'reason': reason,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
