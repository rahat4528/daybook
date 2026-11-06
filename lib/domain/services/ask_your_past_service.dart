import '../models/day_page.dart';
import '../models/journal_entry.dart';
import '../../data/app_repository.dart';

class PastQueryResult {
  final String query;
  final String answer;
  final List<JournalEntry> matchedEntries;
  final String? targetDayKey;
  final bool hasResults;

  const PastQueryResult({
    required this.query,
    required this.answer,
    required this.matchedEntries,
    this.targetDayKey,
    required this.hasResults,
  });
}

class AskYourPastService {
  final AppRepository appRepository;

  AskYourPastService({required this.appRepository});

  /// Conjunct-safe Bangla and English tokenization
  static List<String> tokenize(String input) {
    if (input.trim().isEmpty) return [];

    // Normalize Unicode NFC
    final normalized = input.toLowerCase().trim();

    // Preserve alphanumeric, English words, and Bangla Unicode range (\u0980-\u09FF)
    final regex = RegExp(r'[a-zA-Z0-9\u0980-\u09FF]+');
    final matches = regex.allMatches(normalized);

    final tokens = <String>[];
    for (final m in matches) {
      final word = m.group(0)!;
      // Filter out pure common noise words
      if (!_isStopWord(word)) {
        tokens.add(word);
      }
    }
    return tokens;
  }

  static bool _isStopWord(String word) {
    const stops = {
      'the', 'a', 'an', 'is', 'was', 'did', 'i', 'my', 'when', 'what', 'how', 'much', 'at', 'in', 'on',
      'or', 'and', 'had', 'have', 'has', 'to', 'for', 'of', 'with', 'by', 'be', 'been',
      'last', 'time', 'were', 'ki', 'kobe', 'amar', 'ami', 'koto', 'kon', 'chilo', 'korechi'
    };
    return stops.contains(word.toLowerCase());
  }

  /// Generates character n-grams (size 3) for robust fuzzy/conjunct matching
  static Set<String> generateNGrams(String token, {int n = 3}) {
    final set = <String>{};
    if (token.length <= n) {
      set.add(token);
      return set;
    }
    for (int i = 0; i <= token.length - n; i++) {
      set.add(token.substring(i, i + n));
    }
    return set;
  }

