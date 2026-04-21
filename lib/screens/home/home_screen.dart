import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/post_provider.dart';
import '../../widgets/post_card.dart';
import '../../widgets/category_chip.dart';
import '../post/create_post_screen.dart';
import 'post_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final postsAsync = ref.watch(postsProvider);

    return Scaffold(
      backgroundColor: HumphTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.location_on, color: HumphTheme.onBackground, size: 20),
            const SizedBox(width: 4),
            const Text('Camp Humphreys'),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down,
                color: HumphTheme.onSurfaceVariant, size: 20),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: AppConstants.categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = AppConstants.categories[index];
                return Center(
                  child: CategoryChip(
                    label: category,
                    isSelected: selectedCategory == category,
                    onTap: () {
                      ref.read(selectedCategoryProvider.notifier).state = category;
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Posts list
          Expanded(
            child: postsAsync.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 64, color: HumphTheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        const Text(
                          'No posts yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: HumphTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Be the first to post something!',
                          style: TextStyle(
                            fontSize: 14,
                            color: HumphTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(postsProvider.notifier).refresh(),
                  color: HumphTheme.primary,
                  child: ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      return PostCard(
                        post: posts[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(postId: posts[index].id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: HumphTheme.primary),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load posts',
                      style: TextStyle(color: Colors.red[400]),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.read(postsProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Post'),
        backgroundColor: HumphTheme.primary,
      ),
    );
  }
}
