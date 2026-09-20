// widgets/auth_header.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'app_logo.dart';
import 'brand_chip.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLogo(),
        const SizedBox(height: 16),
        const BrandChip(),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 35,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.mutedText, fontSize: 14),
        ),
      ],
    );
  }
}