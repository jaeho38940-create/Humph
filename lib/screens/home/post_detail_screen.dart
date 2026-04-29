import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/theme.dart';
import '../../config/supabase_config.dart';
import '../../models/post.dart';
import '../../providers/post_provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/image_carousel.dart';
import '../../widgets/manner_temp_badge.dart';
import '../chat/chat_room_screen.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  bool _isLiked = false;
  int _localLikeCount = 0;

  @override
  void initState() {
    super.initState();
    _checkLikeStatus();
  }

  Future<void> _checkLikeStatus() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    final liked = await ref.read(postServiceProvider).isLiked(widget.postId, userId);
    if (mounted) setState(() => _isLiked = liked);
  }

  Future<void> _toggleLike(Post post) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final result = await ref.read(postServiceProvider).toggleLike(widget.postId, userId);
    setState(() {
      _isLiked = result;
      _localLikeCount = post.likeCount + (result ? 1 : -1);
    });
  }

  Future<void> _startChat(Post post) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null || userId == post.userId) return;

    final chatService = ChatService();
    final chatRoom = await chatService.getOrCreateChatRoom(
      postId: post.id,
      buyerId: userId,
      sellerId: post.userId,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            chatRoomId: chatRoom.id,
            otherUserName: post.seller?.username ?? 'Seller',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));

    return postAsync.when(
      data: (post) {
        _localLikeCount = _localLikeCount == 0 ? post.likeCount : _localLikeCount;
        return Scaffold(
          backgroundColor: HumphTheme.background,
          body: _buildContent(post),
          bottomNavigationBar: _BottomBar(
            post: post,
            isLiked: _isLiked,
            onLike: () => _toggleLike(post),
            onChat: () => _startChat(post),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: HumphTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: HumphTheme.primary),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: HumphTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load post'),
              ElevatedButton(
                onPressed: () => ref.invalidate(postDetailProvider(widget.postId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Post post) {
    final isOwner = supabase.auth.currentUser?.id == post.userId;

    return CustomScrollView(
      slivers: [
        // App bar with back button
        SliverAppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          pinned: false,
          expandedHeight: 0,
          leading: IconButton(
            icon: const CircleAvatar(
              backgroundColor: Colors.black45,
              child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black45,
                child: Icon(Icons.share, color: Colors.white, size: 18),
              ),
              onPressed: () {},
            ),
            if (isOwner)
              PopupMenuButton<String>(
                icon: const CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: Icon(Icons.more_vert, color: Colors.white, size: 18),
                ),
                onSelected: (value) async {
                  if (value == 'delete') {
                    await ref.read(postServiceProvider).deletePost(post.id);
                    if (mounted) Navigator.pop(context);
                  } else if (value == 'status') {
                    _showStatusDialog(post);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'status', child: Text('Change Status')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
          ],
        ),
        // Image carousel
        SliverToBoxAdapter(
          child: ImageCarousel(
            imageUrls: post.images.map((e) => e.imageUrl).toList(),
          ),
        ),
        // Seller info
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: HumphTheme.divider, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: HumphTheme.surfaceVariant,
                  backgroundImage: post.seller?.avatarUrl != null
                      ? CachedNetworkImageProvider(post.seller!.avatarUrl!)
                      : null,
                  child: post.seller?.avatarUrl == null
                      ? const Icon(Icons.person, color: HumphTheme.onSurfaceVariant)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.seller?.username ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: HumphTheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        post.location,
                        style: const TextStyle(
                          fontSize: 13,
                          color: HumphTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                MannerTempBadge(
                  temperature: post.seller?.mannerTemp ?? 36.5,
                ),
              ],
            ),
          ),
        ),
        // Post content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge
                if (post.status != 'selling')
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: DropdownButton<String>(
                      value: post.status,
                      isDense: true,
                      dropdownColor: HumphTheme.surface,
                      style: const TextStyle(color: HumphTheme.onBackground),
                      items: const [
                        DropdownMenuItem(value: 'selling', child: Text('Selling')),
                        DropdownMenuItem(value: 'reserved', child: Text('Reserved')),
                        DropdownMenuItem(value: 'sold', child: Text('Sold')),
                      ],
                      onChanged: isOwner ? (value) {
                        if (value != null) {
                          ref.read(postServiceProvider).updatePostStatus(post.id, value);
                          ref.invalidate(postDetailProvider(widget.postId));
                        }
                      } : null,
                    ),
                  ),
                // Title
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: HumphTheme.onBackground,
                  ),
                ),
                const SizedBox(height: 8),
                // Price (right under the title)
                Text(
                  post.displayPrice,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: post.isFree
                        ? HumphTheme.primary
                        : HumphTheme.onBackground,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${post.category} · ${timeago.format(post.createdAt)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: HumphTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                if (post.description != null && post.description!.isNotEmpty)
                  Text(
                    post.description!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: HumphTheme.onSurface,
                      height: 1.6,
                    ),
                  ),
                const SizedBox(height: 24),
                // Location
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HumphTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Meetup Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: HumphTheme.onBackground,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            post.location,
                            style: const TextStyle(
                              fontSize: 14,
                              color: HumphTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: HumphTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on,
                                  size: 32, color: HumphTheme.primary),
                              SizedBox(height: 8),
                              Text(
                                'Camp Humphreys Area',
                                style: TextStyle(
                                  color: HumphTheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Stats
                Text(
                  'Views ${post.viewCount} · Likes $_localLikeCount',
                  style: const TextStyle(
                    fontSize: 13,
                    color: HumphTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showStatusDialog(Post post) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Change Status'),
        children: ['selling', 'reserved', 'sold'].map((status) {
          return SimpleDialogOption(
            onPressed: () {
              ref.read(postServiceProvider).updatePostStatus(post.id, status);
              ref.invalidate(postDetailProvider(widget.postId));
              Navigator.pop(context);
            },
            child: Text(status[0].toUpperCase() + status.substring(1)),
          );
        }).toList(),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final Post post;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onChat;

  const _BottomBar({
    required this.post,
    required this.isLiked,
    required this.onLike,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = supabase.auth.currentUser?.id == post.userId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: HumphTheme.background,
        border: Border(
          top: BorderSide(color: HumphTheme.divider, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: onLike,
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : HumphTheme.onSurfaceVariant,
                size: 28,
              ),
            ),
            Container(
              width: 1,
              height: 36,
              color: HumphTheme.divider,
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.displayPrice,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: HumphTheme.onBackground,
                    ),
                  ),
                  if (!post.isFree && post.price > 0)
                    const Text(
                      'Price negotiable',
                      style: TextStyle(
                        fontSize: 12,
                        color: HumphTheme.onSurfaceVariant,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                ],
              ),
            ),
            if (!isOwner)
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: onChat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HumphTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Chat',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
