class WidgetPayload {
  final String widgetType;
  final Map<String, dynamic> data;
  final DateTime updatedAt;

  const WidgetPayload({
    required this.widgetType,
    required this.data,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'widgetType': widgetType,
        'data': data,
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class QuickSurfacesService {
  /// Generates the payload for Android Today Home Widget
  static WidgetPayload buildTodayWidgetData({
    required int dayScore,
    required String skyGlyph,
    required String topTaskTitle,
    required int completedTasks,
    required int totalTasks,
    required double wakingDayElapsedPercent,
  }) {
    return WidgetPayload(
      widgetType: 'TODAY_HOME_WIDGET',
      data: {
        'dayScore': dayScore,
        'skyGlyph': skyGlyph,
        'topTaskTitle': topTaskTitle,
        'completedTasks': completedTasks,
        'totalTasks': totalTasks,
        'wakingDayElapsedPercent': wakingDayElapsedPercent.toStringAsFixed(1),
        'deepLink': 'daybook://today',
      },
      updatedAt: DateTime.now(),
    );
  }

  /// Generates the payload for Android Habits Widget
  static WidgetPayload buildHabitsWidgetData({
    required List<Map<String, dynamic>> habits,
  }) {
    return WidgetPayload(
      widgetType: 'HABITS_WIDGET',
      data: {
        'habits': habits,
        'deepLink': 'daybook://habits',
      },
      updatedAt: DateTime.now(),
    );
  }

  /// Generates the payload for Android Next Alarm Widget
  static WidgetPayload buildNextAlarmWidgetData({
    required String timeFormatted,
    required String label,
    required String challengeName,
    required String timeRemaining,
  }) {
    return WidgetPayload(
      widgetType: 'NEXT_ALARM_WIDGET',
      data: {
        'timeFormatted': timeFormatted,
        'label': label,
        'challengeName': challengeName,
        'timeRemaining': timeRemaining,
        'deepLink': 'daybook://alarm',
      },
      updatedAt: DateTime.now(),
    );
  }

  /// Generates Quick-Capture Notification payload
  static Map<String, dynamic> buildQuickCaptureNotificationPayload({
    required bool isBangla,
  }) {
    return {
      'channelId': 'daybook_quick_capture',
      'channelName': isBangla ? 'দ্রুত সংযোজন (Quick Capture)' : 'Quick Capture',
      'title': isBangla ? 'দিনবই কুইক ক্যাপচার' : 'DayBook Quick Capture',
      'body': isBangla ? 'টাস্ক, হিসাব বা নোট লিখে রাখুন...' : 'Capture task, expense, or thought...',
      'deepLink': 'daybook://capture',
      'priority': 'LOW',
      'isOngoing': true,
    };
  }
}
