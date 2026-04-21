import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../config/supabase_config.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/manner_temp_badge.dart';
import '../../widgets/post_card.dart';
import '../home/post_detail_screen.dart';

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: HumphTheme.background,
      appBar: AppBar(
        title: const Text('My Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettings(context, ref),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Please sign in'));
          }

          return ListView(
            children: [
              // Profile card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HumphTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: HumphTheme.surfaceVariant,
                      backgroundImage: profile.avatarUrl != null
                          ? CachedNetworkImageProvider(profile.avatarUrl!)
                          : null,
                      child: profile.avatarUrl == null
                          ? const Icon(Icons.person,
                              size: 32, color: HumphTheme.onSurfaceVariant)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.username,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: HumphTheme.onBackground,
                            ),
                          ),
                          const SizedBox(height: 6),
                          MannerTempBadge(temperature: profile.mannerTemp),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: HumphTheme.onSurfaceVariant),
                  ],
                ),
              ),

              // My Transactions section
              _buildSectionHeader('My Transactions'),
              _buildMenuItem(
                icon: Icons.receipt_long_outlined,
                title: 'Sale History',
                onTap: () => _showUserPosts(context, ref),
              ),
              _buildMenuItem(
                icon: Icons.shopping_bag_outlined,
                title: 'Purchase History',
                onTap: () {},
              ),

              const SizedBox(height: 8),

              // My Interests section
              _buildSectionHeader('My Interests'),
              _buildMenuItem(
                icon: Icons.favorite_border,
                title: 'Liked Items',
                onTap: () => _showLikedPosts(context, ref),
              ),
              _buildMenuItem(
                icon: Icons.notifications_outlined,
                title: 'Keyword Alerts',
                onTap: () {},
              ),

              const SizedBox(height: 8),

              // My Activity section
              _buildSectionHeader('My Activity'),
              _buildMenuItem(
                icon: Icons.star_border,
                title: 'Reviews',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.info_outline,
                title: 'About Humph',
                onTap: () => _showAbout(context),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: HumphTheme.primary),
        ),
        error: (_, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load profile'),
              ElevatedButton(
                onPressed: () => ref.invalidate(currentProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: HumphTheme.onBackground,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: HumphTheme.onSurface, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: HumphTheme.onSurface,
                ),
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_right,
                    color: HumphTheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: HumphTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: HumphTheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit, color: HumphTheme.onBackground),
              title: const Text('Edit Profile',
                  style: TextStyle(color: HumphTheme.onBackground)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                ref.read(authNotifierProvider.notifier).signOut();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showUserPosts(BuildContext context, WidgetRef ref) {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PostListPage(
          title: 'Sale History',
          postsProvider: userPostsProvider(userId),
        ),
      ),
    );
  }

  void _showLikedPosts(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PostListPage(
          title: 'Liked Items',
          postsProvider: likedPostsProvider,
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Humph',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Camp Humphreys Marketplace\nBuilt for the Humphreys community.',
    );
  }
}

class _PostListPage<T> extends ConsumerWidget {
  final String title;
  final ProviderBase<AsyncValue<List<Post>>> postsProvider;

  const _PostListPage({
    required this.title,
    required this.postsProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);

    return Scaffold(
      backgroundColor: HumphTheme.background,
      appBar: AppBar(title: Text(title)),
      body: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 64, color: HumphTheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No items yet',
                    style: const TextStyle(color: HumphTheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return PostCard(
                post: posts[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PostDetailScreen(postId: posts[index].id),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: HumphTheme.primary),
        ),
        error: (_, _) => const Center(child: Text('Failed to load')),
      ),
    );
  }
}
