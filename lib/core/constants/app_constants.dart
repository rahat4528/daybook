/// Global constants and configuration values for Daybook.
class AppConstants {
  static const String appName = 'Daybook';
  static const String appTagline = 'AI Daily Operating System & Life Companion';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String tasksKey = 'daybook_tasks_data';
  static const String alarmsKey = 'daybook_alarms_data';
  static const String memoriesKey = 'daybook_memories_data';
  static const String planBlocksKey = 'daybook_plan_blocks_data';
  static const String routinesKey = 'daybook_routines_data';
  static const String chatMessagesKey = 'daybook_chat_history_data';
  static const String settingsKey = 'daybook_settings_data';

  // Defaults
  static const String defaultCity = 'Dhaka';
  static const double defaultLat = 23.8103;
  static const double defaultLng = 90.4125;
  static const int defaultWakeHour = 6;
  static const int defaultWakeMinute = 30;
  static const int defaultSleepHour = 23;
  static const int defaultSleepMinute = 0;

  // Categories
  static const List<String> taskCategories = [
    'Work',
    'Study',
    'Personal',
    'Health',
    'Finance',
    'Creative',
  ];

  // Safety settings
  static const int maxAlarmRingMinutes = 15;
  static const int maxSnoozeCount = 3;
  static const int snoozeDurationMinutes = 5;
}

