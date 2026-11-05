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
  String get appTitle => isBangla ? 'দিনবই' : 'DayBook';
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

  // PART 2 Strings
  String get dayPage => isBangla ? 'দিনের পৃষ্ঠা' : 'Day Page';
  String get theBook => isBangla ? 'দিনবই' : 'Book';
  String get onThisDay => isBangla ? 'এই দিনে (থ্রোব্যাক)' : 'On This Day';
  String get timeCapsule => isBangla ? 'টাইম ক্যাপসুল' : 'Time Capsule';
  String get nightlySummary => isBangla ? 'রাতের সারসংক্ষেপ' : 'Nightly Summary';
  String get reflection => isBangla ? 'প্রতিফলন' : 'Daily Reflection';
  String get gratitude => isBangla ? 'কৃতজ্ঞতা' : 'Gratitude';
  String get dayScore => isBangla ? 'দিন স্কোর' : 'Day Score';
  String get exportBook => isBangla ? 'বই রপ্তানি' : 'Export Book';
  String get printFriendly => isBangla ? 'প্রিন্ট-বান্ধব' : 'Print Friendly';
  String get starDay => isBangla ? 'স্টার দিন' : 'Star Day';
  String get pinnedMoment => isBangla ? 'পিন করা মুহূর্ত' : 'Pinned Moment';
  String get undoAction => isBangla ? 'পূর্বাবস্থায় ফেরান' : 'Undo';
  String get addNote => isBangla ? 'নোট লিখুন' : 'Add Note';
  String get searchEntries => isBangla ? 'এন্ট্রি খুঁজুন' : 'Search Entries';
  String get monthShelf => isBangla ? 'মাসের তাক' : 'Month Shelf';
  String get heatCalendar => isBangla ? 'হিটম্যাপ ক্যালেন্ডার' : 'Heatmap Calendar';
}
