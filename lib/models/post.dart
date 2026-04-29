import 'package:intl/intl.dart';
import 'post_image.dart';
import 'profile.dart';

class Post {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final int price;
  final String currency;
  final bool isFree;
  final String category;
  final String status;
  final String location;
  final int viewCount;
  final int likeCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PostImage> images;
  final Profile? seller;
  final bool? isLiked;

  Post({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.price = 0,
    this.currency = 'USD',
    this.isFree = false,
    this.category = 'Other',
    this.status = 'selling',
    this.location = 'Camp Humphreys',
    this.viewCount = 0,
    this.likeCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.images = const [],
    this.seller,
    this.isLiked,
  });

  String get displayPrice {
    if (isFree) return 'Free';
    if (price == 0) return 'Price negotiable';

    if (currency == 'KRW') {
      return '₩${NumberFormat('#,###').format(price)}';
    }

    final dollars = price / 100;
    final hasCents = price % 100 != 0;
    return NumberFormat.currency(
      symbol: '\$',
      decimalDigits: hasCents ? 2 : 0,
    ).format(dollars);
  }

  String? get thumbnailUrl => images.isNotEmpty ? images.first.imageUrl : null;

  factory Post.fromJson(Map<String, dynamic> json) {
    List<PostImage> images = [];
    if (json['post_images'] != null) {
      images = (json['post_images'] as List)
          .map((e) => PostImage.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    }

    Profile? seller;
    if (json['profiles'] != null) {
      seller = Profile.fromJson(json['profiles'] as Map<String, dynamic>);
    }

    return Post(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      price: json['price'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      isFree: json['is_free'] as bool? ?? false,
      category: json['category'] as String? ?? 'Other',
      status: json['status'] as String? ?? 'selling',
      location: json['location'] as String? ?? 'Camp Humphreys',
      viewCount: json['view_count'] as int? ?? 0,
      likeCount: json['like_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      images: images,
      seller: seller,
      isLiked: json['is_liked'] as bool?,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'is_free': isFree,
      'category': category,
      'status': status,
      'location': location,
    };
  }
}
