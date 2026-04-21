import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../config/theme.dart';
import '../models/post.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;

  const PostCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: HumphTheme.divider, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 110,
                height: 110,
                child: post.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: post.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(
                          color: HumphTheme.surfaceVariant,
                          child: const Icon(Icons.image, color: HumphTheme.onSurfaceVariant),
                        ),
                        errorWidget: (_, _, _) => Container(
                          color: HumphTheme.surfaceVariant,
                          child: const Icon(Icons.broken_image, color: HumphTheme.onSurfaceVariant),
                        ),
                      )
                    : Container(
                        color: HumphTheme.surfaceVariant,
                        child: const Icon(Icons.image, color: HumphTheme.onSurfaceVariant, size: 40),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: SizedBox(
                height: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        color: HumphTheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${post.location} · ${timeago.format(post.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: HumphTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (post.status == 'reserved')
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Reserved',
                              style: TextStyle(fontSize: 11, color: Colors.green),
                            ),
                          ),
                        if (post.status == 'sold')
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Sold',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        Text(
                          post.displayPrice,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: HumphTheme.onBackground,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (post.viewCount > 0) ...[
                          Icon(Icons.visibility_outlined,
                              size: 14, color: HumphTheme.onSurfaceVariant),
                          const SizedBox(width: 2),
                          Text(
                            '${post.viewCount}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: HumphTheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (post.likeCount > 0) ...[
                          Icon(Icons.favorite_border,
                              size: 14, color: HumphTheme.onSurfaceVariant),
                          const SizedBox(width: 2),
                          Text(
                            '${post.likeCount}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: HumphTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
