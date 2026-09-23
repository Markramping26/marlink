import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/utils/haversine_calculator.dart';
import '../../rooms/providers/room_provider.dart';
import '../data/location_repository.dart';
import '../domain/models/member_location_model.dart';
import '../services/location_service.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  final repo = ref.watch(locationRepositoryProvider);
  return LocationService(repository: repo);
});

class MapState {
  final Position? myPosition;
  final int myBattery;
  final List<MemberLocationModel> memberLocations;
  final MemberLocationModel? selectedMember;
  final bool isLoading;
  final String? errorMessage;
  final double currentSpeedKmh;
  final double topSpeedKmh;
  final double averageSpeedKmh;
  final double totalDistanceMeters;
  final int movingSeconds;

  const MapState({
    this.myPosition,
    this.myBattery = 100,
    this.memberLocations = const [],
    this.selectedMember,
    this.isLoading = false,
    this.errorMessage,
    this.currentSpeedKmh = 0.0,
    this.topSpeedKmh = 0.0,
    this.averageSpeedKmh = 0.0,
    this.totalDistanceMeters = 0.0,
    this.movingSeconds = 0,
  });

  LatLng? get myLatLng =>
      myPosition != null ? LatLng(myPosition!.latitude, myPosition!.longitude) : null;

  MapState copyWith({
    Position? myPosition,
    int? myBattery,
    List<MemberLocationModel>? memberLocations,
    MemberLocationModel? selectedMember,
    bool? isLoading,
    String? errorMessage,
    double? currentSpeedKmh,
    double? topSpeedKmh,
    double? averageSpeedKmh,
    double? totalDistanceMeters,
    int? movingSeconds,
  }) {
    return MapState(
      myPosition: myPosition ?? this.myPosition,
      myBattery: myBattery ?? this.myBattery,
      memberLocations: memberLocations ?? this.memberLocations,
      selectedMember: selectedMember,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      topSpeedKmh: topSpeedKmh ?? this.topSpeedKmh,
      averageSpeedKmh: averageSpeedKmh ?? this.averageSpeedKmh,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      movingSeconds: movingSeconds ?? this.movingSeconds,
    );
  }
}

final mapNotifierProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  final service = ref.watch(locationServiceProvider);
  final repo = ref.watch(locationRepositoryProvider);
  return MapNotifier(service, repo, ref);
});

class MapNotifier extends StateNotifier<MapState> {
  final LocationService _locationService;
  final LocationRepository _repository;
  final Ref _ref;
  Timer? _refreshTimer;
  Position? _previousPosition;
  DateTime? _previousPositionTime;

  MapNotifier(this._locationService, this._repository, this._ref)
      : super(const MapState()) {
    _initLiveTracking();
  }

  void _initLiveTracking() async {
    final pos = await _locationService.getCurrentPosition();
    if (pos != null) {
      double initialSpeed = 0.0;
      if (pos.speed > 0) {
        initialSpeed = pos.speed * 3.6;
        if (initialSpeed < 1.0) initialSpeed = 0.0;
      }
      state = state.copyWith(myPosition: pos, currentSpeedKmh: initialSpeed);
      _previousPosition = pos;
      _previousPositionTime = DateTime.now();
    }

    _locationService.startTracking(
      onLocationCaptured: _handleLocationCaptured,
    );

    // Refresh member locations every 4 seconds while circle is active
    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      fetchRoomLocations();
    });

    fetchRoomLocations();
  }

  void _handleLocationCaptured(Position position, int battery) {
    // 1. Instantaneous speed in km/h
    double speedKmh = 0.0;
    if (position.speed > 0) {
      speedKmh = position.speed * 3.6;
    }
    // Filter GPS stationary jitter (e.g. 0.3 - 0.8 km/h drift when stopped)
    if (speedKmh < 1.0) {
      speedKmh = 0.0;
    }

    // 2. Track Top Speed
    double newTopSpeed = state.topSpeedKmh;
    if (speedKmh > newTopSpeed) {
      newTopSpeed = speedKmh;
    }

    // 3. Track Distance, Moving Time, and Average Speed
    double newTotalDistance = state.totalDistanceMeters;
    int newMovingSeconds = state.movingSeconds;
    final now = DateTime.now();

    if (_previousPosition != null && _previousPositionTime != null) {
      final elapsedSec = now.difference(_previousPositionTime!).inSeconds;
      // Accumulate stats only if moving (>= 2.0 km/h) and realistic interval (< 15 seconds)
      if (speedKmh >= 2.0 && elapsedSec > 0 && elapsedSec < 15) {
        final dMeters = HaversineCalculator.distanceBetweenMeters(
          _previousPosition!.latitude,
          _previousPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        // Sanity check: max 120 m/s (~430 km/h) to filter GPS jump anomalies
        if (dMeters < 120.0 * elapsedSec) {
          newTotalDistance += dMeters;
          newMovingSeconds += elapsedSec;
        }
      }
    }

    double newAverageSpeed = state.averageSpeedKmh;
    if (newMovingSeconds > 2 && newTotalDistance > 5) {
      newAverageSpeed = (newTotalDistance / 1000.0) / (newMovingSeconds / 3600.0);
    }

    _previousPosition = position;
    _previousPositionTime = now;

    state = state.copyWith(
      myPosition: position,
      myBattery: battery,
      currentSpeedKmh: speedKmh,
      topSpeedKmh: newTopSpeed,
      averageSpeedKmh: newAverageSpeed,
      totalDistanceMeters: newTotalDistance,
      movingSeconds: newMovingSeconds,
    );
  }

  void resetSpeedStats() {
    state = state.copyWith(
      topSpeedKmh: 0.0,
      averageSpeedKmh: 0.0,
      totalDistanceMeters: 0.0,
      movingSeconds: 0,
    );
    _previousPosition = null;
    _previousPositionTime = null;
  }

  Future<void> fetchRoomLocations() async {
    final currentRoom = _ref.read(roomsNotifierProvider).currentRoom;
    if (currentRoom == null) return;

    try {
      final locations = await _repository.getRoomLocations(currentRoom.id);
      state = state.copyWith(memberLocations: locations);
    } catch (_) {}
  }

  void selectMember(MemberLocationModel? member) {
    state = state.copyWith(selectedMember: member);
  }

  void clearRoomLocations() {
    state = state.copyWith(memberLocations: []);
  }

  void setBroadcasting(bool enabled) {
    _locationService.isBroadcastingEnabled = enabled;
  }

  Future<Position?> captureCurrentPosition({bool openSettingsIfDisabled = true}) async {
    final ok = await _locationService.ensureLocationServiceAndPermission(
      openSettingsIfDisabled: openSettingsIfDisabled,
    );
    if (!ok) return null;

    final pos = await _locationService.getCurrentPosition();
    if (pos != null) {
      state = state.copyWith(myPosition: pos);
    }
    return pos;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _locationService.stopTracking();
    super.dispose();
  }
}
