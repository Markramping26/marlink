import 'package:flutter/material.dart';
import '../../../../core/services/pip_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/weather_model.dart';

class WeatherForecastDialog extends StatefulWidget {
  final WeatherModel weather;

  const WeatherForecastDialog({
    super.key,
    required this.weather,
  });

  @override
  State<WeatherForecastDialog> createState() => _WeatherForecastDialogState();
}

class _WeatherForecastDialogState extends State<WeatherForecastDialog> {
  int? _selectedHourIndex;

  @override
  Widget build(BuildContext context) {
    // If PiP mode is active, dismiss immediately to prevent layout overflow
    if (PipService.instance.isPipMode.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hourly = widget.weather.hourlyForecasts;

    // Active displayed data (current live or user-scrubbed hour)
    final isHourSelected = _selectedHourIndex != null &&
        _selectedHourIndex! >= 0 &&
        _selectedHourIndex! < hourly.length;

    final selectedItem = isHourSelected ? hourly[_selectedHourIndex!] : null;

    final displayTemp = selectedItem != null
        ? selectedItem.temperature.round()
        : widget.weather.temperature.round();

    final displayCondition = selectedItem != null
        ? selectedItem.condition
        : widget.weather.condition;

    final displayIcon = selectedItem != null
        ? selectedItem.weatherIcon
        : widget.weather.weatherIcon;

    final displayTimeLabel = selectedItem != null
        ? _formatHourLabel(selectedItem.time)
        : 'Right Now';

    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title & Location Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandSky.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(displayIcon, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.weather.locationName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$displayCondition • $displayTimeLabel',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isHourSelected
                          ? AppColors.brandSky.withValues(alpha: 0.15)
                          : AppColors.statusOnline.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isHourSelected ? 'PREVIEW' : 'LIVE',
                      style: TextStyle(
                        color: isHourSelected ? AppColors.brandSky : AppColors.statusOnline,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Temperature & Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E2D4A), const Color(0xFF131F38)]
                        : [const Color(0xFFE2E8F0), const Color(0xFFF1F5F9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$displayTemp°C',
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          isHourSelected
                              ? 'Forecast for $displayTimeLabel'
                              : 'Feels like ${widget.weather.apparentTemperature.round()}°C',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      displayIcon,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Realtime Weather Advisory (Rain, Heat, Clouds, Fair)
              _buildWeatherAdvisoryBanner(widget.weather, hourly, isDark),
              const SizedBox(height: 14),

              // Zoom Earth-style Hourly Weather Time-Scrubber
              if (hourly.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: AppColors.brandSky),
                        const SizedBox(width: 5),
                        Text(
                          '24-HOUR WEATHER TIMELINE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (isHourSelected)
                      GestureDetector(
                        onTap: () => setState(() => _selectedHourIndex = null),
                        child: const Text(
                          'Reset to Live',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandSky,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 94,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: hourly.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = hourly[index];
                      final isSelected = _selectedHourIndex == index ||
                          (_selectedHourIndex == null && index == 0);

                      final hourLabel = index == 0 ? 'Now' : _formatHourLabel(item.time);

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          setState(() {
                            _selectedHourIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 66,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.brandSky.withValues(alpha: isDark ? 0.22 : 0.15)
                                : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.brandSky
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              width: isSelected ? 1.8 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                hourLabel,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.brandSky
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                ),
                              ),
                              Text(
                                item.weatherIcon,
                                style: const TextStyle(fontSize: 18),
                              ),
                              Text(
                                '${item.temperature.round()}°',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (item.precipitationProbability > 20)
                                Text(
                                  '💧${item.precipitationProbability}%',
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.brandSky,
                                  ),
                                )
                              else
                                const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Detailed Weather Metrics
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.water_drop_outlined,
                      label: 'Humidity',
                      value: '${widget.weather.humidity}%',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.air_rounded,
                      label: 'Wind Speed',
                      value: '${widget.weather.windSpeed.toStringAsFixed(1)} km/h',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.cloud_outlined,
                      label: 'Rainfall',
                      value: selectedItem != null
                          ? '${selectedItem.precipitationProbability}% prob'
                          : '${widget.weather.precipitation.toStringAsFixed(1)} mm',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherAdvisoryBanner(
    WeatherModel weather,
    List<HourlyForecastItem> hourly,
    bool isDark,
  ) {
    // 1. Check if currently raining
    final isRaining = weather.precipitation > 0 ||
        (weather.weatherCode >= 51 && weather.weatherCode <= 67) ||
        (weather.weatherCode >= 80 && weather.weatherCode <= 99);

    // 2. Check for upcoming rain in the next 8 hours
    final nextRainHour = hourly.take(8).where((h) => h.precipitationProbability >= 40).firstOrNull;

    // 3. Check for high heat
    final isHeatWarning = weather.apparentTemperature >= 38 || weather.temperature >= 35;

    // 4. Check for cloud cover
    final isCloudy = weather.weatherCode == 2 || weather.weatherCode == 3;

    final IconData icon;
    final Color color;
    final String headline;
    final String subtitle;

    if (isRaining) {
      icon = Icons.umbrella_rounded;
      color = const Color(0xFF38BDF8); // Sky blue
      headline = 'Active Rain in Your Location';
      subtitle = weather.precipitation > 0
          ? '${weather.condition} • ${weather.precipitation.toStringAsFixed(1)} mm precipitation'
          : '${weather.condition} currently observed';
    } else if (nextRainHour != null) {
      icon = Icons.grain_rounded;
      color = const Color(0xFF60A5FA); // Blue
      headline = 'Rain Expected Around ${_formatHourLabel(nextRainHour.time)}';
      subtitle = '${nextRainHour.precipitationProbability}% precipitation probability forecasted';
    } else if (isHeatWarning) {
      icon = Icons.warning_amber_rounded;
      color = const Color(0xFFF97316); // Orange
      headline = 'High Heat Advisory';
      subtitle = 'Feels like ${weather.apparentTemperature.round()}°C • Stay hydrated';
    } else if (isCloudy) {
      icon = Icons.cloud_queue_rounded;
      color = const Color(0xFF94A3B8); // Slate
      headline = 'Overcast / Cloudy Skies';
      subtitle = '${weather.condition} • Low UV index';
    } else {
      icon = Icons.wb_sunny_rounded;
      color = const Color(0xFFFACC15); // Yellow/Gold
      headline = 'Clear & Favorable Weather';
      subtitle = 'Optimal road and outdoor visibility';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  headline,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatHourLabel(DateTime time) {
    final hour = time.hour;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12 $amPm';
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.brandSky),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
