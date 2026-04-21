import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/chat_room.dart';
import '../models/message.dart';

class ChatService {
  Future<List<ChatRoom>> getChatRooms(String userId) async {
    final data = await supabase
        .from('chat_rooms')
        .select('''
          *,
          buyer:profiles!chat_rooms_buyer_id_fkey(*),
          seller:profiles!chat_rooms_seller_id_fkey(*),
          posts(*, post_images(*))
        ''')
        .or('buyer_id.eq.$userId,seller_id.eq.$userId')
        .order('last_message_at', ascending: false);

    return data.map((json) => ChatRoom.fromJson(json, userId)).toList();
  }

  Future<ChatRoom> getOrCreateChatRoom({
    required String postId,
    required String buyerId,
    required String sellerId,
  }) async {
    // Check if chat room already exists
    final existing = await supabase
        .from('chat_rooms')
        .select('''
          *,
          buyer:profiles!chat_rooms_buyer_id_fkey(*),
          seller:profiles!chat_rooms_seller_id_fkey(*)
        ''')
        .eq('post_id', postId)
        .eq('buyer_id', buyerId)
        .eq('seller_id', sellerId);

    if (existing.isNotEmpty) {
      return ChatRoom.fromJson(existing.first, buyerId);
    }

    final data = await supabase
        .from('chat_rooms')
        .insert({
          'post_id': postId,
          'buyer_id': buyerId,
          'seller_id': sellerId,
        })
        .select('''
          *,
          buyer:profiles!chat_rooms_buyer_id_fkey(*),
          seller:profiles!chat_rooms_seller_id_fkey(*)
        ''')
        .single();

    return ChatRoom.fromJson(data, buyerId);
  }

  Future<List<Message>> getMessages(String chatRoomId) async {
    final data = await supabase
        .from('messages')
        .select()
        .eq('chat_room_id', chatRoomId)
        .order('created_at', ascending: true);

    return data.map((json) => Message.fromJson(json)).toList();
  }

  Future<Message> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String content,
  }) async {
    final data = await supabase
        .from('messages')
        .insert({
          'chat_room_id': chatRoomId,
          'sender_id': senderId,
          'content': content,
        })
        .select()
        .single();

    return Message.fromJson(data);
  }

  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    await supabase
        .from('messages')
        .update({'is_read': true})
        .eq('chat_room_id', chatRoomId)
        .neq('sender_id', userId)
        .eq('is_read', false);
  }

  Future<int> getUnreadCount(String chatRoomId, String userId) async {
    final data = await supabase
        .from('messages')
        .select()
        .eq('chat_room_id', chatRoomId)
        .neq('sender_id', userId)
        .eq('is_read', false);
    return data.length;
  }

  RealtimeChannel subscribeToMessages(
    String chatRoomId,
    void Function(Message) onNewMessage,
  ) {
    return supabase
        .channel('messages:$chatRoomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_room_id',
            value: chatRoomId,
          ),
          callback: (payload) {
            onNewMessage(Message.fromJson(payload.newRecord));
          },
        )
        .subscribe();
  }

  RealtimeChannel subscribeToChatRooms(
    String userId,
    void Function() onUpdate,
  ) {
    return supabase
        .channel('chat_rooms:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chat_rooms',
          callback: (_) => onUpdate(),
        )
        .subscribe();
  }
}
