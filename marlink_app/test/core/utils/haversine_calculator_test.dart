import 'package:flutter_test/flutter_test.dart';
import 'package:marlink_app/core/utils/haversine_calculator.dart';

void main() {
  group('HaversineCalculator Tests', () {
    test('Calculates distance between known coordinates accurately', () {
      // Makati (14.5547, 121.0244) to BGC (14.5505, 121.0500) ~ 2.8 km
      final distance = HaversineCalculator.distanceBetweenMeters(
        14.5547,
        121.0244,
        14.5505,
        121.0500,
      );

      expect(distance, greaterThan(2500));
      expect(distance, lessThan(3200));
    });

    test('Formats distance in meters under 1000m and km for greater', () {
      expect(HaversineCalculator.formatDistance(350), '350 m away');
      expect(HaversineCalculator.formatDistance(2400), '2.4 km away');
    });

    test('Converts compass heading degrees to cardinal direction', () {
      expect(HaversineCalculator.headingToCardinal(0), 'North');
      expect(HaversineCalculator.headingToCardinal(45), 'North-East');
      expect(HaversineCalculator.headingToCardinal(90), 'East');
      expect(HaversineCalculator.headingToCardinal(180), 'South');
      expect(HaversineCalculator.headingToCardinal(270), 'West');
    });

    test('Formats speed or gracefully returns unavailable', () {
      expect(HaversineCalculator.formatSpeed(47.2), '47 km/h');
      expect(HaversineCalculator.formatSpeed(null), 'Speed unavailable');
      expect(HaversineCalculator.formatSpeed(-1), 'Speed unavailable');
    });
  });
}
