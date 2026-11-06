class SM2Result {
  final int repetition;
  final int intervalDays;
  final double easinessFactor;
  final DateTime nextReviewDate;

  const SM2Result({
    required this.repetition,
    required this.intervalDays,
    required this.easinessFactor,
    required this.nextReviewDate,
  });
}

class CourseItem {
  final String id;
  final String code;
  final String title;
  final double creditHours;
  final String instructor;
  final String room;
  final String semester;
  final String colorHex;

  const CourseItem({
    required this.id,
    required this.code,
    required this.title,
    this.creditHours = 3.0,
    this.instructor = '',
    this.room = '',
    this.semester = 'Spring 2026',
    this.colorHex = '#B6FF00',
  });

  CourseItem copyWith({
    String? id,
    String? code,
    String? title,
    double? creditHours,
    String? instructor,
    String? room,
    String? semester,
    String? colorHex,
  }) {
    return CourseItem(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      creditHours: creditHours ?? this.creditHours,
      instructor: instructor ?? this.instructor,
      room: room ?? this.room,
      semester: semester ?? this.semester,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'title': title,
        'creditHours': creditHours,
        'instructor': instructor,
        'room': room,
        'semester': semester,
        'colorHex': colorHex,
      };

  factory CourseItem.fromJson(Map<String, dynamic> json) => CourseItem(
        id: json['id'] as String,
        code: json['code'] as String,
        title: json['title'] as String,
        creditHours: (json['creditHours'] as num?)?.toDouble() ?? 3.0,
        instructor: json['instructor'] as String? ?? '',
        room: json['room'] as String? ?? '',
        semester: json['semester'] as String? ?? 'Spring 2026',
        colorHex: json['colorHex'] as String? ?? '#B6FF00',
      );
}

class AssignmentItem {
  final String id;
  final String courseId;
  final String title;
  final DateTime dueAt;
  final double weightPercentage;
  final bool isSubmitted;
  final String notes;

  const AssignmentItem({
    required this.id,
    required this.courseId,
    required this.title,
    required this.dueAt,
    this.weightPercentage = 10.0,
    this.isSubmitted = false,
    this.notes = '',
  });

  bool isOverdue(DateTime now) => !isSubmitted && dueAt.isBefore(now);

  AssignmentItem copyWith({
    String? id,
    String? courseId,
    String? title,
    DateTime? dueAt,
    double? weightPercentage,
    bool? isSubmitted,
    String? notes,
  }) {
    return AssignmentItem(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      dueAt: dueAt ?? this.dueAt,
      weightPercentage: weightPercentage ?? this.weightPercentage,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'title': title,
        'dueAt': dueAt.toIso8601String(),
        'weightPercentage': weightPercentage,
        'isSubmitted': isSubmitted,
        'notes': notes,
      };

  factory AssignmentItem.fromJson(Map<String, dynamic> json) => AssignmentItem(
        id: json['id'] as String,
        courseId: json['courseId'] as String,
        title: json['title'] as String,
        dueAt: DateTime.parse(json['dueAt'] as String),
        weightPercentage: (json['weightPercentage'] as num?)?.toDouble() ?? 10.0,
        isSubmitted: json['isSubmitted'] as bool? ?? false,
        notes: json['notes'] as String? ?? '',
      );
}

class ExamItem {
  final String id;
  final String courseId;
  final String courseCode;
  final String title;
  final DateTime examDate;
  final int durationMinutes;
  final String room;
  final String seatNumber;
  final double weightPercentage;
  final String syllabus;

  const ExamItem({
    required this.id,
    required this.courseId,
    required this.courseCode,
    required this.title,
    required this.examDate,
    this.durationMinutes = 120,
    this.room = '',
    this.seatNumber = '',
    this.weightPercentage = 40.0,
    this.syllabus = '',
  });

  int daysUntil(DateTime now) {
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfExam = DateTime(examDate.year, examDate.month, examDate.day);
    return startOfExam.difference(startOfToday).inDays;
  }

  bool isUpcoming(DateTime now) => examDate.isAfter(now);
  bool isUrgent(DateTime now) => isUpcoming(now) && daysUntil(now) <= 7;

