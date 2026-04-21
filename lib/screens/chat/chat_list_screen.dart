import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../config/supabase_config.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chat_tile.dart';
import 'chat_room_screen.dart';

enum ChatFilter { all, selling, buying, unread }

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  ChatFilter _filter = ChatFilter.all;

  @override
  Widget build(BuildContext context) {
    final chatRoomsAsync = ref.watch(chatRoomsProvider);
    final userId = supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: HumphTheme.background,
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ChatFilter.values.map((filter) {
                final isSelected = _filter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? HumphTheme.onBackground
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? HumphTheme.onBackground
                              : HumphTheme.divider,
                        ),
                      ),
                      child: Text(
                        filter.label,
                        style: TextStyle(
                          color: isSelected
                              ? HumphTheme.background
                              : HumphTheme.onSurface,
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          // Chat list
          Expanded(
            child: chatRoomsAsync.when(
              data: (rooms) {
                final filtered = _filterRooms(rooms, userId);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: HumphTheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        const Text(
                          'No chats yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: HumphTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Start a conversation from a listing!',
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
                  onRefresh: () => ref.read(chatRoomsProvider.notifier).refresh(),
                  color: HumphTheme.primary,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final room = filtered[index];
                      return ChatTile(
                        chatRoom: room,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatRoomScreen(
                                chatRoomId: room.id,
                                otherUserName:
                                    room.otherUser?.username ?? 'Unknown',
                              ),
                            ),
                          ).then((_) {
                            ref.read(chatRoomsProvider.notifier).refresh();
                          });
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
                    const Text('Failed to load chats'),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(chatRoomsProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _filterRooms(List<dynamic> rooms, String? userId) {
    switch (_filter) {
      case ChatFilter.all:
        return rooms;
      case ChatFilter.selling:
        return rooms.where((r) => r.sellerId == userId).toList();
      case ChatFilter.buying:
        return rooms.where((r) => r.buyerId == userId).toList();
      case ChatFilter.unread:
        return rooms.where((r) => r.unreadCount > 0).toList();
    }
  }
}

extension on ChatFilter {
  String get label {
    switch (this) {
      case ChatFilter.all:
        return 'All';
      case ChatFilter.selling:
        return 'Selling';
      case ChatFilter.buying:
        return 'Buying';
      case ChatFilter.unread:
        return 'Unread';
    }
  }
}
