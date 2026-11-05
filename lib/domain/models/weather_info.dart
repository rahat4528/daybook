import '../../core/enums/core_enums.dart';

class WeatherInfo {
  final double temperature;
  final int wmoCode;
  final String cityName;
  final bool isDay;
  final DateTime cachedAt;

  const WeatherInfo({
    required this.temperature,
    required this.wmoCode,
    this.cityName = 'Dhaka',
    this.isDay = true,
    required this.cachedAt,
  });

  /// Maps WMO code to WeatherType enum
  WeatherType get weatherType {
    if (wmoCode == 0) return WeatherType.clear;
    if (wmoCode >= 1 && wmoCode <= 3) return WeatherType.partlyCloudy;
    if (wmoCode == 45 || wmoCode == 48) return WeatherType.foggy;
    if (wmoCode >= 51 && wmoCode <= 57) return WeatherType.rain; // drizzle
    if (wmoCode >= 61 && wmoCode <= 67) return WeatherType.rain;
    if (wmoCode >= 80 && wmoCode <= 82) return WeatherType.rain; // showers
    if (wmoCode >= 95 && wmoCode <= 99) return WeatherType.thunderstorm;
    return WeatherType.clear;
  }

  /// Compact unicode glyph for timeline and book shelf
  String get skyGlyph {
    if (weatherType == WeatherType.thunderstorm) return '⚡';
    if (weatherType == WeatherType.rain) return '🌧';
    if (weatherType == WeatherType.foggy) return '🌫';
    if (weatherType == WeatherType.partlyCloudy) return '⛅';
    return isDay ? '☀️' : '🌙';
  }

  /// Standardized code string for entries table
  String get skyCode {
    final cond = weatherType.name;
    final timeStr = isDay ? 'day' : 'night';
    return '${cond}_$timeStr';
  }

  String get conditionBangla {
    switch (weatherType) {
      case WeatherType.clear:
        return isDay ? 'পরিষ্কার রোদ ঝলমলে আকাশ' : 'পরিষ্কার তারাময় রাত';
      case WeatherType.partlyCloudy:
        return 'আংশিক মেঘলা আকাশ';
      case WeatherType.overcast:
        return 'ঘন মেঘাচ্ছন্ন আকাশ';
      case WeatherType.rain:
        return 'বৃষ্টি ও ঝিরিঝিরি বৃষ্টিপাত';
      case WeatherType.thunderstorm:
        return 'বজ্রঝড় ও দমকা হাওয়া';
      case WeatherType.foggy:
        return 'কুয়াশাচ্ছন্ন পরিবেশ';
    }
  }

  String get conditionEnglish {
    switch (weatherType) {
      case WeatherType.clear:
        return isDay ? 'Clear & Sunny' : 'Clear Starlit Night';
      case WeatherType.partlyCloudy:
        return 'Partly Cloudy';
      case WeatherType.overcast:
        return 'Overcast';
      case WeatherType.rain:
        return 'Rain & Showers';
      case WeatherType.thunderstorm:
        return 'Thunderstorms';
      case WeatherType.foggy:
        return 'Misty & Foggy';
    }
  }

  Map<String, dynamic> toJson() => {
        'temperature': temperature,
        'wmoCode': wmoCode,
        'cityName': cityName,
        'isDay': isDay,
        'cachedAt': cachedAt.toIso8601String(),
      };

  factory WeatherInfo.fromJson(Map<String, dynamic> json) => WeatherInfo(
        temperature: (json['temperature'] as num).toDouble(),
        wmoCode: json['wmoCode'] as int,
        cityName: json['cityName'] as String? ?? 'Dhaka',
        isDay: json['isDay'] as bool? ?? true,
        cachedAt: DateTime.parse(json['cachedAt'] as String),
      );

  static WeatherInfo defaultDhaka([DateTime? now]) {
    final t = now ?? DateTime.now();
    final hour = t.hour;
    final isDay = hour >= 6 && hour < 18;
    return WeatherInfo(
      temperature: 28.5,
      wmoCode: 0,
      cityName: 'Dhaka',
      isDay: isDay,
      cachedAt: t,
    );
  }
}
