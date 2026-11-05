import '../../core/enums/task_priority.dart';
import '../models/capture_item.dart';

/// Offline-first rule-based natural language parser for Bangla, Banglish, and English.
/// Evaluates text deterministically in sub-millisecond execution times without external API calls.
class BanglishParser {
  const BanglishParser();

  /// Converts Bengali numerals (০-৯) to Arabic numerals (0-9).
  static String normalizeNumerals(String text) {
    const bengaliToEnglish = {
      '০': '0',
      '১': '1',
      '২': '2',
      '৩': '3',
      '৪': '4',
      '৫': '5',
      '৬': '6',
      '৭': '7',
      '৮': '8',
      '৯': '9',
    };

    var result = text;
    bengaliToEnglish.forEach((bn, en) {
      result = result.replaceAll(bn, en);
    });
    return result;
  }

  /// Parses raw user input string into a structured [ParsedCaptureIntent].
  /// [referenceTime] defaults to DateTime.now() if omitted.
  static ParsedCaptureIntent parse(String input, {DateTime? referenceTime}) {
    final now = referenceTime ?? DateTime.now();
    final normalized = normalizeNumerals(input.trim());
    final lower = normalized.toLowerCase();

    // 1. Check for command palette prefix overrides (/task, /expense, /note, etc.)
    if (lower.startsWith('/task ')) {
      return _parseTask(normalized.substring(6).trim(), now, lower);
    } else if (lower.startsWith('/expense ')) {
      return _parseExpense(normalized.substring(9).trim(), now, lower);
    } else if (lower.startsWith('/note ')) {
      return _parseNote(normalized.substring(6).trim(), now);
    } else if (lower.startsWith('/habit ')) {
      return _parseHabit(normalized.substring(7).trim(), now);
    } else if (lower.startsWith('/mood ')) {
      return _parseMood(normalized.substring(6).trim(), now);
    } else if (lower.startsWith('/alarm ')) {
      return _parseAlarm(normalized.substring(7).trim(), now);
    }

    // 2. Intent Detection Strategy
    // A. Alarm detection
    if (_isAlarmIntent(lower)) {
      return _parseAlarm(normalized, now);
    }

    // B. Expense detection
    if (_isExpenseIntent(lower)) {
      return _parseExpense(normalized, now, lower);
    }

    // C. Habit detection
    if (_isHabitIntent(lower)) {
      return _parseHabit(normalized, now);
    }

    // D. Mood detection
    if (_isMoodIntent(lower)) {
      return _parseMood(normalized, now);
    }

    // E. Explicit Note detection
    if (_isNoteIntent(lower)) {
      return _parseNote(normalized, now);
    }

    // F. Task detection
    if (_isTaskIntent(lower)) {
      return _parseTask(normalized, now, lower);
    }

    // G. Fallback: If date/time is detected, treat as task; else as note
    final detectedDate = extractDateTime(normalized, now);
    if (detectedDate != null) {
      return _parseTask(normalized, now, lower);
    }

    return _parseNote(normalized, now);
  }

  // --- INTENT CLASSIFICATION MATCHERS ---

  static bool _isNoteIntent(String lower) {
    return lower.contains('notes with') ||
        lower.contains('meeting notes') ||
        lower.contains('memo') ||
        lower.contains('subnet') ||
        lower.contains('password') ||
        lower.contains('thoughts') ||
        lower.contains('quote') ||
        lower.contains('recipe');
  }

  static bool _isAlarmIntent(String lower) {
    return lower.contains('alarm') ||
        lower.contains('অ্যালার্ম') ||
        lower.contains('wake me') ||
        lower.contains('uthbo') ||
        lower.contains('ghoom theke uthbo') ||
        lower.contains('dakio') ||
        lower.contains('wake up');
  }

  static bool _isExpenseIntent(String lower) {
    // Keywords indicating spending / money transfer
    final hasExpenseKeyword = lower.contains('vara') ||
        lower.contains('ভাড়া') ||
        lower.contains('khoroch') ||
        lower.contains('খরচ') ||
        lower.contains('kinlam') ||
        lower.contains('কিনলাম') ||
        lower.contains('bazar') ||
        lower.contains('বাজার') ||
        lower.contains('dhar dilam') ||
        lower.contains('ধার দিলাম') ||
        lower.contains('dhar nilam') ||
        lower.contains('bill') ||
        lower.contains('বিল') ||
        lower.contains('spent') ||
        lower.contains('bought') ||
        lower.contains('cost') ||
        lower.contains('paid') ||
        lower.contains('payment') ||
        lower.contains('expense');

    // Or explicit currency with numbers: e.g. "500 tk", "500 taka", "৳ 500"
    final hasCurrencyPattern = RegExp(r'(\d+)\s*(?:tk|taka|৳|টাকা)').hasMatch(lower) ||
        RegExp(r'(?:tk|taka|৳|টাকা)\s*(\d+)').hasMatch(lower);

    return hasExpenseKeyword || hasCurrencyPattern;
  }

