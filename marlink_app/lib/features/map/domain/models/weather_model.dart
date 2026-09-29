class HourlyForecastItem {
  final DateTime time;
  final double temperature;
  final int weatherCode;
  final int precipitationProbability;
  final bool isDay;

  const HourlyForecastItem({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    required this.precipitationProbability,
    required this.isDay,
  });

  String get weatherIcon => WeatherModel.codeToIcon(weatherCode, isDay);
  String get condition => WeatherModel.codeToCondition(weatherCode);
}

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
  final List<HourlyForecastItem> hourlyForecasts;

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
    this.hourlyForecasts = const [],
  });

  factory WeatherModel.fromOpenMeteoJson(Map<String, dynamic> json, {String locationName = 'Current Location'}) {
    final current = json['current'] as Map<String, dynamic>? ?? {};
    final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 25.0;
    final apparent = (current['apparent_temperature'] as num?)?.toDouble() ?? 26.0;
    final hum = (current['relative_humidity_2m'] as num?)?.toInt() ?? 65;
    final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 5.0;
    final prec = (current['precipitation'] as num?)?.toDouble() ?? 0.0;
    final code = (current['weather_code'] as num?)?.toInt() ?? 0;
    final isDayBool = ((current['is_day'] as num?)?.toInt() ?? 1) == 1;

    // Parse Hourly Forecast (Next 24 hours)
    final hourly = json['hourly'] as Map<String, dynamic>?;
    final List<HourlyForecastItem> parsedHourly = [];
    if (hourly != null) {
      final times = hourly['time'] as List<dynamic>? ?? [];
      final temps = hourly['temperature_2m'] as List<dynamic>? ?? [];
      final rainProbs = hourly['precipitation_probability'] as List<dynamic>? ?? [];
      final codes = hourly['weather_code'] as List<dynamic>? ?? [];
      final days = hourly['is_day'] as List<dynamic>? ?? [];

      final now = DateTime.now();
      for (int i = 0; i < times.length && parsedHourly.length < 24; i++) {
        final parsedTime = DateTime.tryParse(times[i].toString());
        if (parsedTime != null) {
          if (parsedTime.isAfter(now.subtract(const Duration(minutes: 55)))) {
            parsedHourly.add(
              HourlyForecastItem(
                time: parsedTime,
                temperature: i < temps.length ? (temps[i] as num?)?.toDouble() ?? temp : temp,
                weatherCode: i < codes.length ? (codes[i] as num?)?.toInt() ?? code : code,
                precipitationProbability: i < rainProbs.length ? (rainProbs[i] as num?)?.toInt() ?? 0 : 0,
                isDay: i < days.length ? ((days[i] as num?)?.toInt() ?? 1) == 1 : isDayBool,
              ),
            );
          }
        }
      }
    }

    // Fallback hourly if empty
    if (parsedHourly.isEmpty) {
      final now = DateTime.now();
      for (int h = 0; h < 12; h++) {
        final hourTime = now.add(Duration(hours: h));
        final hourVal = hourTime.hour;
        parsedHourly.add(
          HourlyForecastItem(
            time: hourTime,
            temperature: temp + (h % 3 == 0 ? 1 : -1),
            weatherCode: code,
            precipitationProbability: prec > 0 ? 60 : 10,
            isDay: hourVal >= 6 && hourVal < 18,
          ),
        );
      }
    }

    return WeatherModel(
      temperature: temp,
      apparentTemperature: apparent,
      humidity: hum,
      windSpeed: wind,
      precipitation: prec,
      weatherCode: code,
      isDay: isDayBool,
      locationName: locationName,
      timestamp: DateTime.now(),
      hourlyForecasts: parsedHourly,
    );
  }

  /// WMO Weather Interpretation Code to Emoji Icon
  String get weatherIcon => codeToIcon(weatherCode, isDay);

  /// Human-friendly condition description
  String get condition => codeToCondition(weatherCode);

  static String codeToIcon(int code, bool isDay) {
    switch (code) {
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

  static String codeToCondition(int code) {
    switch (code) {
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
