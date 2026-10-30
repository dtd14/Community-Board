import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 22,
  });
  final String name;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final fallback = Text(
      name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase(),
      style: TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
        fontSize: radius * .8,
      ),
    );
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primarySoft,
      child: imageUrl == null || imageUrl!.isEmpty
          ? fallback
          : ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                placeholder: (_, _) => fallback,
                errorWidget: (_, _, _) => fallback,
              ),
            ),
    );
  }
}
