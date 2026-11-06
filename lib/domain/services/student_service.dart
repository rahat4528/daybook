import 'package:flutter/foundation.dart';
import '../models/day_page.dart';
import '../models/journal_entry.dart';
import '../models/student_models.dart';
import '../../data/repositories/entries_repository.dart';

class StudentService extends ChangeNotifier {
  static int _counter = 0;

  final Map<String, CourseItem> _courses = {};
  final Map<String, ExamItem> _exams = {};
  final Map<String, AssignmentItem> _assignments = {};
  final Map<String, FlashcardDeck> _decks = {};

  // --- GETTERS ---

  List<CourseItem> get allCourses => _courses.values.toList()
    ..sort((a, b) => a.code.compareTo(b.code));

  List<ExamItem> get allExams {
    final list = _exams.values.toList();
    list.sort((a, b) => a.examDate.compareTo(b.examDate));
    return list;
  }

  List<ExamItem> get upcomingExams {
    final now = DateTime.now();
    return allExams.where((e) => e.isUpcoming(now)).toList();
  }

  List<ExamItem> get urgentExams {
    final now = DateTime.now();
    return allExams.where((e) => e.isUrgent(now)).toList();
  }

  List<AssignmentItem> get allAssignments {
    final list = _assignments.values.toList();
    list.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return list;
  }

  List<AssignmentItem> get pendingAssignments =>
      allAssignments.where((a) => !a.isSubmitted).toList();

  List<FlashcardDeck> get allDecks => _decks.values.toList()
    ..sort((a, b) => a.title.compareTo(b.title));

  double get totalEnrolledCredits =>
      allCourses.fold(0.0, (sum, c) => sum + c.creditHours);

  // --- SUPERMEMO SM-2 SPACED REPETITION ENGINE ---

  static SM2Result calculateSM2({
    required int repetition,
    required double easinessFactor,
    required int intervalDays,
    required int qualityRating, // 0 to 5
    DateTime? reviewDate,
  }) {
    if (qualityRating < 0 || qualityRating > 5) {
      throw ArgumentError('Quality rating must be strictly between 0 and 5.');
    }

    final now = reviewDate ?? DateTime.now();
    int newRepetition;
    int newInterval;
    double newEF;

    if (qualityRating >= 3) {
      // Correct recall
      if (repetition == 0) {
        newInterval = 1;
      } else if (repetition == 1) {
        newInterval = 6;
      } else {
        newInterval = (intervalDays * easinessFactor).round();
      }
      newRepetition = repetition + 1;
    } else {
      // Blackout or incorrect recall: reset repetition and interval to 1
      newRepetition = 0;
      newInterval = 1;
    }

    // SuperMemo formula: EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    final qDiff = 5 - qualityRating;
    newEF = easinessFactor + (0.1 - qDiff * (0.08 + qDiff * 0.02));
    if (newEF < 1.3) newEF = 1.3; // Min threshold per SuperMemo specification

    final nextDate = DateTime(now.year, now.month, now.day).add(Duration(days: newInterval));

    return SM2Result(
      repetition: newRepetition,
      intervalDays: newInterval,
      easinessFactor: double.parse(newEF.toStringAsFixed(2)),
      nextReviewDate: nextDate,
    );
  }

  // --- COURSES CRUD ---

  CourseItem addCourse({
    required String code,
    required String title,
    double creditHours = 3.0,
    String instructor = '',
    String room = '',
    String semester = 'Spring 2026',
    String colorHex = '#B6FF00',
  }) {
    final id = 'crs_${DateTime.now().microsecondsSinceEpoch}_${++_counter}';
    final course = CourseItem(
      id: id,
      code: code.trim(),
      title: title.trim(),
      creditHours: creditHours,
      instructor: instructor.trim(),
      room: room.trim(),
      semester: semester.trim(),
      colorHex: colorHex,
    );
    _courses[id] = course;
    notifyListeners();
    return course;
  }

  void updateCourse(CourseItem course) {
    _courses[course.id] = course;
    notifyListeners();
  }

  void restoreCourse(CourseItem course) {
    _courses[course.id] = course;
    notifyListeners();
  }

  void restoreExam(ExamItem exam) {
    _exams[exam.id] = exam;
    notifyListeners();
  }

  void restoreAssignment(AssignmentItem assignment) {
    _assignments[assignment.id] = assignment;
    notifyListeners();
  }

