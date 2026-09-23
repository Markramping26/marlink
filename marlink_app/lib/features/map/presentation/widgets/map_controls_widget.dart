import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MapControlsWidget extends StatelessWidget {
  final VoidCallback onRecenter;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback? onPip;
  final VoidCallback? onToggleNavigationFollow;
  final bool isNavigationFollowActive;

  const MapControlsWidget({
    super.key,
    required this.onRecenter,
    required this.onZoomIn,
    required this.onZoomOut,
    this.onPip,
    this.onToggleNavigationFollow,
    this.isNavigationFollowActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : AppColors.lightSurface).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Google Maps-Style Realtime Navigation Follow Toggle
          if (onToggleNavigationFollow != null) ...[
            Container(
              decoration: isNavigationFollowActive
                  ? BoxDecoration(
                      color: AppColors.statusOnline.withValues(alpha: 0.18),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    )
                  : null,
              child: IconButton(
                icon: Icon(
                  isNavigationFollowActive ? Icons.navigation_rounded : Icons.explore_outlined,
                  color: isNavigationFollowActive
                      ? AppColors.statusOnline
                      : (isDark ? AppColors.brandSky : AppColors.brandBlue),
                ),
                tooltip: isNavigationFollowActive
                    ? 'Exit Navigation Follow (Wide)'
                    : 'Start Realtime Navigation Follow',
                onPressed: onToggleNavigationFollow,
              ),
            ),
            Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ],
          if (onPip != null) ...[
            IconButton(
              icon: const Icon(Icons.picture_in_picture_alt_rounded),
              tooltip: 'Floating Mini Map (PiP)',
              onPressed: onPip,
              color: AppColors.brandSky,
            ),
            Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ],
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'My Location',
            onPressed: onRecenter,
            color: isDark ? AppColors.brandSky : AppColors.brandBlue,
          ),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Zoom In',
            onPressed: onZoomIn,
          ),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          IconButton(
            icon: const Icon(Icons.remove_rounded),
            tooltip: 'Zoom Out',
            onPressed: onZoomOut,
          ),
        ],
      ),
    );
  }
}
