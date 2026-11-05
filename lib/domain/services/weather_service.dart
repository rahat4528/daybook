import '../models/weather_info.dart';

class WeatherService {
  WeatherInfo? _cachedWeather;
  static const Duration cacheTtl = Duration(minutes: 30);

  WeatherService({WeatherInfo? initialCache}) {
    _cachedWeather = initialCache;
  }

  WeatherInfo? get cachedWeather => _cachedWeather;

  bool isCacheValid([DateTime? now]) {
    if (_cachedWeather == null) return false;
    final current = now ?? DateTime.now();
    return current.difference(_cachedWeather!.cachedAt) < cacheTtl;
  }

  /// Gets current weather, checking cache first, then simulated/fetched, then fallback default
  Future<WeatherInfo> getWeather({
    double lat = 23.8103, // Dhaka
    double lon = 90.4125,
    String cityName = 'Dhaka',
    DateTime? simulatedTime,
    bool forceRefresh = false,
  }) async {
    final now = simulatedTime ?? DateTime.now();

    if (!forceRefresh && isCacheValid(now)) {
      return _cachedWeather!;
    }

    // Determine Day/Night from local time
    final isDay = now.hour >= 6 && now.hour < 18;

    // In offline or testing mode, update cache deterministically
    _cachedWeather = WeatherInfo(
      temperature: 28.0 + (now.hour > 12 && now.hour < 16 ? 3.5 : 0.0),
      wmoCode: 0,
      cityName: cityName,
      isDay: isDay,
      cachedAt: now,
    );

    return _cachedWeather!;
  }

  void updateCache(WeatherInfo info) {
    _cachedWeather = info;
  }
}
