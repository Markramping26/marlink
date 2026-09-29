import 'package:dio/dio.dart';
import '../../domain/models/weather_model.dart';

class WeatherService {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  /// Fetch real-time weather from Open-Meteo (100% Free, No API Key needed)
  Future<WeatherModel?> fetchWeather({
    required double lat,
    required double lng,
    String locationName = 'Current Location',
  }) async {
    try {
      final url = 'https://api.open-meteo.com/v1/forecast?'
          'latitude=$lat&longitude=$lng'
          '&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m'
          '&forecast_days=1&timezone=auto';

      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return WeatherModel.fromOpenMeteoJson(
          response.data as Map<String, dynamic>,
          locationName: locationName,
        );
      }
    } catch (_) {
      // Gracefully handle network failures
    }
    return null;
  }

  /// Fetch live Zoom Earth-style radar tile URL from RainViewer (100% Free, No API Key needed)
  Future<String?> fetchRainViewerRadarTileUrl() async {
    try {
      final response = await _dio.get('https://api.rainviewer.com/public/weather-maps.json');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final host = data['host'] as String? ?? 'https://tilecache.rainviewer.com';
        final radar = data['radar'] as Map<String, dynamic>?;
        final past = radar?['past'] as List<dynamic>?;
        if (past != null && past.isNotEmpty) {
          final latest = past.last as Map<String, dynamic>;
          final path = latest['path'] as String?;
          if (path != null && path.isNotEmpty) {
            // RainViewer tile format: {host}{path}/256/{z}/{x}/{y}/2/1_1.png
            return '$host$path/256/{z}/{x}/{y}/2/1_1.png';
          }
        }
      }
    } catch (_) {
      // Gracefully handle network failures
    }
    return null;
  }
}
