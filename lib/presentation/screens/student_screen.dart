import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../core/design/app_typography.dart';
import '../../domain/models/student_models.dart';
import '../../domain/services/student_service.dart';
import '../../data/repositories/entries_repository.dart';

class StudentScreen extends StatefulWidget {
  final StudentService studentService;
  final EntriesRepository entriesRepo;
  final bool isBangla;

  const StudentScreen({
    super.key,
    required this.studentService,
    required this.entriesRepo,
    this.isBangla = false,
  });

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- MODALS ---

  void _showAddCourseModal() {
    final codeController = TextEditingController();
    final titleController = TextEditingController();
    final instructorController = TextEditingController();
    final roomController = TextEditingController();
    final creditsController = TextEditingController(text: '3.0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isBangla ? 'নতুন কোর্স যুক্ত করুন' : 'Add New Course',
              style: AppTypography.headingMedium.copyWith(color: AppColors.accentLime),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Course Code (e.g., CSE 411)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Course Title (e.g., Compiler Design)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: creditsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Credits',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: roomController,
                    decoration: const InputDecoration(
                      labelText: 'Room',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: instructorController,
              decoration: const InputDecoration(
                labelText: 'Instructor Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentLime,
                  foregroundColor: AppColors.bg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                ),
                onPressed: () {
                  final code = codeController.text.trim();
                  final title = titleController.text.trim();
                  final creds = double.tryParse(creditsController.text.trim()) ?? 3.0;
                  if (code.isNotEmpty && title.isNotEmpty) {
                    widget.studentService.addCourse(
                      code: code,
                      title: title,
                      creditHours: creds,
                      instructor: instructorController.text.trim(),
                      room: roomController.text.trim(),
                    );
                    Navigator.pop(ctx);
                    setState(() {});
                  }
                },
                child: Text(
                  widget.isBangla ? 'কোর্স সংরক্ষণ' : 'Save Course',
                  style: AppTypography.buttonText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExamModal() {
    final courses = widget.studentService.allCourses;
    if (courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one course first.')),
      );
      return;
    }

    String selectedCourseId = courses.first.id;
    final titleController = TextEditingController(text: 'Final Examination');
    final roomController = TextEditingController(text: 'Exam Hall 2');
    final seatController = TextEditingController(text: 'Row 3, Seat 14');
    final syllabusController = TextEditingController();
    DateTime examDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final course = courses.firstWhere((c) => c.id == selectedCourseId);
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isBangla ? 'পরীক্ষার তারিখ ও আসন যুক্ত করুন' : 'Schedule Exam',
                  style: AppTypography.headingMedium.copyWith(color: AppColors.accentLime),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCourseId,
                  dropdownColor: AppColors.surface1,
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Course'),
                  items: courses
                      .map((c) => DropdownMenuItem(value: c.id, child: Text('${c.code} - ${c.title}')))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedCourseId = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Exam Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: roomController,
                        decoration: const InputDecoration(labelText: 'Room', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: seatController,
                        decoration: const InputDecoration(labelText: 'Seat Number', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Exam Date', style: AppTypography.bodySmall),
                  subtitle: Text(
                    '${examDate.year}-${examDate.month.toString().padLeft(2, '0')}-${examDate.day.toString().padLeft(2, '0')}',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.accentLime),
                  ),
                  trailing: const Icon(Icons.calendar_today, color: AppColors.accentLime),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: examDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setModalState(() => examDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: syllabusController,
                  decoration: const InputDecoration(labelText: 'Syllabus / Chapters', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentLime,
                      foregroundColor: AppColors.bg,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                    ),
                    onPressed: () {
                      if (titleController.text.trim().isNotEmpty) {
                        widget.studentService.addExam(
                          courseId: course.id,
                          courseCode: course.code,
                          title: titleController.text.trim(),
                          examDate: examDate,
                          room: roomController.text.trim(),
                          seatNumber: seatController.text.trim(),
                          syllabus: syllabusController.text.trim(),
                          entriesRepo: widget.entriesRepo,
                        );
                        Navigator.pop(ctx);
                        setState(() {});
                      }
                    },
                    child: Text(
                      widget.isBangla ? 'পরীক্ষা সংরক্ষণ' : 'Save Exam',
                      style: AppTypography.buttonText,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddAssignmentModal() {
    final courses = widget.studentService.allCourses;
    if (courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one course first.')),
      );
      return;
    }

    String selectedCourseId = courses.first.id;
    final titleController = TextEditingController();
    final weightController = TextEditingController(text: '10.0');
    final notesController = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 3));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isBangla ? 'অ্যাসাইনমেন্ট যোগ করুন' : 'Add Assignment',
                  style: AppTypography.headingMedium.copyWith(color: AppColors.accentLime),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCourseId,
                  dropdownColor: AppColors.surface1,
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Course'),
                  items: courses
                      .map((c) => DropdownMenuItem(value: c.id, child: Text('${c.code} - ${c.title}')))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedCourseId = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Assignment Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Weight (%)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Deadline', style: AppTypography.caption),
                        subtitle: Text(
                          '${dueDate.month}/${dueDate.day}',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.accentLime),
                        ),
                        trailing: const Icon(Icons.event, color: AppColors.accentLime),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 120)),
                          );
                          if (picked != null) setModalState(() => dueDate = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Submission Instructions', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentLime,
                      foregroundColor: AppColors.bg,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                    ),
                    onPressed: () {
                      if (titleController.text.trim().isNotEmpty) {
                        widget.studentService.addAssignment(
                          courseId: selectedCourseId,
                          title: titleController.text.trim(),
                          dueAt: dueDate,
                          weightPercentage: double.tryParse(weightController.text.trim()) ?? 10.0,
                          notes: notesController.text.trim(),
                        );
                        Navigator.pop(ctx);
                        setState(() {});
                      }
                    },
                    child: Text(
                      widget.isBangla ? 'সংরক্ষণ করুন' : 'Save Assignment',
                      style: AppTypography.buttonText,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddDeckModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isBangla ? 'নতুন ডেক তৈরি করুন' : 'Create Flashcard Deck',
              style: AppTypography.headingMedium.copyWith(color: AppColors.accentLime),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Deck Title (e.g. Operating Systems Concepts)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentLime,
                  foregroundColor: AppColors.bg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                ),
                onPressed: () {
                  final title = titleController.text.trim();
                  if (title.isNotEmpty) {
                    widget.studentService.createDeck(
                      title: title,
                      description: descController.text.trim(),
                    );
                    Navigator.pop(ctx);
                    setState(() {});
                  }
                },
                child: Text(widget.isBangla ? 'ডেক তৈরি' : 'Create Deck', style: AppTypography.buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCardModal(String deckId) {
    final frontController = TextEditingController();
    final backController = TextEditingController();
    final hintController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isBangla ? 'ফ্ল্যাশকার্ড যুক্ত করুন' : 'Add Flashcard',
              style: AppTypography.headingMedium.copyWith(color: AppColors.accentLime),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: frontController,
              decoration: const InputDecoration(labelText: 'Front (Question / Prompt)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: backController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Back (Answer / Definition)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hintController,
              decoration: const InputDecoration(labelText: 'Hint / Context (Bangla or Phonetics)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentLime,
                  foregroundColor: AppColors.bg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                ),
                onPressed: () {
                  final front = frontController.text.trim();
                  final back = backController.text.trim();
                  if (front.isNotEmpty && back.isNotEmpty) {
                    widget.studentService.addFlashcard(
                      deckId: deckId,
                      front: front,
                      back: back,
                      hint: hintController.text.trim(),
                    );
                    Navigator.pop(ctx);
                    setState(() {});
                  }
                },
                child: Text(widget.isBangla ? 'কার্ড সংরক্ষণ' : 'Save Card', style: AppTypography.buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- FLASHCARD REVIEW SCREEN ---

  void _openReviewSession(FlashcardDeck deck) {
    final dueCards = widget.studentService.getDueCardsForDeck(deck.id);
    if (dueCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cards due for review right now! Great job.')),
      );
      return;
    }

    int currentCardIdx = 0;
    bool isFlipped = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setReviewState) {
          final card = dueCards[currentCardIdx];
          final progressText = '${currentCardIdx + 1} / ${dueCards.length}';

          return Dialog(
            backgroundColor: AppColors.surface1,
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(deck.title, style: AppTypography.headingSmall),
                      Text(progressText, style: AppTypography.tabularNumber.copyWith(color: AppColors.accentLime)),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 24),
                  GestureDetector(
                    onTap: () => setReviewState(() => isFlipped = !isFlipped),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: isFlipped ? AppColors.accentLime : AppColors.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isFlipped ? card.back : card.front,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 16,
                              fontWeight: isFlipped ? FontWeight.normal : FontWeight.bold,
                              color: isFlipped ? AppColors.accentLime : AppColors.textPrimary,
                            ),
                          ),
                          if (!isFlipped && card.hint.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              '💡 Hint: ${card.hint}',
                              textAlign: TextAlign.center,
                              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            isFlipped ? '(Tap to flip back)' : '(Tap to reveal answer)',
                            style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!isFlipped)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.accentLime),
                          foregroundColor: AppColors.accentLime,
                        ),
                        onPressed: () => setReviewState(() => isFlipped = true),
                        child: const Text('Show Answer'),
                      ),
                    )
                  else ...[
                    const Text('Rate Your Recall (SuperMemo SM-2)', style: AppTypography.caption),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ratingButton(
                          label: 'Blackout',
                          score: 1,
                          color: AppColors.errorRed,
                          onPressed: () => _handleRating(ctx, deck.id, card.id, 1, setReviewState, () {
                            if (currentCardIdx + 1 < dueCards.length) {
                              setReviewState(() {
                                currentCardIdx++;
                                isFlipped = false;
                              });
                            } else {
                              Navigator.pop(ctx);
                              setState(() {});
                            }
                          }),
                        ),
                        _ratingButton(
                          label: 'Hard',
                          score: 2,
                          color: const Color(0xFFF59E0B),
                          onPressed: () => _handleRating(ctx, deck.id, card.id, 2, setReviewState, () {
                            if (currentCardIdx + 1 < dueCards.length) {
                              setReviewState(() {
                                currentCardIdx++;
                                isFlipped = false;
                              });
                            } else {
                              Navigator.pop(ctx);
                              setState(() {});
                            }
                          }),
                        ),
                        _ratingButton(
                          label: 'Good',
                          score: 3,
                          color: AppColors.textPrimary,
                          onPressed: () => _handleRating(ctx, deck.id, card.id, 3, setReviewState, () {
                            if (currentCardIdx + 1 < dueCards.length) {
                              setReviewState(() {
                                currentCardIdx++;
                                isFlipped = false;
                              });
                            } else {
                              Navigator.pop(ctx);
                              setState(() {});
                            }
                          }),
                        ),
                        _ratingButton(
                          label: 'Mastered',
                          score: 5,
                          color: AppColors.accentLime,
                          onPressed: () => _handleRating(ctx, deck.id, card.id, 5, setReviewState, () {
                            if (currentCardIdx + 1 < dueCards.length) {
                              setReviewState(() {
                                currentCardIdx++;
                                isFlipped = false;
                              });
                            } else {
                              Navigator.pop(ctx);
                              setState(() {});
                            }
                          }),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _ratingButton({
    required String label,
    required int score,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          icon: Text('$score', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          onPressed: onPressed,
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: color, fontSize: 10)),
      ],
    );
  }

