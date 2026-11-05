class AppLocale {
  final bool isBangla;

  const AppLocale({this.isBangla = false});

  /// Translates numbers to Bengali script if locale is Bangla.
  String formatNumber(dynamic value) {
    if (!isBangla) return value.toString();
    const englishToBangla = {
      '0': '০',
      '1': '১',
      '2': '২',
      '3': '৩',
      '4': '৪',
      '5': '৫',
      '6': '৬',
      '7': '৭',
      '8': '৮',
      '9': '৯',
    };
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      buffer.write(englishToBangla[str[i]] ?? str[i]);
    }
    return buffer.toString();
  }

  // Common UI Strings
  String get appTitle => isBangla ? 'ডেবুক (Daybook)' : 'Daybook';
  String get today => isBangla ? 'আজকের' : 'Today';
  String get tasks => isBangla ? 'টাস্ক' : 'Tasks';
  String get planner => isBangla ? 'পরিকল্পনা' : 'Planner';
  String get alarms => isBangla ? 'স্মার্ট অ্যালার্ম' : 'Alarms';
  String get assistant => isBangla ? 'সহকারী' : 'Assistant';
  String get memories => isBangla ? 'স্মৃতি ভল্ট' : 'Memories';
  String get settings => isBangla ? 'সেটিংস' : 'Settings';

  String get morningBriefing => isBangla ? 'সকালের ব্রিফিং' : 'Morning Briefing';
  String get eveningReflection => isBangla ? 'রাতের পর্যালোচনা' : 'Evening Reflection';
  String get newTask => isBangla ? 'নতুন টাস্ক' : 'New Task';
  String get autoPlan => isBangla ? 'স্বয়ংক্রিয় দিন পরিকল্পনা' : 'Auto-Plan Day';
  String get batteryGuide => isBangla ? 'ব্যাটারি অপ্টিমাইজেশন গাইড' : 'Battery Saver Guide';
}