  bool deleteCourse(String id) {
    final removed = _courses.remove(id);
    if (removed != null) {
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- EXAMS CRUD ---

  ExamItem addExam({
    required String courseId,
    required String courseCode,
    required String title,
    required DateTime examDate,
    int durationMinutes = 120,
    String room = '',
    String seatNumber = '',
    double weightPercentage = 40.0,
    String syllabus = '',
    EntriesRepository? entriesRepo,
  }) {
    final id = 'exam_${DateTime.now().microsecondsSinceEpoch}_${++_counter}';
    final exam = ExamItem(
      id: id,
      courseId: courseId,
      courseCode: courseCode.trim(),
      title: title.trim(),
      examDate: examDate,
      durationMinutes: durationMinutes,
      room: room.trim(),
      seatNumber: seatNumber.trim(),
      weightPercentage: weightPercentage,
      syllabus: syllabus.trim(),
    );
    _exams[id] = exam;

    // Log to Day Page single event log
    entriesRepo?.insertEntry(JournalEntry(
      id: 'entry_exam_$id',
      type: EntryType.manualNote,
      ts: DateTime.now(),
      dayKey: DayPageModel.formatDayKey(DateTime.now()),
      payload: {
        'examId': id,
        'courseCode': exam.courseCode,
        'title': exam.title,
        'examDate': examDate.toIso8601String(),
        'room': exam.room,
        'seat': exam.seatNumber,
      },
    ));

    notifyListeners();
    return exam;
  }

  bool deleteExam(String id) {
    final removed = _exams.remove(id);
    if (removed != null) {
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- ASSIGNMENTS CRUD ---

  AssignmentItem addAssignment({
    required String courseId,
    required String title,
    required DateTime dueAt,
    double weightPercentage = 10.0,
    String notes = '',
  }) {
    final id = 'asgn_${DateTime.now().microsecondsSinceEpoch}_${++_counter}';
    final asgn = AssignmentItem(
      id: id,
      courseId: courseId,
      title: title.trim(),
      dueAt: dueAt,
      weightPercentage: weightPercentage,
      notes: notes.trim(),
    );
    _assignments[id] = asgn;
    notifyListeners();
    return asgn;
  }

  bool toggleAssignmentSubmitted(String id, {EntriesRepository? entriesRepo}) {
    final asgn = _assignments[id];
    if (asgn == null) return false;

    final updated = asgn.copyWith(isSubmitted: !asgn.isSubmitted);
    _assignments[id] = updated;

    if (updated.isSubmitted) {
      final now = DateTime.now();
      entriesRepo?.insertEntry(JournalEntry(
        id: 'entry_asgn_$id',
        type: EntryType.taskCompleted,
        ts: now,
        dayKey: DayPageModel.formatDayKey(now),
        payload: {
          'assignmentId': id,
          'title': updated.title,
          'action': 'submitted',
        },
      ));
    }

    notifyListeners();
    return true;
  }

  bool deleteAssignment(String id) {
    final removed = _assignments.remove(id);
    if (removed != null) {
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- DECKS & FLASHCARDS CRUD ---

  FlashcardDeck createDeck({
    required String title,
    String? courseId,
    String description = '',
  }) {
    final id = 'deck_${DateTime.now().microsecondsSinceEpoch}_${++_counter}';
    final deck = FlashcardDeck(
      id: id,
      title: title.trim(),
      courseId: courseId,
      description: description.trim(),
      createdAt: DateTime.now(),
    );
    _decks[id] = deck;
    notifyListeners();
    return deck;
  }

  FlashcardItem addFlashcard({
    required String deckId,
    required String front,
    required String back,
    String hint = '',
    DateTime? nextReviewDate,
  }) {
    final deck = _decks[deckId];
    if (deck == null) {
      throw StateError('Flashcard deck not found for id $deckId');
    }

    final now = DateTime.now();
    final cardId = 'card_${now.microsecondsSinceEpoch}_${++_counter}';
    final card = FlashcardItem(
      id: cardId,
      deckId: deckId,
      front: front.trim(),
      back: back.trim(),
      hint: hint.trim(),
      nextReviewDate: nextReviewDate ?? now,
      lastReviewedAt: now,
    );

    final updatedCards = List<FlashcardItem>.from(deck.cards)..add(card);
    _decks[deckId] = deck.copyWith(cards: updatedCards);
    notifyListeners();
    return card;
  }

  List<FlashcardItem> getDueCardsForDeck(String deckId, {DateTime? asOf}) {
    final deck = _decks[deckId];
    if (deck == null) return [];
    final now = asOf ?? DateTime.now();
    return deck.cards.where((c) => c.isDue(now)).toList();
  }

  /// Reviews a flashcard using SM-2 algorithm, updates its interval, and logs to single event log
  FlashcardItem reviewCard({
    required String deckId,
    required String cardId,
    required int qualityRating, // 0 to 5
    DateTime? reviewDate,
    EntriesRepository? entriesRepo,
  }) {
    final deck = _decks[deckId];
    if (deck == null) {
      throw StateError('Flashcard deck not found for id $deckId');
    }

    final cardIndex = deck.cards.indexWhere((c) => c.id == cardId);
    if (cardIndex == -1) {
      throw StateError('Card not found for id $cardId');
    }

    final card = deck.cards[cardIndex];
    final now = reviewDate ?? DateTime.now();

    final sm2 = calculateSM2(
      repetition: card.repetition,
      easinessFactor: card.easinessFactor,
      intervalDays: card.intervalDays,
      qualityRating: qualityRating,
      reviewDate: now,
    );

    final updatedCard = card.copyWith(
      repetition: sm2.repetition,
      easinessFactor: sm2.easinessFactor,
      intervalDays: sm2.intervalDays,
      nextReviewDate: sm2.nextReviewDate,
      lastReviewedAt: now,
    );

    final updatedCards = List<FlashcardItem>.from(deck.cards)..[cardIndex] = updatedCard;
    _decks[deckId] = deck.copyWith(cards: updatedCards);

    // Write to Day Page single event log
    entriesRepo?.insertEntry(JournalEntry(
      id: 'entry_review_${now.microsecondsSinceEpoch}_${++_counter}',
      type: EntryType.taskCompleted,
      ts: now,
      dayKey: DayPageModel.formatDayKey(now),
      payload: {
        'deckId': deckId,
        'deckTitle': deck.title,
        'cardId': cardId,
        'qualityRating': qualityRating,
        'nextIntervalDays': sm2.intervalDays,
        'easinessFactor': sm2.easinessFactor,
      },
    ));

    notifyListeners();
    return updatedCard;
  }

  bool deleteDeck(String deckId) {
    final removed = _decks.remove(deckId);
    if (removed != null) {
      notifyListeners();
      return true;
    }
    return false;
  }
}
