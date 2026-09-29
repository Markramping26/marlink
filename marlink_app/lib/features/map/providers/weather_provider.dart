import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/haversine_calculator.dart';
import '../data/services/weather_service.dart';
import '../domain/models/weather_model.dart';

class WeatherState {
  final WeatherModel? userWeather;
  final bool isRadarOverlayActive;
  final String? radarTileUrlTemplate;
  final Map<int, WeatherModel> memberWeatherMap;
  final bool isLoading;

  const WeatherState({
    this.userWeather,
    this.isRadarOverlayActive = false,
    this.radarTileUrlTemplate,
    this.memberWeatherMap = const {},
    this.isLoading = false,
  });

  WeatherState copyWith({
    WeatherModel? userWeather,
    bool? isRadarOverlayActive,
    String? radarTileUrlTemplate,
    Map<int, WeatherModel>? memberWeatherMap,
    bool? isLoading,
  }) {
    return WeatherState(
      userWeather: userWeather ?? this.userWeather,
      isRadarOverlayActive: isRadarOverlayActive ?? this.isRadarOverlayActive,
      radarTileUrlTemplate: radarTileUrlTemplate ?? this.radarTileUrlTemplate,
      memberWeatherMap: memberWeatherMap ?? this.memberWeatherMap,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WeatherNotifier extends StateNotifier<WeatherState> {
  WeatherNotifier() : super(const WeatherState());

  final WeatherService _service = WeatherService.instance;
  DateTime? _lastUserFetch;
  double? _lastLat;
  double? _lastLng;

  Future<void> fetchUserWeather(
    double lat,
    double lng, {
    String locationName = 'My Location',
    bool force = false,
  }) async {
    final now = DateTime.now();

    // Check if user has physically relocated > 500 meters
    bool locationShifted = false;
    if (_lastLat != null && _lastLng != null) {
      final movedMeters = HaversineCalculator.distanceBetweenMeters(_lastLat!, _lastLng!, lat, lng);
      if (movedMeters > 500) {
        locationShifted = true;
      }
    } else {
      locationShifted = true;
    }

    // Only skip if within 2 minutes AND location hasn't shifted AND not forced
    if (!force &&
        !locationShifted &&
        _lastUserFetch != null &&
        now.difference(_lastUserFetch!).inMinutes < 2 &&
        state.userWeather != null) {
      return;
    }

    state = state.copyWith(isLoading: true);
    final weather = await _service.fetchWeather(lat: lat, lng: lng, locationName: locationName);
    if (weather != null) {
      _lastUserFetch = now;
      _lastLat = lat;
      _lastLng = lng;
      state = state.copyWith(userWeather: weather, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchMemberWeather(int userId, double lat, double lng, {String locationName = 'Member Location'}) async {
    if (state.memberWeatherMap.containsKey(userId)) {
      final existing = state.memberWeatherMap[userId]!;
      if (DateTime.now().difference(existing.timestamp).inMinutes < 5) {
        return; // Use cached weather
      }
    }

    final weather = await _service.fetchWeather(lat: lat, lng: lng, locationName: locationName);
    if (weather != null) {
      final updated = Map<int, WeatherModel>.from(state.memberWeatherMap);
      updated[userId] = weather;
      state = state.copyWith(memberWeatherMap: updated);
    }
  }

  Future<void> toggleRadarOverlay() async {
    final next = !state.isRadarOverlayActive;
    if (next && state.radarTileUrlTemplate == null) {
      state = state.copyWith(isRadarOverlayActive: true, isLoading: true);
      final tileUrl = await _service.fetchRainViewerRadarTileUrl();
      state = state.copyWith(
        isRadarOverlayActive: true,
        radarTileUrlTemplate: tileUrl,
        isLoading: false,
      );
    } else {
      state = state.copyWith(isRadarOverlayActive: next);
    }
  }

  Future<void> loadRadarTilesIfNeeded() async {
    if (state.radarTileUrlTemplate == null) {
      final tileUrl = await _service.fetchRainViewerRadarTileUrl();
      if (tileUrl != null) {
        state = state.copyWith(radarTileUrlTemplate: tileUrl);
      }
    }
  }
}

final weatherNotifierProvider = StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  return WeatherNotifier();
});