  ExamItem copyWith({
    String? id,
    String? courseId,
    String? courseCode,
    String? title,
    DateTime? examDate,
    int? durationMinutes,
    String? room,
    String? seatNumber,
    double? weightPercentage,
    String? syllabus,
  }) {
    return ExamItem(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      courseCode: courseCode ?? this.courseCode,
      title: title ?? this.title,
      examDate: examDate ?? this.examDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      room: room ?? this.room,
      seatNumber: seatNumber ?? this.seatNumber,
      weightPercentage: weightPercentage ?? this.weightPercentage,
      syllabus: syllabus ?? this.syllabus,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'courseCode': courseCode,
        'title': title,
        'examDate': examDate.toIso8601String(),
        'durationMinutes': durationMinutes,
        'room': room,
        'seatNumber': seatNumber,
        'weightPercentage': weightPercentage,
        'syllabus': syllabus,
      };

  factory ExamItem.fromJson(Map<String, dynamic> json) => ExamItem(
        id: json['id'] as String,
        courseId: json['courseId'] as String,
        courseCode: json['courseCode'] as String,
        title: json['title'] as String,
        examDate: DateTime.parse(json['examDate'] as String),
        durationMinutes: json['durationMinutes'] as int? ?? 120,
        room: json['room'] as String? ?? '',
        seatNumber: json['seatNumber'] as String? ?? '',
        weightPercentage: (json['weightPercentage'] as num?)?.toDouble() ?? 40.0,
        syllabus: json['syllabus'] as String? ?? '',
      );
}

class FlashcardItem {
  final String id;
  final String deckId;
  final String front;
  final String back;
  final String hint;
  final int repetition;
  final double easinessFactor;
  final int intervalDays;
  final DateTime nextReviewDate;
  final DateTime lastReviewedAt;

  const FlashcardItem({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    this.hint = '',
    this.repetition = 0,
    this.easinessFactor = 2.5,
    this.intervalDays = 1,
    required this.nextReviewDate,
    required this.lastReviewedAt,
  });

  bool isDue(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final reviewDate = DateTime(nextReviewDate.year, nextReviewDate.month, nextReviewDate.day);
    return !reviewDate.isAfter(today);
  }

  FlashcardItem copyWith({
    String? id,
    String? deckId,
    String? front,
    String? back,
    String? hint,
    int? repetition,
    double? easinessFactor,
    int? intervalDays,
    DateTime? nextReviewDate,
    DateTime? lastReviewedAt,
  }) {
    return FlashcardItem(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      hint: hint ?? this.hint,
      repetition: repetition ?? this.repetition,
      easinessFactor: easinessFactor ?? this.easinessFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'deckId': deckId,
        'front': front,
        'back': back,
        'hint': hint,
        'repetition': repetition,
        'easinessFactor': easinessFactor,
        'intervalDays': intervalDays,
        'nextReviewDate': nextReviewDate.toIso8601String(),
        'lastReviewedAt': lastReviewedAt.toIso8601String(),
      };

  factory FlashcardItem.fromJson(Map<String, dynamic> json) => FlashcardItem(
        id: json['id'] as String,
        deckId: json['deckId'] as String,
        front: json['front'] as String,
        back: json['back'] as String,
        hint: json['hint'] as String? ?? '',
        repetition: json['repetition'] as int? ?? 0,
        easinessFactor: (json['easinessFactor'] as num?)?.toDouble() ?? 2.5,
        intervalDays: json['intervalDays'] as int? ?? 1,
        nextReviewDate: DateTime.parse(json['nextReviewDate'] as String),
        lastReviewedAt: DateTime.parse(json['lastReviewedAt'] as String),
      );
}

class FlashcardDeck {
  final String id;
  final String title;
  final String? courseId;
  final String description;
  final List<FlashcardItem> cards;
  final DateTime createdAt;

  const FlashcardDeck({
    required this.id,
    required this.title,
    this.courseId,
    this.description = '',
    this.cards = const [],
    required this.createdAt,
  });

  int dueCount(DateTime now) => cards.where((c) => c.isDue(now)).length;

  FlashcardDeck copyWith({
    String? id,
    String? title,
    String? courseId,
    String? description,
    List<FlashcardItem>? cards,
    DateTime? createdAt,
  }) {
    return FlashcardDeck(
      id: id ?? this.id,
      title: title ?? this.title,
      courseId: courseId ?? this.courseId,
      description: description ?? this.description,
      cards: cards ?? this.cards,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'courseId': courseId,
        'description': description,
        'cards': cards.map((c) => c.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory FlashcardDeck.fromJson(Map<String, dynamic> json) => FlashcardDeck(
        id: json['id'] as String,
        title: json['title'] as String,
        courseId: json['courseId'] as String?,
        description: json['description'] as String? ?? '',
        cards: (json['cards'] as List? ?? [])
            .map((c) => FlashcardItem.fromJson(c as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
