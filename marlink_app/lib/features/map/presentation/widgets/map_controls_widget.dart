import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MapControlsWidget extends StatelessWidget {
  final VoidCallback onRecenter;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback? onPip;
  final VoidCallback? onSwitchMapStyle;
  final VoidCallback? onToggleWeather;
  final bool isSatelliteActive;
  final bool isNavigationFollowActive;
  final bool isRadarActive;

  const MapControlsWidget({
    super.key,
    required this.onRecenter,
    required this.onZoomIn,
    required this.onZoomOut,
    this.onPip,
    this.onSwitchMapStyle,
    this.onToggleWeather,
    this.isSatelliteActive = false,
    this.isNavigationFollowActive = false,
    this.isRadarActive = false,
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
          if (onSwitchMapStyle != null) ...[
            IconButton(
              icon: Icon(
                isSatelliteActive ? Icons.satellite_alt_rounded : Icons.layers_rounded,
                color: isSatelliteActive ? AppColors.brandSky : (isDark ? Colors.white70 : AppColors.brandNavy),
              ),
              tooltip: 'Map Layer (Satellite / Real Houses)',
              onPressed: onSwitchMapStyle,
            ),
            Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ],
          if (onToggleWeather != null) ...[
            Container(
              decoration: isRadarActive
                  ? BoxDecoration(
                      color: AppColors.brandSky.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: IconButton(
                icon: Icon(
                  isRadarActive ? Icons.radar_rounded : Icons.cloud_outlined,
                  color: isRadarActive
                      ? AppColors.brandSky
                      : (isDark ? Colors.white70 : AppColors.brandNavy),
                ),
                tooltip: isRadarActive ? 'Live Radar ON (Tap for Forecast)' : 'Live Weather & Zoom Earth Radar',
                onPressed: onToggleWeather,
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
          // Single Unified Smart Location & Follow Navigation Button
          Container(
            decoration: isNavigationFollowActive
                ? BoxDecoration(
                    color: AppColors.statusOnline.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            child: IconButton(
              icon: Icon(
                isNavigationFollowActive ? Icons.navigation_rounded : Icons.my_location_rounded,
                color: isNavigationFollowActive
                    ? AppColors.statusOnline
                    : (isDark ? AppColors.brandSky : AppColors.brandBlue),
              ),
              tooltip: isNavigationFollowActive
                  ? 'Following (Tap to View Route Overview)'
                  : 'My Location (Tap to Center & Follow)',
              onPressed: onRecenter,
            ),
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
