import '../../core/enums/core_enums.dart';

class WeatherState {
  final String cityName;
  final double temperatureC;
  final WeatherType condition;
  final int humidityPercent;
  final double windSpeedKmh;
  final int sunriseHour;
  final int sunriseMinute;
  final int sunsetHour;
  final int sunsetMinute;
  final DateTime lastUpdated;

  const WeatherState({
    this.cityName = 'Dhaka',
    this.temperatureC = 27.5,
    this.condition = WeatherType.clear,
    this.humidityPercent = 64,
    this.windSpeedKmh = 11.2,
    this.sunriseHour = 6,
    this.sunriseMinute = 4,
    this.sunsetHour = 17,
    this.sunsetMinute = 16,
    required this.lastUpdated,
  });

  /// Calculates real-time sky phase depending on current time relative to sunrise & sunset.
  SkyPhase getSkyPhase([DateTime? referenceTime]) {
    final now = referenceTime ?? DateTime.now();
    final currentMinuteOfDay = now.hour * 60 + now.minute;
    final sunriseMinuteOfDay = sunriseHour * 60 + sunriseMinute;
    final sunsetMinuteOfDay = sunsetHour * 60 + sunsetMinute;

    // Dawn: 45 min before sunrise until 15 min after
    if (currentMinuteOfDay >= sunriseMinuteOfDay - 45 &&
        currentMinuteOfDay < sunriseMinuteOfDay + 15) {
      return SkyPhase.dawn;
    }

    // Morning: until 12:00 PM
    if (currentMinuteOfDay >= sunriseMinuteOfDay + 15 && currentMinuteOfDay < 720) {
      return SkyPhase.morning;
    }

    // Afternoon: 12:00 PM until 60 min before sunset
    if (currentMinuteOfDay >= 720 &&
        currentMinuteOfDay < sunsetMinuteOfDay - 60) {
      return SkyPhase.afternoon;
    }

    // Golden Hour: 60 min before sunset until sunset
    if (currentMinuteOfDay >= sunsetMinuteOfDay - 60 &&
        currentMinuteOfDay < sunsetMinuteOfDay) {
      return SkyPhase.goldenHour;
    }

    // Dusk / Twilight: sunset until 45 min after sunset
    if (currentMinuteOfDay >= sunsetMinuteOfDay &&
        currentMinuteOfDay < sunsetMinuteOfDay + 45) {
      return SkyPhase.dusk;
    }

    // Night: all other hours
    return SkyPhase.night;
  }

  Map<String, dynamic> toJson() => {
        'cityName': cityName,
        'temperatureC': temperatureC,
        'condition': condition.index,
        'humidityPercent': humidityPercent,
        'windSpeedKmh': windSpeedKmh,
        'sunriseHour': sunriseHour,
        'sunriseMinute': sunriseMinute,
        'sunsetHour': sunsetHour,
        'sunsetMinute': sunsetMinute,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory WeatherState.fromJson(Map<String, dynamic> json) => WeatherState(
        cityName: json['cityName'] as String? ?? 'Dhaka',
        temperatureC: (json['temperatureC'] as num?)?.toDouble() ?? 27.5,
        condition: WeatherType.values[json['condition'] as int? ?? 0],
        humidityPercent: json['humidityPercent'] as int? ?? 64,
        windSpeedKmh: (json['windSpeedKmh'] as num?)?.toDouble() ?? 11.2,
        sunriseHour: json['sunriseHour'] as int? ?? 6,
        sunriseMinute: json['sunriseMinute'] as int? ?? 4,
        sunsetHour: json['sunsetHour'] as int? ?? 17,
        sunsetMinute: json['sunsetMinute'] as int? ?? 16,
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.parse(json['lastUpdated'] as String)
            : DateTime.now(),
      );
}

class DailyBriefing {
  final DateTime date;
  final String greeting;
  final String quote;
  final String weatherBrief;
  final List<String> topTaskTitles;
  final String? firstAlarmFormatted;
  final int totalEstimatedMinutes;

  const DailyBriefing({
    required this.date,
    required this.greeting,
    required this.quote,
    required this.weatherBrief,
    required this.topTaskTitles,
    this.firstAlarmFormatted,
    this.totalEstimatedMinutes = 0,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'greeting': greeting,
        'quote': quote,
        'weatherBrief': weatherBrief,
        'topTaskTitles': topTaskTitles,
        'firstAlarmFormatted': firstAlarmFormatted,
        'totalEstimatedMinutes': totalEstimatedMinutes,
      };

  factory DailyBriefing.fromJson(Map<String, dynamic> json) => DailyBriefing(
        date: DateTime.parse(json['date'] as String),
        greeting: json['greeting'] as String,
        quote: json['quote'] as String,
        weatherBrief: json['weatherBrief'] as String,
        topTaskTitles: (json['topTaskTitles'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        firstAlarmFormatted: json['firstAlarmFormatted'] as String?,
        totalEstimatedMinutes: json['totalEstimatedMinutes'] as int? ?? 0,
      );
}

class EveningReflection {
  final String id;
  final DateTime date;
  final int completedTasksCount;
  final int pendingTasksCount;
  final int moodScore; // 1 to 5
  final String reflectionNotes;
  final List<String> rolloverTaskIds;

  const EveningReflection({
    required this.id,
    required this.date,
    required this.completedTasksCount,
    required this.pendingTasksCount,
    this.moodScore = 4,
    this.reflectionNotes = '',
    this.rolloverTaskIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'completedTasksCount': completedTasksCount,
        'pendingTasksCount': pendingTasksCount,
        'moodScore': moodScore,
        'reflectionNotes': reflectionNotes,
        'rolloverTaskIds': rolloverTaskIds,
      };

  factory EveningReflection.fromJson(Map<String, dynamic> json) =>
      EveningReflection(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        completedTasksCount: json['completedTasksCount'] as int,
        pendingTasksCount: json['pendingTasksCount'] as int,
        moodScore: json['moodScore'] as int? ?? 4,
        reflectionNotes: json['reflectionNotes'] as String? ?? '',
        rolloverTaskIds: (json['rolloverTaskIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
}
