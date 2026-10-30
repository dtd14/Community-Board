import 'package:cached_network_image/cached_network_image.dart';
import 'package:domain/post.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/user_avatar.dart';
import 'post_badges.dart';
import 'post_people_sheet.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, this.onToggleLike});
  final PostDisplay post;
  final VoidCallback? onToggleLike;

  @override
  Widget build(BuildContext context) {
    void openPost() => context.pushNamed(
      RouteNames.postDetail,
      pathParameters: {'postId': post.postId},
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: openPost,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PostBadges(post: post),
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.pushNamed(
                  RouteNames.userDetail,
                  pathParameters: {'userId': post.authorId},
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      name: post.authorUsername,
                      imageUrl: post.authorAvatarUrl,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorUsername,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            DateFormat(
                              'yyyy-MM-dd HH:mm',
                            ).format(post.postCreatedAt.toLocal()),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.mutedText),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_outward_rounded,
                      size: 18,
                      color: AppColors.mutedText,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                post.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                post.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(height: 1.6, color: AppColors.mutedText),
              ),
              if (post.imageUrl?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl!,
                    width: double.infinity,
                    height: 210,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(height: 210, color: AppColors.fieldBg),
                    errorWidget: (_, _, _) => const SizedBox(
                      height: 100,
                      child: Center(child: Icon(Icons.broken_image_outlined)),
                    ),
                  ),
                ),
              ],
              const Divider(height: 28),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton(
                    tooltip: post.currentUserLiked
                        ? 'Bỏ thích'
                        : 'Thích bài viết',
                    onPressed: onToggleLike,
                    icon: Icon(
                      post.currentUserLiked
                          ? Icons.thumb_up_rounded
                          : Icons.thumb_up_outlined,
                      size: 20,
                    ),
                    color: post.currentUserLiked
                        ? AppColors.primary
                        : AppColors.mutedText,
                  ),
                  TextButton(
                    onPressed: () =>
                        showPostPeopleSheet(context, postId: post.postId),
                    child: Text('${post.likesCount} lượt thích'),
                  ),
                  TextButton.icon(
                    onPressed: openPost,
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text('${post.commentsCount} bình luận'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
