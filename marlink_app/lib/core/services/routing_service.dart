import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../utils/haversine_calculator.dart';

class NavigationStep {
  final String instruction;
  final String type;
  final String modifier;
  final double distanceMeters;
  final double durationSeconds;
  final String roadName;

  const NavigationStep({
    required this.instruction,
    required this.type,
    required this.modifier,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.roadName,
  });

  IconData get maneuverIcon {
    final mod = modifier.toLowerCase();
    final t = type.toLowerCase();

    if (t == 'arrive') return Icons.location_on;
    if (mod.contains('slight left')) return Icons.turn_slight_left;
    if (mod.contains('slight right')) return Icons.turn_slight_right;
    if (mod.contains('left')) return Icons.turn_left;
    if (mod.contains('right')) return Icons.turn_right;
    if (mod.contains('uturn') || mod.contains('u-turn')) return Icons.u_turn_left;
    if (mod.contains('straight')) return Icons.straight;
    return Icons.navigation;
  }
}

class RoadRoute {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final List<NavigationStep> steps;

  const RoadRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.steps,
  });

  NavigationStep? get currentStep => steps.isNotEmpty ? steps.first : null;

  String get formattedDistance => HaversineCalculator.formatDistance(distanceMeters);

  String get formattedDuration {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 1) return '< 1 min';
    if (minutes < 60) return '$minutes min${minutes == 1 ? '' : 's'}';
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    return '${hours}h ${remainingMins}m';
  }
}

class RoutingService {
  RoutingService._();
  static final RoutingService instance = RoutingService._();

  static const String _osrmBaseUrl = 'https://router.project-osrm.org/route/v1/driving';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
    ),
  );

  Future<RoadRoute?> getRoadRoute({
    required LatLng from,
    required LatLng to,
  }) async {
    try {
      final url =
          '$_osrmBaseUrl/${from.longitude},${from.latitude};${to.longitude},${to.latitude}?overview=full&geometries=geojson&steps=true';

      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : (response.data is String ? jsonDecode(response.data as String) as Map<String, dynamic> : null);
        if (data != null && data['code'] == 'Ok' && data['routes'] is List && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0] as Map<String, dynamic>;
          final dist = (route['distance'] as num?)?.toDouble() ?? 0.0;
          final dur = (route['duration'] as num?)?.toDouble() ?? 0.0;

          // Parse road coordinates
          final coordsList = route['geometry']?['coordinates'] as List? ?? [];
          final roadPoints = <LatLng>[];
          for (final coord in coordsList) {
            if (coord is List && coord.length >= 2) {
              final lng = (coord[0] as num).toDouble();
              final lat = (coord[1] as num).toDouble();
              roadPoints.add(LatLng(lat, lng));
            }
          }

          // Parse steps
          final steps = <NavigationStep>[];
          final legs = route['legs'] as List? ?? [];
          if (legs.isNotEmpty) {
            final rawSteps = legs[0]['steps'] as List? ?? [];
            for (final s in rawSteps) {
              final stepMap = s as Map<String, dynamic>;
              final name = (stepMap['name'] as String?)?.trim() ?? '';
              final stepDist = (stepMap['distance'] as num?)?.toDouble() ?? 0.0;
              final stepDur = (stepMap['duration'] as num?)?.toDouble() ?? 0.0;
              final maneuver = stepMap['maneuver'] as Map<String, dynamic>? ?? {};
              final type = (maneuver['type'] as String?) ?? 'turn';
              final modifier = (maneuver['modifier'] as String?) ?? 'straight';

              String instruction;
              final distStr = HaversineCalculator.formatDistance(stepDist);

              if (type == 'arrive') {
                instruction = 'Arriving at destination';
              } else if (type == 'depart') {
                instruction = name.isNotEmpty ? 'Depart on $name' : 'Head towards destination';
              } else if (modifier.contains('left')) {
                instruction = name.isNotEmpty ? 'In $distStr, turn left onto $name' : 'In $distStr, turn left';
              } else if (modifier.contains('right')) {
                instruction = name.isNotEmpty ? 'In $distStr, turn right onto $name' : 'In $distStr, turn right';
              } else {
                instruction = name.isNotEmpty ? 'Continue straight onto $name' : 'Continue straight ($distStr)';
              }

              steps.add(NavigationStep(
                instruction: instruction,
                type: type,
                modifier: modifier,
                distanceMeters: stepDist,
                durationSeconds: stepDur,
                roadName: name,
              ));
            }
          }

          if (roadPoints.isNotEmpty) {
            return RoadRoute(
              points: roadPoints,
              distanceMeters: dist,
              durationSeconds: dur,
              steps: steps,
            );
          }
        }
      }
    } catch (_) {
      // Graceful fallback to direct line if offline or server timeout
    }

    // Direct line fallback
    final directDist = HaversineCalculator.distanceBetweenMeters(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );

    return RoadRoute(
      points: [from, to],
      distanceMeters: directDist,
      durationSeconds: (directDist / 8.33), // Approx 30 km/h driving
      steps: [
        NavigationStep(
          instruction: 'Proceed directly toward destination',
          type: 'depart',
          modifier: 'straight',
          distanceMeters: directDist,
          durationSeconds: directDist / 8.33,
          roadName: '',
        ),
      ],
    );
  }
}
