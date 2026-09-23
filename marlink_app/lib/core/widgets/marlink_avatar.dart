import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MarLinkAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final bool showOnlineIndicator;
  final bool isOnline;
  final VoidCallback? onTap;

  const MarLinkAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 22,
    this.showOnlineIndicator = false,
    this.isOnline = false,
    this.onTap,
  });

  String get _initials {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.trim().substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget avatarContent;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatarContent = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
          child: Center(
            child: Text(
              _initials,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.8,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildInitials(isDark),
      );
    } else {
      avatarContent = _buildInitials(isDark);
    }

    final avatar = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: avatarContent,
    );

    if (!showOnlineIndicator) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.55,
              height: radius * 0.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? AppColors.statusOnline : AppColors.statusOffline,
                border: Border.all(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitials(bool isDark) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: radius * 0.8,
            color: isDark ? AppColors.brandSky : AppColors.brandBlue,
          ),
        ),
      ),
    );
  }
}
