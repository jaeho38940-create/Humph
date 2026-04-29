import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/post.dart';

class PostService {
  static const _selectQuery = '''
    *, 
    post_images(*), 
    profiles(*)
  ''';

  Future<List<Post>> getPosts({
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = supabase.from('posts').select(_selectQuery);

    if (category != null && category != 'All') {
      query = query.eq('category', category);
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return data.map((json) => Post.fromJson(json)).toList();
  }

  Future<Post> getPost(String postId) async {
    final data = await supabase
        .from('posts')
        .select(_selectQuery)
        .eq('id', postId)
        .single();

    await supabase
        .from('posts')
        .update({'view_count': data['view_count'] + 1})
        .eq('id', postId);

    return Post.fromJson(data);
  }

  Future<Post> createPost({
    required String title,
    required String description,
    required int price,
    required bool isFree,
    required String category,
    required String userId,
    String currency = 'USD',
    String location = 'Camp Humphreys',
  }) async {
    final data = await supabase
        .from('posts')
        .insert({
          'user_id': userId,
          'title': title,
          'description': description,
          'price': price,
          'currency': currency,
          'is_free': isFree,
          'category': category,
          'location': location,
        })
        .select(_selectQuery)
        .single();

    return Post.fromJson(data);
  }

  Future<void> updatePostStatus(String postId, String status) async {
    await supabase
        .from('posts')
        .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', postId);
  }

  Future<void> deletePost(String postId) async {
    await supabase.from('posts').delete().eq('id', postId);
  }

  Future<List<Post>> getUserPosts(String userId) async {
    final data = await supabase
        .from('posts')
        .select(_selectQuery)
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return data.map((json) => Post.fromJson(json)).toList();
  }

  Future<bool> toggleLike(String postId, String userId) async {
    final existing = await supabase
        .from('likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', userId);

    if (existing.isNotEmpty) {
      await supabase
          .from('likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
      return false;
    } else {
      await supabase.from('likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
      return true;
    }
  }

  Future<List<Post>> getLikedPosts(String userId) async {
    final likeData = await supabase
        .from('likes')
        .select('post_id')
        .eq('user_id', userId);

    if (likeData.isEmpty) return [];

    final postIds = likeData.map((e) => e['post_id'] as String).toList();

    final data = await supabase
        .from('posts')
        .select(_selectQuery)
        .inFilter('id', postIds)
        .order('created_at', ascending: false);

    return data.map((json) => Post.fromJson(json)).toList();
  }

  Future<bool> isLiked(String postId, String userId) async {
    final data = await supabase
        .from('likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', userId);
    return data.isNotEmpty;
  }

  RealtimeChannel subscribeToNewPosts(void Function(Post) onNewPost) {
    return supabase
        .channel('public:posts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'posts',
          callback: (payload) async {
            final data = await supabase
                .from('posts')
                .select(_selectQuery)
                .eq('id', payload.newRecord['id'])
                .single();
            onNewPost(Post.fromJson(data));
          },
        )
        .subscribe();
  }
}
