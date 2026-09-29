class WeatherModel {
  final double temperature;
  final double apparentTemperature;
  final int humidity;
  final double windSpeed;
  final double precipitation;
  final int weatherCode;
  final bool isDay;
  final String locationName;
  final DateTime timestamp;

  const WeatherModel({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.windSpeed,
    required this.precipitation,
    required this.weatherCode,
    required this.isDay,
    required this.locationName,
    required this.timestamp,
  });

  factory WeatherModel.fromOpenMeteoJson(Map<String, dynamic> json, {String locationName = 'Current Location'}) {
    final current = json['current'] as Map<String, dynamic>? ?? {};
    return WeatherModel(
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 25.0,
      apparentTemperature: (current['apparent_temperature'] as num?)?.toDouble() ?? 26.0,
      humidity: (current['relative_humidity_2m'] as num?)?.toInt() ?? 65,
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 5.0,
      precipitation: (current['precipitation'] as num?)?.toDouble() ?? 0.0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      isDay: ((current['is_day'] as num?)?.toInt() ?? 1) == 1,
      locationName: locationName,
      timestamp: DateTime.now(),
    );
  }

  /// WMO Weather Interpretation Code to Emoji Icon
  String get weatherIcon {
    switch (weatherCode) {
      case 0:
        return isDay ? '☀️' : '🌙';
      case 1:
      case 2:
        return isDay ? '⛅' : '☁️';
      case 3:
        return '☁️';
      case 45:
      case 48:
        return '🌫️';
      case 51:
      case 53:
      case 55:
        return '🌦️';
      case 61:
      case 63:
      case 65:
        return '🌧️';
      case 71:
      case 73:
      case 75:
        return '❄️';
      case 80:
      case 81:
      case 82:
        return '🌧️';
      case 95:
      case 96:
      case 99:
        return '⛈️';
      default:
        return '⛅';
    }
  }

  /// Human-friendly condition description
  String get condition {
    switch (weatherCode) {
      case 0:
        return 'Clear Sky';
      case 1:
        return 'Mainly Clear';
      case 2:
        return 'Partly Cloudy';
      case 3:
        return 'Overcast';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Light Drizzle';
      case 61:
        return 'Slight Rain';
      case 63:
        return 'Moderate Rain';
      case 65:
        return 'Heavy Rain';
      case 71:
      case 73:
      case 75:
        return 'Snow Flurries';
      case 80:
      case 81:
      case 82:
        return 'Passing Showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Severe Thunderstorm';
      default:
        return 'Fair Weather';
    }
  }
}
