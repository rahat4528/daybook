import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daybook/domain/services/student_service.dart';
import 'package:daybook/data/repositories/entries_repository.dart';
import 'package:daybook/presentation/screens/student_screen.dart';

void main() {
  group('Part 10: SuperMemo SM-2 Mathematical Spaced Repetition Engine', () {
    test('Initial review (n=0) with perfect recall (q=5) yields 1 day interval and increases EF', () {
      final now = DateTime(2026, 11, 6);
      final res = StudentService.calculateSM2(
        repetition: 0,
        easinessFactor: 2.5,
        intervalDays: 1,
        qualityRating: 5,
        reviewDate: now,
      );

      expect(res.repetition, equals(1));
      expect(res.intervalDays, equals(1));
      expect(res.easinessFactor, equals(2.6)); // 2.5 + (0.1 - 0) = 2.6
      expect(res.nextReviewDate, equals(DateTime(2026, 11, 7)));
    });

    test('Second review (n=1) with correct recall (q=4) yields 6 days interval', () {
      final now = DateTime(2026, 11, 7);
      final res = StudentService.calculateSM2(
        repetition: 1,
        easinessFactor: 2.6,
        intervalDays: 1,
        qualityRating: 4,
        reviewDate: now,
      );

      expect(res.repetition, equals(2));
      expect(res.intervalDays, equals(6));
      expect(res.easinessFactor, closeTo(2.6, 0.01)); // qDiff=1 -> 2.6 + (0.1 - (0.08+0.02)) = 2.6
      expect(res.nextReviewDate, equals(DateTime(2026, 11, 13)));
    });

    test('Third review (n=2) with q=5 scales interval by easiness factor', () {
      final now = DateTime(2026, 11, 13);
      final res = StudentService.calculateSM2(
        repetition: 2,
        easinessFactor: 2.6,
        intervalDays: 6,
        qualityRating: 5,
        reviewDate: now,
      );

      expect(res.repetition, equals(3));
      // 6 * 2.6 = 15.6 -> round(15.6) = 16 days
      expect(res.intervalDays, equals(16));
      expect(res.easinessFactor, equals(2.7));
      expect(res.nextReviewDate, equals(DateTime(2026, 11, 29)));
    });

    test('Blackout / failed recall (q < 3) resets repetition and interval to 1', () {
      final now = DateTime(2026, 11, 6);
      final res = StudentService.calculateSM2(
        repetition: 4,
        easinessFactor: 2.5,
        intervalDays: 25,
        qualityRating: 1, // Complete failure
        reviewDate: now,
      );

      expect(res.repetition, equals(0));
      expect(res.intervalDays, equals(1));
      expect(res.nextReviewDate, equals(DateTime(2026, 11, 7)));
    });

    test('Easiness Factor never drops below theoretical floor of 1.3', () {
      final now = DateTime(2026, 11, 6);
      double currentEF = 1.4;

      // Force severe consecutive failures
      for (int i = 0; i < 5; i++) {
        final res = StudentService.calculateSM2(
          repetition: 0,
          easinessFactor: currentEF,
          intervalDays: 1,
          qualityRating: 0,
          reviewDate: now,
        );
        currentEF = res.easinessFactor;
      }

      expect(currentEF, equals(1.3));
    });

    test('Invalid quality ratings outside 0..5 throw ArgumentError', () {
      expect(
        () => StudentService.calculateSM2(
          repetition: 0,
          easinessFactor: 2.5,
          intervalDays: 1,
          qualityRating: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => StudentService.calculateSM2(
          repetition: 0,
          easinessFactor: 2.5,
          intervalDays: 1,
          qualityRating: 6,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Part 10: StudentService Academic Courses, Exams & Assignments', () {
    late StudentService studentService;
    late EntriesRepository entriesRepo;

    setUp(() {
      studentService = StudentService();
      entriesRepo = EntriesRepository();
    });

    test('Course management and total credits calculation', () {
      final c1 = studentService.addCourse(
        code: 'CSE 411',
        title: 'Compiler Design',
        creditHours: 3.0,
      );
      final c2 = studentService.addCourse(
        code: 'CSE 412',
        title: 'Compiler Design Lab',
        creditHours: 1.5,
      );

      expect(c1.code, equals('CSE 411'));
      expect(studentService.allCourses.length, equals(2));
      expect(studentService.totalEnrolledCredits, equals(4.5));

      studentService.deleteCourse(c2.id);
      expect(studentService.allCourses.length, equals(1));
      expect(studentService.totalEnrolledCredits, equals(3.0));
    });

    test('Exams timetable, countdown calculation and urgent exam alerts', () {
      final now = DateTime.now();
      final course = studentService.addCourse(code: 'CSE 321', title: 'Operating Systems');

      // Urgent exam: in 3 days
      final urgentExam = studentService.addExam(
        courseId: course.id,
        courseCode: course.code,
        title: 'Midterm Exam',
        examDate: now.add(const Duration(days: 3)),
        room: 'Exam Hall 1',
        seatNumber: 'Row 2, Seat 5',
        entriesRepo: entriesRepo,
      );

      // Distant exam: in 30 days
      studentService.addExam(
        courseId: course.id,
        courseCode: course.code,
        title: 'Final Exam',
        examDate: now.add(const Duration(days: 30)),
        room: 'Exam Hall 3',
        seatNumber: 'Row 5, Seat 1',
        entriesRepo: entriesRepo,
      );

      expect(studentService.allExams.length, equals(2));
      expect(studentService.urgentExams.length, equals(1));
      expect(studentService.urgentExams.first.id, equals(urgentExam.id));
      expect(urgentExam.daysUntil(now), equals(3));
    });

    test('Assignments tracking and submission logging to single event log', () {
      final now = DateTime.now();
      final course = studentService.addCourse(code: 'MAT 102', title: 'Linear Algebra');

      final asgn = studentService.addAssignment(
        courseId: course.id,
        title: 'Problem Set 4: Eigenvalues & Vector Spaces',
        dueAt: now.add(const Duration(days: 5)),
        weightPercentage: 10.0,
      );

      expect(asgn.isSubmitted, isFalse);
      expect(studentService.pendingAssignments.length, equals(1));

      // Toggle submit
      studentService.toggleAssignmentSubmitted(asgn.id, entriesRepo: entriesRepo);
      expect(studentService.pendingAssignments.isEmpty, isTrue);

      final loggedEntries = entriesRepo.entries;
      expect(loggedEntries.any((e) => e.payload['action'] == 'submitted'), isTrue);
    });

    test('Flashcard Deck review session updates SM-2 cards and logs to entries', () {
      final now = DateTime.now();
      final deck = studentService.createDeck(
        title: 'Algorithms Revision',
        description: 'Graph search & dynamic programming',
      );

      final card = studentService.addFlashcard(
        deckId: deck.id,
        front: 'What is the time complexity of Dijkstra with Fibonacci Heap?',
        back: 'O(V log V + E)',
        hint: 'Fibonacci heap amortized decrease-key is O(1)',
        nextReviewDate: now.subtract(const Duration(hours: 2)), // Due
      );

      expect(studentService.getDueCardsForDeck(deck.id).length, equals(1));

      // Review card with quality rating 5
      final updated = studentService.reviewCard(
        deckId: deck.id,
        cardId: card.id,
        qualityRating: 5,
        entriesRepo: entriesRepo,
      );

      expect(updated.repetition, equals(1));
      expect(updated.intervalDays, equals(1));
      expect(updated.easinessFactor, equals(2.6));

      // Verify single event log entry
      final reviewEntries = entriesRepo.entries.where((e) => e.payload['deckId'] == deck.id).toList();
      expect(reviewEntries.length, equals(1));
      expect(reviewEntries.first.payload['qualityRating'], equals(5));
    });
  });

  group('Part 10: StudentScreen Widget Smoke Tests', () {
    late StudentService studentService;
    late EntriesRepository entriesRepo;

    setUp(() {
      studentService = StudentService();
      entriesRepo = EntriesRepository();

      final cse = studentService.addCourse(
        code: 'CSE 411',
        title: 'Compiler Design',
        creditHours: 3.0,
        instructor: 'Dr. Hasan',
        room: 'UB 704',
      );

      studentService.addExam(
        courseId: cse.id,
        courseCode: cse.code,
        title: 'Midterm Examination',
        examDate: DateTime.now().add(const Duration(days: 4)),
        room: 'Hall 2',
        seatNumber: 'Seat 12',
      );

      studentService.addAssignment(
        courseId: cse.id,
        title: 'Parser Implementation',
        dueAt: DateTime.now().add(const Duration(days: 2)),
      );

      final deck = studentService.createDeck(title: 'OS Flashcards');
      studentService.addFlashcard(
        deckId: deck.id,
        front: 'What is a Semaphore?',
        back: 'A synchronization variable used to manage concurrent access to shared resources.',
      );
    });

    testWidgets('StudentScreen renders tabs, courses, exam countdown, and decks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StudentScreen(
            isBangla: false,
            studentService: studentService,
            entriesRepo: entriesRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Student Mode & Academics'), findsOneWidget);
      expect(find.text('TOTAL REGISTERED CREDITS'), findsOneWidget);
      expect(find.text('3.0 Credits'), findsOneWidget);
      expect(find.text('UPCOMING EXAM COUNTDOWN'), findsOneWidget);
      expect(find.text('EXAM TIMETABLE & SEAT PLANS'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
