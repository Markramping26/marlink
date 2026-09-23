import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/haversine_calculator.dart';
import '../data/location_repository.dart';

class LocationService {
  final LocationRepository _repository;
  final Battery _battery = Battery();

  StreamSubscription<Position>? _positionSubscription;
  Position? _lastBroadcastPosition;
  DateTime? _lastBroadcastTime;

  bool isBroadcastingEnabled = true;

  LocationService({LocationRepository? repository})
      : _repository = repository ?? LocationRepository();

  /// Check and request location permission.
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Ensures GPS location service and permissions are active.
  /// If phone location service is disabled, opens phone location settings directly.
  Future<bool> ensureLocationServiceAndPermission({bool openSettingsIfDisabled = true}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (openSettingsIfDisabled) {
        await Geolocator.openLocationSettings();
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (openSettingsIfDisabled) {
        await Geolocator.openAppSettings();
      }
      return false;
    }

    return true;
  }

  /// Get current immediate position.
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  /// Start continuous high-frequency real-time navigation location & speed stream.
  void startTracking({
    required Function(Position position, int batteryLevel) onLocationCaptured,
  }) async {
    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) return;

    stopTracking();

    // Use AndroidSettings for high-frequency navigation-grade real-time updates (500ms, distanceFilter: 0)
    final LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0, // 0 threshold ensures every speed change is captured immediately
        forceLocationManager: false,
        intervalDuration: const Duration(milliseconds: 500),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );
    }

    _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) async {
        int batteryLevel = 100;
        try {
          batteryLevel = await _battery.batteryLevel;
        } catch (_) {}

        // ALWAYS deliver immediately to local UI for real-time smooth speedometer & compass
        onLocationCaptured(position, batteryLevel);

        // Throttle backend server API broadcasting to preserve battery and bandwidth
        if (isBroadcastingEnabled && _shouldDispatchServerUpdate(position)) {
          _lastBroadcastPosition = position;
          _lastBroadcastTime = DateTime.now();

          try {
            final speedKmh = position.speed >= 0 ? position.speed * 3.6 : null; // m/s to km/h
            await _repository.sendLocationUpdate(
              latitude: position.latitude,
              longitude: position.longitude,
              accuracy: position.accuracy,
              altitude: position.altitude,
              speed: speedKmh,
              heading: position.heading >= 0 ? position.heading : null,
              batteryPct: batteryLevel,
              isMoving: (speedKmh != null && speedKmh > 2.0),
            );
          } catch (_) {}
        }
      },
      onError: (_) {},
    );
  }

  /// Throttling filter for server broadcast (preserves HTTP bandwidth and battery)
  bool _shouldDispatchServerUpdate(Position newPos) {
    if (_lastBroadcastPosition == null || _lastBroadcastTime == null) {
      return true;
    }

    final elapsed = DateTime.now().difference(_lastBroadcastTime!);
    if (elapsed.inSeconds < 3) {
      return false; // Minimum 3s interval between server HTTP POSTs
    }

    final distance = HaversineCalculator.distanceBetweenMeters(
      _lastBroadcastPosition!.latitude,
      _lastBroadcastPosition!.longitude,
      newPos.latitude,
      newPos.longitude,
    );

    if (distance >= 5.0) {
      return true;
    }

    // Significant heading change check while moving
    final headingDelta = (newPos.heading - _lastBroadcastPosition!.heading).abs();
    if (headingDelta >= 15.0 && newPos.speed > 1.0) {
      return true;
    }

    // Periodic 10s heartbeat
    if (elapsed.inSeconds >= 10) {
      return true;
    }

    return false;
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