  /// Main natural language search method over user's past
  Future<PastQueryResult> askQuestion(String naturalQuery, {bool isBangla = false}) async {
    final clean = naturalQuery.trim();
    if (clean.isEmpty) {
      return PastQueryResult(
        query: naturalQuery,
        answer: isBangla ? "অনুগ্রহ করে একটি প্রশ্ন লিখুন।" : "Please enter a question to search your past.",
        matchedEntries: [],
        hasResults: false,
      );
    }

    final queryTokens = tokenize(clean);
    final allEntries = appRepository.entriesRepository.entries;
    final allTasks = appRepository.taskService.tasks;
    final allNotes = appRepository.inboxService.notes;

    // Check for temporal keywords
    DateTime? filterAfter;
    DateTime? filterBefore;
    final lower = clean.toLowerCase();

    if (lower.contains('yesterday') || lower.contains('গতকাল')) {
      final yest = DateTime.now().subtract(const Duration(days: 1));
      filterAfter = DateTime(yest.year, yest.month, yest.day);
      filterBefore = DateTime(yest.year, yest.month, yest.day, 23, 59, 59);
    } else if (lower.contains('last week') || lower.contains('গত সপ্তাহে')) {
      filterAfter = DateTime.now().subtract(const Duration(days: 7));
    } else if (lower.contains('last month') || lower.contains('গত মাসে')) {
      filterAfter = DateTime.now().subtract(const Duration(days: 30));
    }

    final matched = <JournalEntry>[];

    // 1. Search in Single Event Log Entries
    for (final entry in allEntries) {
      if (filterAfter != null && entry.ts.isBefore(filterAfter)) continue;
      if (filterBefore != null && entry.ts.isAfter(filterBefore)) continue;

      final textToMatch = '${entry.displayText()} ${entry.payload}'.toLowerCase();
      int matchScore = 0;

      for (final token in queryTokens) {
        if (token.length < 3) continue;
        final wordRegex = RegExp(r'\b' + RegExp.escape(token) + r'\b', caseSensitive: false);
        if (wordRegex.hasMatch(textToMatch)) {
          matchScore += 2;
        } else if (RegExp(r'[\u0980-\u09FF]').hasMatch(token)) {
          // Check n-gram overlap for Bangla conjuncts / inflections only
          final tokenGrams = generateNGrams(token);
          for (final gram in tokenGrams) {
            if (textToMatch.contains(gram)) {
              matchScore += 1;
              break;
            }
          }
        }
      }

      if (matchScore > 0) {
        matched.add(entry);
      }
    }

    // 2. Also search tasks if no entries matched
    if (matched.isEmpty) {
      for (final task in allTasks) {
        final text = '${task.title} ${task.notes}'.toLowerCase();
        for (final token in queryTokens) {
          if (token.length < 3) continue;
          final wordRegex = RegExp(r'\b' + RegExp.escape(token) + r'\b', caseSensitive: false);
          if (wordRegex.hasMatch(text)) {
            // Synthesize an entry view
            matched.add(JournalEntry(
              id: 'task_ref_${task.id}',
              type: EntryType.taskCompleted,
              ts: task.createdAt,
              dayKey: DayPageModel.formatDayKey(task.createdAt),
              payload: {
                'title': task.title,
                'note': task.notes.isNotEmpty ? task.notes : 'Task recorded',
              },
            ));
            break;
          }
        }
      }
    }

    // 3. Search notes
    if (matched.isEmpty) {
      for (final note in allNotes) {
        final text = '${note.title} ${note.body}'.toLowerCase();
        for (final token in queryTokens) {
          if (token.length < 3) continue;
          final wordRegex = RegExp(r'\b' + RegExp.escape(token) + r'\b', caseSensitive: false);
          if (wordRegex.hasMatch(text)) {
            matched.add(JournalEntry(
              id: 'note_ref_${note.id}',
              type: EntryType.manualNote,
              ts: note.createdAt,
              dayKey: note.dayKey,
              payload: {
                'title': note.title,
                'note': note.body,
              },
            ));
            break;
          }
        }
      }
    }

    // Sort by timestamp descending (newest first)
    matched.sort((a, b) => b.ts.compareTo(a.ts));

    if (matched.isEmpty) {
      return PastQueryResult(
        query: naturalQuery,
        answer: isBangla
            ? "এই বিষয়ে আপনার অতীতে কোনো তথ্য পাওয়া যায়নি। (DayBook কখনোই বানিয়ে উত্তর দেয় না)"
            : "No records found in your past entries matching that query. DayBook never fabricates facts.",
        matchedEntries: [],
        hasResults: false,
      );
    }

    final mostRecent = matched.first;
    final dayKey = mostRecent.dayKey;

    // Build grounded factual answer
    final answer = _synthesizeGroundedAnswer(
      clean,
      mostRecent,
      matched.length,
      isBangla: isBangla,
    );

    return PastQueryResult(
      query: naturalQuery,
      answer: answer,
      matchedEntries: matched,
      targetDayKey: dayKey,
      hasResults: true,
    );
  }

  String _synthesizeGroundedAnswer(
    String query,
    JournalEntry entry,
    int totalCount, {
    required bool isBangla,
  }) {
    final dt = entry.ts;
    final dateFormatted = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    final title = entry.payload['title'] as String? ?? entry.displayText(isBangla: isBangla);
    final details = entry.payload['note'] as String? ?? entry.payload['description'] as String? ?? entry.displayText(isBangla: isBangla);

    if (isBangla) {
      return "পাওয়া গেছে ($dateFormatted তারিখে): **$title**।\nবিবরণ: $details\n(মোট $totalCount টি প্রাসঙ্গিক এন্ট্রি সনাক্ত হয়েছে)";
    } else {
      return "Found on **$dateFormatted**: **$title**.\nDetails: $details\n(Retrieved $totalCount matching record${totalCount > 1 ? 's' : ''} from your past)";
    }
  }
}
