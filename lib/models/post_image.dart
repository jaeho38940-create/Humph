class PostImage {
  final String id;
  final String postId;
  final String imageUrl;
  final int displayOrder;

  PostImage({
    required this.id,
    required this.postId,
    required this.imageUrl,
    this.displayOrder = 0,
  });

  factory PostImage.fromJson(Map<String, dynamic> json) {
    return PostImage(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      imageUrl: json['image_url'] as String,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'image_url': imageUrl,
      'display_order': displayOrder,
    };
  }
}
