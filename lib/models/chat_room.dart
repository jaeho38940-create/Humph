import 'profile.dart';
import 'post.dart';

class ChatRoom {
  final String id;
  final String? postId;
  final String buyerId;
  final String sellerId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final Profile? otherUser;
  final Post? post;
  final int unreadCount;

  ChatRoom({
    required this.id,
    this.postId,
    required this.buyerId,
    required this.sellerId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    this.otherUser,
    this.post,
    this.unreadCount = 0,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json, String currentUserId) {
    Profile? otherUser;
    if (json['buyer'] != null && json['seller'] != null) {
      final isBuyer = currentUserId == json['buyer_id'];
      otherUser = Profile.fromJson(
        (isBuyer ? json['seller'] : json['buyer']) as Map<String, dynamic>,
      );
    }

    Post? post;
    if (json['posts'] != null) {
      post = Post.fromJson(json['posts'] as Map<String, dynamic>);
    }

    return ChatRoom(
      id: json['id'] as String,
      postId: json['post_id'] as String?,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      otherUser: otherUser,
      post: post,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }
}
