import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../services/storage_service.dart';
import '../config/supabase_config.dart';

final postServiceProvider = Provider((ref) => PostService());
final storageServiceProvider = Provider((ref) => StorageService());

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

final postsProvider = StateNotifierProvider<PostsNotifier, AsyncValue<List<Post>>>((ref) {
  final postService = ref.read(postServiceProvider);
  final category = ref.watch(selectedCategoryProvider);
  return PostsNotifier(postService, category);
});

class PostsNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  final PostService _postService;
  final String _category;
  RealtimeChannel? _subscription;

  PostsNotifier(this._postService, this._category) : super(const AsyncValue.loading()) {
    loadPosts();
    _subscribeToNewPosts();
  }

  Future<void> loadPosts() async {
    try {
      state = const AsyncValue.loading();
      final posts = await _postService.getPosts(
        category: _category == 'All' ? null : _category,
      );
      if (mounted) state = AsyncValue.data(posts);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  void _subscribeToNewPosts() {
    _subscription = _postService.subscribeToNewPosts((newPost) {
      final currentPosts = state.valueOrNull ?? [];
      if (_category == 'All' || newPost.category == _category) {
        state = AsyncValue.data([newPost, ...currentPosts]);
      }
    });
  }

  Future<void> refresh() async {
    await loadPosts();
  }

  void addPost(Post post) {
    final currentPosts = state.valueOrNull ?? [];
    state = AsyncValue.data([post, ...currentPosts]);
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}

final postDetailProvider = FutureProvider.family<Post, String>((ref, postId) async {
  final postService = ref.read(postServiceProvider);
  return postService.getPost(postId);
});

final userPostsProvider = FutureProvider.family<List<Post>, String>((ref, userId) async {
  final postService = ref.read(postServiceProvider);
  return postService.getUserPosts(userId);
});

final likedPostsProvider = FutureProvider<List<Post>>((ref) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];
  final postService = ref.read(postServiceProvider);
  return postService.getLikedPosts(userId);
});

final isLikedProvider = FutureProvider.family<bool, String>((ref, postId) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return false;
  final postService = ref.read(postServiceProvider);
  return postService.isLiked(postId, userId);
});

class CreatePostNotifier extends StateNotifier<AsyncValue<void>> {
  final PostService _postService;
  final StorageService _storageService;

  CreatePostNotifier(this._postService, this._storageService)
      : super(const AsyncValue.data(null));

  Future<Post?> createPost({
    required String title,
    required String description,
    required int price,
    required bool isFree,
    required String category,
    required String userId,
    required List<XFile> images,
    String currency = 'USD',
    String location = 'Camp Humphreys',
  }) async {
    state = const AsyncValue.loading();
    try {
      final post = await _postService.createPost(
        title: title,
        description: description,
        price: price,
        isFree: isFree,
        category: category,
        userId: userId,
        currency: currency,
        location: location,
      );

      if (images.isNotEmpty) {
        final urls = await _storageService.uploadImages(images, userId);
        for (int i = 0; i < urls.length; i++) {
          await supabase.from('post_images').insert({
            'post_id': post.id,
            'image_url': urls[i],
            'display_order': i,
          });
        }
      }

      state = const AsyncValue.data(null);
      return post;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final createPostProvider = StateNotifierProvider<CreatePostNotifier, AsyncValue<void>>((ref) {
  return CreatePostNotifier(
    ref.read(postServiceProvider),
    ref.read(storageServiceProvider),
  );
});