  static bool _isHabitIntent(String lower) {
    return lower.contains('habit') ||
        lower.contains('obhyas') ||
        lower.contains('অভ্যাস') ||
        lower.contains('pani khailam') ||
        lower.contains('পানি খেলাম') ||
        lower.contains('workout') ||
        lower.contains('gym') ||
        lower.contains('exercise') ||
        lower.contains('stretching') ||
        lower.contains('meditation') ||
        lower.contains('namaz') ||
        lower.contains('নামাজ') ||
        lower.contains('streak') ||
        lower.contains('walking') ||
        lower.contains('read 10 pages') ||
        lower.contains('daily water');
  }

  static bool _isMoodIntent(String lower) {
    return lower.contains('mood') ||
        lower.contains('feeling') ||
        lower.contains('mon valo') ||
        lower.contains('মন ভালো') ||
        lower.contains('মন খুব ভালো') ||
        lower.contains('mon kharap') ||
        lower.contains('মন খারাপ') ||
        lower.contains('depressed') ||
        lower.contains('anxious') ||
        lower.contains('happy') ||
        lower.contains('sad') ||
        lower.contains('khub valo') ||
        lower.contains('shanto') ||
        lower.contains('শান্ত') ||
        lower.contains('frustrated') ||
        lower.contains('stressed') ||
        lower.contains('grateful') ||
        lower.contains('excited') ||
        lower.contains('tired') ||
        lower.contains('exhausted');
  }

  static bool _isTaskIntent(String lower) {
    return lower.contains('korbo') ||
        lower.contains('করব') ||
        lower.contains('hobe') ||
        lower.contains('হবে') ||
        lower.contains('kinte') ||
        lower.contains('কিনতে') ||
        lower.contains('submit') ||
        lower.contains('call') ||
        lower.contains('phone') ||
        lower.contains('finish') ||
        lower.contains('buy') ||
        lower.contains('pathate') ||
        lower.contains('পাঠাতে') ||
        lower.contains('due') ||
        lower.contains('remind') ||
        lower.contains('todo') ||
        lower.contains('meeting') ||
        lower.contains('deadline') ||
        lower.contains('porbo') ||
        lower.contains('পড়ব') ||
        lower.contains('complete') ||
        lower.contains('send email') ||
        lower.contains('send cv') ||
        lower.contains('via email') ||
        lower.contains('doctor') ||
        lower.contains('urgent') ||
        lower.contains('joruri') ||
        lower.contains('জরুরি') ||
        lower.contains('p1') ||
        lower.contains('p2') ||
        lower.contains('p3') ||
        lower.contains('p4') ||
        lower.contains('renew') ||
        lower.contains('prepare') ||
        lower.contains('organize') ||
        lower.contains('appointment') ||
        lower.contains('followup') ||
        lower.contains('review') ||
        lower.contains('clean desk');
  }

  // --- ENTITY EXTRACTORS ---

  /// Extracts money amount in BDT (Taka).
  static double? extractAmount(String text) {
    final normalized = normalizeNumerals(text.toLowerCase());

    // Match forms like "500 tk", "500taka", "500 ৳", "500 টাকা", "৳500"
    final regexes = [
      RegExp(r'(?:tk|taka|৳|টাকা)\s*(\d+(?:\.\d+)?)'),
      RegExp(r'(\d+(?:\.\d+)?)\s*(?:tk|taka|৳|টাকা)'),
      RegExp(r'\b(\d+(?:\.\d+)?)\s*k\b'), // e.g. 5k -> 5000 (must be distinct k)
      RegExp(r'vara\s*(\d+)', caseSensitive: false),
      RegExp(r'bill\s*(\d+)', caseSensitive: false),
      RegExp(r'(\d+)\s*/-'), // e.g. 500/-
    ];

    for (final reg in regexes) {
      final match = reg.firstMatch(normalized);
      if (match != null) {
        final valStr = match.group(1);
        if (valStr != null) {
          double val = double.tryParse(valStr) ?? 0.0;
          if (match.group(0)!.trim().endsWith('k') && !match.group(0)!.contains('tk')) {
            val *= 1000;
          }
          if (val > 0) return val;
        }
      }
    }

    // Secondary pass: if text has word "vara", "bill", "khoroch" and a standalone number
    if (normalized.contains('vara') ||
        normalized.contains('khoroch') ||
        normalized.contains('bill') ||
        normalized.contains('paid') ||
        normalized.contains('dilam')) {
      final standaloneMatch = RegExp(r'\b(\d+(?:\.\d+)?)\b').firstMatch(normalized);
      if (standaloneMatch != null) {
        final val = double.tryParse(standaloneMatch.group(1)!);
        if (val != null && val > 0 && val < 500000) {
          return val;
        }
      }
    }

    return null;
  }

