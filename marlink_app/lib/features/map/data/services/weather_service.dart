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

  /// Fast reverse geocode to resolve city/locality name for live GPS coordinates
  Future<String?> reverseGeocodeLocality(double lat, double lng) async {
    try {
      final res = await _dio.get(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=en',
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        final locality = data['locality'] as String? ?? '';
        final city = data['city'] as String? ?? '';
        final subdivision = data['principalSubdivision'] as String? ?? '';
        if (locality.isNotEmpty && city.isNotEmpty && locality != city) {
          return '$locality, $city';
        } else if (locality.isNotEmpty) {
          return locality;
        } else if (city.isNotEmpty) {
          return subdivision.isNotEmpty ? '$city, $subdivision' : city;
        }
      }
    } catch (_) {}
    return null;
  }

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
          '&hourly=temperature_2m,precipitation_probability,weather_code,is_day'
          '&forecast_days=2&timezone=auto';

      String resolvedLocationName = locationName;
      if (locationName == 'Current Location' ||
          locationName == 'My Location' ||
          locationName == 'Local Weather') {
        final geo = await reverseGeocodeLocality(lat, lng);
        if (geo != null && geo.isNotEmpty) {
          resolvedLocationName = geo;
        }
      }

      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return WeatherModel.fromOpenMeteoJson(
          response.data as Map<String, dynamic>,
          locationName: resolvedLocationName,
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
