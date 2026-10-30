import 'package:domain/post.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

String postCategoryLabel(String category) => switch (category) {
  PostCategories.policy => 'Quy định',
  PostCategories.activity => 'Tin hoạt động',
  _ => 'Thông báo',
};

IconData postCategoryIcon(String category) => switch (category) {
  PostCategories.policy => Icons.policy_outlined,
  PostCategories.activity => Icons.celebration_outlined,
  _ => Icons.campaign_outlined,
};

class PostBadges extends StatelessWidget {
  const PostBadges({super.key, required this.post});
  final PostDisplay post;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      _Badge(
        label: postCategoryLabel(post.category),
        icon: postCategoryIcon(post.category),
      ),
      if (post.isPinned)
        const _Badge(
          label: 'Đã ghim',
          icon: Icons.push_pin_rounded,
          color: Color(0xFF835500),
          background: Color(0xFFFFF3DA),
        ),
      if (post.requiresAcknowledgement)
        _Badge(
          label: post.currentUserAcknowledged ? 'Đã xác nhận' : 'Cần xác nhận',
          icon: post.currentUserAcknowledged
              ? Icons.task_alt
              : Icons.fact_check_outlined,
          color: post.currentUserAcknowledged
              ? AppColors.primary
              : const Color(0xFF835500),
          background: post.currentUserAcknowledged
              ? AppColors.primarySoft
              : const Color(0xFFFFF3DA),
        ),
    ],
  );
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.icon,
    this.color = AppColors.primary,
    this.background = AppColors.primarySoft,
  });
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}