  void _handleRating(
    BuildContext ctx,
    String deckId,
    String cardId,
    int rating,
    StateSetter setReviewState,
    VoidCallback onNext,
  ) {
    widget.studentService.reviewCard(
      deckId: deckId,
      cardId: cardId,
      qualityRating: rating,
      entriesRepo: widget.entriesRepo,
    );
    onNext();
  }

  @override
  Widget build(BuildContext context) {
    final courses = widget.studentService.allCourses;
    final exams = widget.studentService.allExams;
    final urgentExams = widget.studentService.urgentExams;
    final assignments = widget.studentService.allAssignments;
    final decks = widget.studentService.allDecks;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        title: Text(
          widget.isBangla ? 'স্টুডেন্ট মোড ও পড়াশোনা' : 'Student Mode & Academics',
          style: AppTypography.screenTitle,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentLime,
          labelColor: AppColors.accentLime,
          unselectedLabelColor: AppColors.textSecondary,
          isScrollable: true,
          tabs: [
            Tab(text: widget.isBangla ? 'পরীক্ষা ও সারসংক্ষেপ' : 'Exams & Overview'),
            Tab(text: widget.isBangla ? 'কোর্সসমূহ' : 'Courses'),
            Tab(text: widget.isBangla ? 'অ্যাসাইনমেন্ট' : 'Assignments'),
            Tab(text: widget.isBangla ? 'ফ্ল্যাশকার্ড ডেক' : 'Flashcards (SM-2)'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentLime,
        foregroundColor: AppColors.bg,
        onPressed: () {
          final idx = _tabController.index;
          if (idx == 0) _showAddExamModal();
          if (idx == 1) _showAddCourseModal();
          if (idx == 2) _showAddAssignmentModal();
          if (idx == 3) _showAddDeckModal();
        },
        child: const Icon(Icons.add, size: 28),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Exams & Overview
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Academic Enrolled Credits Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isBangla ? 'মোট ক্রেডিট সম্পন্ন/নিবন্ধিত' : 'TOTAL REGISTERED CREDITS',
                          style: AppTypography.caption,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.studentService.totalEnrolledCredits.toStringAsFixed(1)} Credits',
                          style: AppTypography.keyMetricLime,
                        ),
                      ],
                    ),
                    Text(
                      '${courses.length} Courses Active',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Urgent Exam Alert Banner
              if (urgentExams.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    border: Border.all(color: AppColors.accentLime, width: 1.5),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: AppColors.accentLime, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isBangla ? 'আসন্ন জরুরি পরীক্ষা!' : 'UPCOMING EXAM COUNTDOWN',
                              style: AppTypography.caption.copyWith(color: AppColors.accentLime, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${urgentExams.first.courseCode}: ${urgentExams.first.title} in ${urgentExams.first.daysUntil(now)} days!',
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const Text('EXAM TIMETABLE & SEAT PLANS', style: AppTypography.sectionHeader),
              const SizedBox(height: 8),

              if (exams.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      widget.isBangla ? 'কোনো পরীক্ষা নির্ধারিত নেই।' : 'No exams scheduled yet.',
                      style: AppTypography.bodySecondary,
                    ),
                  ),
                )
              else
                ...exams.map((e) {
                  final days = e.daysUntil(now);
                  final isNear = days <= 7;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface1,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: isNear ? AppColors.accentLime : AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surface2,
                                borderRadius: BorderRadius.circular(AppRadius.chip),
                                border: Border.all(color: AppColors.accentLime),
                              ),
                              child: Text(
                                e.courseCode,
                                style: const TextStyle(color: AppColors.accentLime, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                            Text(
                              days >= 0 ? '$days days left' : 'Completed',
                              style: TextStyle(
                                color: isNear ? AppColors.accentLime : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(e.title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.room, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(e.room.isNotEmpty ? e.room : 'Venue TBA', style: AppTypography.caption),
                            const SizedBox(width: 14),
                            const Icon(Icons.event_seat, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(e.seatNumber.isNotEmpty ? e.seatNumber : 'Seat TBA', style: AppTypography.caption),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),

          // Tab 2: Courses
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (courses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      widget.isBangla ? 'কোনো কোর্স যুক্ত করা হয়নি।' : 'No courses registered yet. Tap + to add.',
                      style: AppTypography.bodySecondary,
                    ),
                  ),
                )
              else
                ...courses.map((c) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface1,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.surface2,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.accentLime),
                            ),
                            child: Center(
                              child: Text(
                                c.code.split(' ').first,
                                style: const TextStyle(color: AppColors.accentLime, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${c.code} • ${c.title}', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                  '${c.instructor} • ${c.creditHours} Credits • Room ${c.room}',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
            ],
          ),

          // Tab 3: Assignments
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (assignments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      widget.isBangla ? 'কোনো অ্যাসাইনমেন্ট বাকি নেই।' : 'No assignments listed.',
                      style: AppTypography.bodySecondary,
                    ),
                  ),
                )
              else
                ...assignments.map((a) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface1,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: a.isSubmitted ? AppColors.accentLime : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: a.isSubmitted,
                          activeColor: AppColors.accentLime,
                          checkColor: AppColors.bg,
                          onChanged: (_) {
                            widget.studentService.toggleAssignmentSubmitted(a.id, entriesRepo: widget.entriesRepo);
                            setState(() {});
                          },
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  decoration: a.isSubmitted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Weight: ${a.weightPercentage}% • Due: ${a.dueAt.month}/${a.dueAt.day}',
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),

          // Tab 4: Flashcards & SM-2
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (decks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      widget.isBangla ? 'কোনো ফ্ল্যাশকার্ড ডেক নেই।' : 'No flashcard decks yet. Tap + to create.',
                      style: AppTypography.bodySecondary,
                    ),
                  ),
                )
              else
                ...decks.map((deck) {
                  final dueCount = deck.dueCount(now);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface1,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: dueCount > 0 ? AppColors.accentLime : AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(deck.title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            if (dueCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.accentLime,
                                  borderRadius: BorderRadius.circular(AppRadius.chip),
                                ),
                                child: Text(
                                  '$dueCount Due',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              )
                            else
                              Text('${deck.cards.length} cards', style: AppTypography.caption),
                          ],
                        ),
                        if (deck.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(deck.description, style: AppTypography.caption),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentLime,
                                foregroundColor: AppColors.bg,
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.school, size: 16),
                              label: const Text('Review Deck'),
                              onPressed: () => _openReviewSession(deck),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.border),
                                foregroundColor: AppColors.textPrimary,
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Card'),
                              onPressed: () => _showAddCardModal(deck.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ],
      ),
    );
  }
}