  /// Extracts category for expenses or habits.
  static String? extractCategory(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('rickshaw') ||
        lower.contains('bus') ||
        lower.contains('uber') ||
        lower.contains('pathao') ||
        lower.contains('vara') ||
        lower.contains('ভাড়া') ||
        lower.contains('cng') ||
        lower.contains('metro')) {
      return 'Transport';
    }
    if (lower.contains('dudh') ||
        lower.contains('dim') ||
        lower.contains('bazar') ||
        lower.contains('khabar') ||
        lower.contains('lunch') ||
        lower.contains('dinner') ||
        lower.contains('breakfast') ||
        lower.contains('coffee') ||
        lower.contains('tea') ||
        lower.contains('cha') ||
        lower.contains('food') ||
        lower.contains('groceries')) {
      return 'Food & Groceries';
    }
    if (lower.contains('wifi') ||
        lower.contains('current bill') ||
        lower.contains('gas bill') ||
        lower.contains('utility') ||
        lower.contains('mobile recharge') ||
        lower.contains('recharge')) {
      return 'Utilities & Bills';
    }
    if (lower.contains('dhar') || lower.contains('ধার') || lower.contains('loan')) {
      return 'Debt (Dhar)';
    }
    if (lower.contains('med') ||
        lower.contains('medicine') ||
        lower.contains('oshudh') ||
        lower.contains('ঔষধ') ||
        lower.contains('doctor')) {
      return 'Health';
    }
    if (lower.contains('book') ||
        lower.contains('boi') ||
        lower.contains('khata') ||
        lower.contains('course') ||
        lower.contains('tuition')) {
      return 'Education';
    }
    return null;
  }

  /// Extracts task priority based on urgency cues.
  static TaskPriority extractPriority(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('urgent') ||
        lower.contains('জরুরি') ||
        lower.contains('joruri') ||
        lower.contains('p1') ||
        lower.contains('emergency') ||
        lower.contains('khub dorkar') ||
        lower.contains('asap')) {
      return TaskPriority.p1;
    }
    if (lower.contains('p2') || lower.contains('high') || lower.contains('important')) {
      return TaskPriority.p2;
    }
    if (lower.contains('p4') ||
        lower.contains('low') ||
        lower.contains('shomoy pele') ||
        lower.contains('somoy pele') ||
        lower.contains('optional')) {
      return TaskPriority.p4;
    }
    return TaskPriority.p3;
  }

  /// Extracts due date and time from natural language text.
  static DateTime? extractDateTime(String text, DateTime reference) {
    final normalized = normalizeNumerals(text.toLowerCase());

    // 1. Determine Target Date (Day)
    DateTime targetDate = reference;
    bool dateSpecified = false;

    if (normalized.contains('kal') ||
        normalized.contains('kalke') ||
        normalized.contains('কাল') ||
        normalized.contains('কালকে') ||
        normalized.contains('tomorrow')) {
      targetDate = reference.add(const Duration(days: 1));
      dateSpecified = true;
    } else if (normalized.contains('porshu') ||
        normalized.contains('porshukaal') ||
        normalized.contains('পরশু') ||
        normalized.contains('day after tomorrow')) {
      targetDate = reference.add(const Duration(days: 2));
      dateSpecified = true;
    } else if (normalized.contains('torashu') || normalized.contains('তরশু')) {
      targetDate = reference.add(const Duration(days: 3));
      dateSpecified = true;
    } else if (normalized.contains('aj') ||
        normalized.contains('ajke') ||
        normalized.contains('আজ') ||
        normalized.contains('আজকে') ||
        normalized.contains('today') ||
        normalized.contains('tonight')) {
      targetDate = reference;
      dateSpecified = true;
    } else if (normalized.contains('next week') ||
        normalized.contains('porer shoptaho') ||
        normalized.contains('পরের সপ্তাহ')) {
      targetDate = reference.add(const Duration(days: 7));
      dateSpecified = true;
    } else {
      // Days of the week detection
      final weekdayMap = {
        'shonibar': DateTime.saturday,
        'shoni': DateTime.saturday,
        'শনিবার': DateTime.saturday,
        'robibar': DateTime.sunday,
        'robi': DateTime.sunday,
        'রবিবার': DateTime.sunday,
        'shombar': DateTime.monday,
        'shom': DateTime.monday,
        'সোমবার': DateTime.monday,
        'mongolbar': DateTime.tuesday,
        'mongol': DateTime.tuesday,
        'মঙ্গলবার': DateTime.tuesday,
        'budhbar': DateTime.wednesday,
        'budh': DateTime.wednesday,
        'বুধবার': DateTime.wednesday,
        'brihoshpotibar': DateTime.thursday,
        'brihoshpoti': DateTime.thursday,
        'বৃহস্পতিবার': DateTime.thursday,
        'shukrobar': DateTime.friday,
        'shukro': DateTime.friday,
        'শুক্রবার': DateTime.friday,
      };

      for (final entry in weekdayMap.entries) {
        if (normalized.contains(entry.key)) {
          int daysAhead = entry.value - reference.weekday;
          if (daysAhead <= 0) {
            daysAhead += 7;
          }
          if (normalized.contains('ashchhe') ||
              normalized.contains('next') ||
              normalized.contains('samner') ||
              normalized.contains('সামনের')) {
            // Already computed forward
          }
          targetDate = reference.add(Duration(days: daysAhead));
          dateSpecified = true;
          break;
        }
      }
    }

    // 2. Determine Target Time (Hour & Minute)
    int hour = 9;
    int minute = 0;
    bool timeSpecified = false;

    // Check for explicit clock time like "9am", "10:30pm", "5:30ta", "11ta", "9tai", "রাত ৯টায়"
    final clockMatch = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm|ta|tai|tay|টায়|টায়|টা)?')
        .allMatches(normalized);

    for (final match in clockMatch) {
      final hourStr = match.group(1);
      final minStr = match.group(2);
      final suffix = match.group(3)?.toLowerCase();

      if (hourStr != null) {
        final parsedHour = int.tryParse(hourStr);
        if (parsedHour != null && parsedHour >= 1 && parsedHour <= 24) {
          // Verify if it looks like a clock time or money/quantity
          if (suffix != null &&
              (suffix.startsWith('t') ||
                  suffix == 'am' ||
                  suffix == 'pm' ||
                  suffix.contains('টা'))) {
            hour = parsedHour;
            minute = minStr != null ? (int.tryParse(minStr) ?? 0) : 0;
            timeSpecified = true;

            // Handle AM/PM logic
            if (suffix == 'pm' && hour < 12) {
              hour += 12;
            } else if (suffix == 'am' && hour == 12) {
              hour = 0;
            } else if (suffix.startsWith('t') || suffix.contains('টা')) {
              // Contextual Banglish adjustments based on diurnal keywords
              if ((normalized.contains('rat') ||
                      normalized.contains('shondha') ||
                      normalized.contains('bikel') ||
                      normalized.contains('রাত') ||
                      normalized.contains('সন্ধ্যা') ||
                      normalized.contains('বিকাল')) &&
                  hour <= 11) {
                hour += 12;
              }
            }
            break;
          }
        }
      }
    }

    // Diurnal keywords if time wasn't specified explicitly
    if (!timeSpecified) {
      if (normalized.contains('sokal') || normalized.contains('সকাল') || normalized.contains('morning')) {
        hour = 8;
        minute = 30;
        timeSpecified = true;
      } else if (normalized.contains('dupur') || normalized.contains('দুপুর') || normalized.contains('noon')) {
        hour = 13;
        minute = 0;
        timeSpecified = true;
      } else if (normalized.contains('bikel') || normalized.contains('বিকাল') || normalized.contains('afternoon')) {
        hour = 16;
        minute = 30;
        timeSpecified = true;
      } else if (normalized.contains('shondha') || normalized.contains('সন্ধ্যা') || normalized.contains('evening')) {
        hour = 19;
        minute = 0;
        timeSpecified = true;
      } else if (normalized.contains('rat') || normalized.contains('রাত') || normalized.contains('night') || normalized.contains('tonight')) {
        hour = 21;
        minute = 30;
        timeSpecified = true;
      }
    }

    if (!dateSpecified && !timeSpecified) {
      return null;
    }

    return DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
  }

  /// Cleans the raw input to generate a clean title without temporal/amount noise.
  static String cleanTitle(String input) {
    var title = input.trim();
    // Remove command prefixes
    title = title.replaceAll(RegExp(r'^/(task|expense|note|habit|mood|alarm)\s+', caseSensitive: false), '');
    // Remove explicit clock times like 9ta, 9:30am, 11pm
    title = title.replaceAll(RegExp(r'\b\d{1,2}(?::\d{2})?\s*(?:am|pm|ta|tai|tay|টা)?\b', caseSensitive: false), ' ');

    // Strip known temporal noise words from edges
    final noiseWords = [
      'aj', 'ajke', 'আজ', 'আজকে', 'today',
      'kal', 'kalke', 'কাল', 'কালকে', 'tomorrow',
      'porshu', 'পরশু', 'torashu', 'তরশু',
      'sokal', 'shokal', 'সকাল', 'sokale', 'shokale',
      'dupur', 'dupure', 'দুপুর',
      'bikel', 'bikele', 'বিকাল',
      'shondha', 'shondhay', 'সন্ধ্যা',
      'rat', 'rate', 'রাত', 'রাত্রে',
      'urgent', 'joruri', 'জরুরি', 'asap', 'p1', 'p2', 'p3', 'p4',
    ];

    final words = title.split(RegExp(r'\s+'));
    final filtered = words.where((w) {
      final cleanW = w.toLowerCase().replaceAll(RegExp(r'[^\w\u0980-\u09FF]'), '');
      return !noiseWords.contains(cleanW);
    }).toList();

    var cleaned = filtered.join(' ').trim();
    if (cleaned.isEmpty) {
      cleaned = input.trim();
    }
    // Capitalize first character
    if (cleaned.isNotEmpty) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }
    return cleaned;
  }

  // --- PRIVATE BUILDERS ---

  static ParsedCaptureIntent _parseTask(String text, DateTime now, String lower) {
    final dueDate = extractDateTime(text, now);
    final priority = extractPriority(text);
    final title = cleanTitle(text);

    return ParsedCaptureIntent(
      intentType: ParsedIntentType.task,
      title: title,
      dueDate: dueDate,
      priority: priority,
      confidence: 0.92,
      rawInput: text,
      tags: const ['task'],
    );
  }

  static ParsedCaptureIntent _parseExpense(String text, DateTime now, String lower) {
    final amount = extractAmount(text);
    final category = extractCategory(text) ?? 'General';
    final title = cleanTitle(text);

    return ParsedCaptureIntent(
      intentType: ParsedIntentType.expense,
      title: title,
      dueDate: now,
      amount: amount ?? 0.0,
      category: category,
      confidence: amount != null && amount > 0 ? 0.95 : 0.80,
      rawInput: text,
      tags: ['expense', category.toLowerCase().replaceAll(' ', '_')],
    );
  }

  static ParsedCaptureIntent _parseHabit(String text, DateTime now) {
    final title = cleanTitle(text);
    return ParsedCaptureIntent(
      intentType: ParsedIntentType.habit,
      title: title,
      dueDate: now,
      confidence: 0.90,
      rawInput: text,
      tags: const ['habit'],
    );
  }

  static ParsedCaptureIntent _parseMood(String text, DateTime now) {
    final title = cleanTitle(text);
    return ParsedCaptureIntent(
      intentType: ParsedIntentType.mood,
      title: title,
      dueDate: now,
      confidence: 0.90,
      rawInput: text,
      tags: const ['mood'],
    );
  }

  static ParsedCaptureIntent _parseAlarm(String text, DateTime now) {
    final dt = extractDateTime(text, now) ?? now.add(const Duration(hours: 8));
    final title = cleanTitle(text);
    return ParsedCaptureIntent(
      intentType: ParsedIntentType.alarm,
      title: title.isNotEmpty ? title : 'Wake Quest',
      dueDate: dt,
      confidence: 0.94,
      rawInput: text,
      tags: const ['alarm'],
    );
  }

  static ParsedCaptureIntent _parseNote(String text, DateTime now) {
    return ParsedCaptureIntent(
      intentType: ParsedIntentType.note,
      title: text.length > 50 ? '${text.substring(0, 47)}...' : text,
      dueDate: now,
      confidence: 0.85,
      rawInput: text,
      tags: const ['note'],
    );
  }
}
