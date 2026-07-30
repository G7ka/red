import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

import 'fcm_service.dart';

class PostService {
  PostService._();
  static final PostService instance = PostService._();

  final _supabase = Supabase.instance.client;

  // Create a post with video
  Future<String> createPost({
    required String text,
    required File videoFile,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${user.id}.mp4';
    final storagePath = 'posts/$fileName';

    await _supabase.storage.from('posts').upload(storagePath, videoFile);
    final videoUrl =
        _supabase.storage.from('posts').getPublicUrl(storagePath);

    final res = await _supabase
        .from('posts')
        .insert({
          'owner_uid': user.id,
          'text': text,
          'video_url': videoUrl,
          'image_url': null,
          'media_type': 'video',
          'likes_count': 0,
          'comments_count': 0,
        })
        .select()
        .single();

    return res['id'] as String;
  }

  // Create a post with image
  Future<String> createImagePost({
    required String text,
    required File imageFile,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${user.id}.jpg';
    final storagePath = 'posts/$fileName';

    await _supabase.storage.from('posts').upload(storagePath, imageFile);
    final imageUrl =
        _supabase.storage.from('posts').getPublicUrl(storagePath);

    final res = await _supabase
        .from('posts')
        .insert({
          'owner_uid': user.id,
          'text': text,
          'video_url': null,
          'image_url': imageUrl,
          'media_type': 'image',
          'likes_count': 0,
          'comments_count': 0,
        })
        .select()
        .single();

    return res['id'] as String;
  }

  // Like / Unlike a post
  Future<void> likePost(String postId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Check if already liked
    final existing = await _supabase
        .from('likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      // Unlike
      await _supabase.from('likes').delete().eq('id', existing['id']);
      await _supabase.rpc('decrement_likes', params: {'p_post_id': postId});
    } else {
      // Like
      await _supabase.from('likes').insert({
        'post_id': postId,
        'user_id': user.id,
      });
      await _supabase.rpc('increment_likes', params: {'p_post_id': postId});

      // Notify post owner
      final post = await _supabase
          .from('posts')
          .select('owner_uid')
          .eq('id', postId)
          .maybeSingle();
      final ownerUid = post?['owner_uid'] as String?;
      if (ownerUid != null && ownerUid != user.id) {
        final fromUser = await _supabase
            .from('users')
            .select('display_name')
            .eq('id', user.id)
            .maybeSingle();
        final userName = fromUser?['display_name'] as String? ?? 'Someone';

        await FCMService.instance.sendPushNotification(
          toUid: ownerUid,
          title: 'New Like',
          body: '$userName liked your post',
          data: {'type': 'like', 'postId': postId, 'fromUid': user.id},
        );
      }
    }
  }

  // Check if user liked a post
  Future<bool> hasUserLiked(String postId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final existing = await _supabase
        .from('likes')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', user.id)
        .maybeSingle();

    return existing != null;
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    await _supabase.from('posts').delete().eq('id', postId);
  }

  // Get posts from friends
  Stream<List<Map<String, dynamic>>> getFriendsPostsStream(
      List<String> friendIds) {
    if (friendIds.isEmpty) return Stream.value([]);

    return _supabase
        .from('posts')
        .stream(primaryKey: ['id']).map((posts) {
      return posts
          .where((p) => friendIds.contains(p['owner_uid']))
          .toList()
        ..sort((a, b) {
          final aTime = DateTime.tryParse(a['created_at'] ?? '');
          final bTime = DateTime.tryParse(b['created_at'] ?? '');
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });
    });
  }

  // Get posts by a specific user
  Stream<List<Map<String, dynamic>>> getUserPostsStream(String userId) {
    return _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('owner_uid', userId)
        .order('created_at', ascending: false);
  }
}
