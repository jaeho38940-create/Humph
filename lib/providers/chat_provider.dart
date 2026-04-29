import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

final chatServiceProvider = Provider((ref) => ChatService());

/// Streams the total unread message count for the current user.
/// Updates in real time whenever a message is inserted or marked as read.
final unreadCountProvider = StateNotifierProvider<UnreadCountNotifier, int>((ref) {
  return UnreadCountNotifier(ref.read(chatServiceProvider));
});

class UnreadCountNotifier extends StateNotifier<int> {
  final ChatService _chatService;
  RealtimeChannel? _subscription;

  UnreadCountNotifier(this._chatService) : super(0) {
    _init();
  }

  Future<void> _init() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final count = await _chatService.getTotalUnreadCount(userId);
    if (mounted) state = count;

    _subscription = _chatService.subscribeToUnreadCount(userId, (count) {
      if (mounted) state = count;
    });
  }

  void refresh() => _init();

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}

final chatRoomsProvider = StateNotifierProvider<ChatRoomsNotifier, AsyncValue<List<ChatRoom>>>((ref) {
  final chatService = ref.read(chatServiceProvider);
  return ChatRoomsNotifier(chatService);
});

class ChatRoomsNotifier extends StateNotifier<AsyncValue<List<ChatRoom>>> {
  final ChatService _chatService;
  RealtimeChannel? _subscription;

  ChatRoomsNotifier(this._chatService) : super(const AsyncValue.loading()) {
    loadChatRooms();
  }

  Future<void> loadChatRooms() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final rooms = await _chatService.getChatRooms(userId);
      if (mounted) state = AsyncValue.data(rooms);
      _subscribeToChatRooms(userId);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  void _subscribeToChatRooms(String userId) {
    _subscription?.unsubscribe();
    _subscription = _chatService.subscribeToChatRooms(userId, () {
      loadChatRooms();
    });
  }

  Future<void> refresh() async {
    await loadChatRooms();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}

final chatMessagesProvider =
    StateNotifierProvider.family<ChatMessagesNotifier, AsyncValue<List<Message>>, String>(
  (ref, chatRoomId) {
    final chatService = ref.read(chatServiceProvider);
    return ChatMessagesNotifier(chatService, chatRoomId);
  },
);

class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  final ChatService _chatService;
  final String _chatRoomId;
  RealtimeChannel? _subscription;

  ChatMessagesNotifier(this._chatService, this._chatRoomId)
      : super(const AsyncValue.loading()) {
    _loadMessages();
    _subscribeToMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _chatService.getMessages(_chatRoomId);
      if (mounted) state = AsyncValue.data(messages);

      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await _chatService.markMessagesAsRead(_chatRoomId, userId);
      }
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  void _subscribeToMessages() {
    _subscription = _chatService.subscribeToMessages(_chatRoomId, (message) {
      final currentMessages = state.valueOrNull ?? [];
      if (!currentMessages.any((m) => m.id == message.id)) {
        state = AsyncValue.data([...currentMessages, message]);

        final userId = supabase.auth.currentUser?.id;
        if (userId != null && message.senderId != userId) {
          _chatService.markMessagesAsRead(_chatRoomId, userId);
        }
      }
    });
  }

  Future<void> sendMessage(String content) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _chatService.sendMessage(
      chatRoomId: _chatRoomId,
      senderId: userId,
      content: content,
    );
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}
