import 'package:core/constants.dart';
import 'package:domain/auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/user_avatar.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.profile});
  final UserEntity profile;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 24),
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [AppColors.primaryDark, AppColors.primary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Column(
      children: [
        UserAvatar(
          name: profile.username,
          imageUrl: profile.avatarUrl,
          radius: 44,
        ),
        const SizedBox(height: 16),
        Text(
          profile.username,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Chip(
          avatar: Icon(
            profile.role == Roles.admin
                ? Icons.verified_user_outlined
                : Icons.badge_outlined,
            size: 18,
          ),
          label: Text(
            profile.role == Roles.admin ? 'Quản trị viên' : 'Thành viên',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Kết nối cùng đồng nghiệp',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    ),
  );
}
