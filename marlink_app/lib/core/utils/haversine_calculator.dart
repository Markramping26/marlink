import 'dart:math' as math;

class HaversineCalculator {
  HaversineCalculator._();

  static const double earthRadiusMeters = 6371000.0;

  /// Calculate geographic distance between two points in meters using Haversine formula.
  static double distanceBetweenMeters(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final dLat = _degToRad(endLat - startLat);
    final dLng = _degToRad(endLng - startLng);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(startLat)) *
            math.cos(_degToRad(endLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  /// Format distance into user-friendly representation (meters vs kilometers).
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m away';
    } else {
      final km = meters / 1000.0;
      return '${km.toStringAsFixed(1)} km away';
    }
  }

  /// Calculate bearing / compass direction in degrees (0 to 360) from start point to end point.
  static double calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final lat1 = _degToRad(startLat);
    final lat2 = _degToRad(endLat);
    final dLng = _degToRad(endLng - startLng);

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final rad = math.atan2(y, x);
    final deg = (rad * (180.0 / math.pi) + 360.0) % 360.0;
    return deg;
  }

  /// Calculate estimated driving or walking time based on distance in meters.
  static String estimateTravelTime(double meters) {
    if (meters < 1000) {
      final minutes = (meters / 83.0).ceil();
      return 'Walk: ~$minutes min${minutes > 1 ? 's' : ''}';
    } else {
      final km = meters / 1000.0;
      if (km < 30) {
        final minutes = ((km / 35.0) * 60).round();
        return 'Drive: ~$minutes mins';
      } else {
        final hours = (km / 70.0).toStringAsFixed(1);
        return 'Drive: ~$hours hrs';
      }
    }
  }

  /// Convert heading in degrees (0-360) to 8-point cardinal direction.
  static String headingToCardinal(double? degrees) {
    if (degrees == null || degrees < 0) return 'Unknown direction';
    final normalized = (degrees % 360);
    if (normalized >= 337.5 || normalized < 22.5) return 'North';
    if (normalized >= 22.5 && normalized < 67.5) return 'North-East';
    if (normalized >= 67.5 && normalized < 112.5) return 'East';
    if (normalized >= 112.5 && normalized < 157.5) return 'South-East';
    if (normalized >= 157.5 && normalized < 202.5) return 'South';
    if (normalized >= 202.5 && normalized < 247.5) return 'South-West';
    if (normalized >= 247.5 && normalized < 292.5) return 'West';
    return 'North-West';
  }

  /// Format speed into km/h or display unavailable if null.
  static String formatSpeed(double? speedKmh) {
    if (speedKmh == null || speedKmh < 0) {
      return 'Speed unavailable';
    }
    return '${speedKmh.round()} km/h';
  }

  /// Format relative timestamp.
  static String formatRelativeTime(DateTime? timestamp) {
    if (timestamp == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 5) return 'Just now';
    if (difference.inSeconds < 60) return '${difference.inSeconds} seconds ago';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  static double _degToRad(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}
