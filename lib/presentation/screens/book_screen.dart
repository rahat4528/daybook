import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/design/app_tokens.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/repositories/entries_repository.dart';
import '../../domain/models/day_page.dart';
import '../../domain/models/time_capsule.dart';
import '../../domain/services/book_export_service.dart';
import '../../data/database/local_storage_service.dart';
import 'day_page_screen.dart';

class BookScreen extends StatefulWidget {
  final EntriesRepository repository;
  final bool isBangla;

  const BookScreen({
    super.key,
    required this.repository,
    this.isBangla = false,
  });

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  late DateTime _selectedMonth;
  late List<DayPageModel> _monthDays;
  late PageController _pageController;
  int _currentPageIndex = 0;
  bool _showOnlyBookmarks = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _currentPageIndex = (now.day - 1).clamp(0, 30);
    _pageController = PageController(initialPage: _currentPageIndex);
    _loadMonth();
  }

  void _loadMonth() {
    setState(() {
      _monthDays = widget.repository.getMonthDays(_selectedMonth.year, _selectedMonth.month);
      if (_currentPageIndex >= _monthDays.length) {
        _currentPageIndex = _monthDays.length - 1;
      }
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
      _currentPageIndex = 0;
      _loadMonth();
      _pageController.jumpToPage(0);
    });
  }

  void _exportDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTokens.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusCard)),
        side: BorderSide(color: AppTokens.border),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isBangla ? 'বই রপ্তানি করুন' : 'Export DayBook Volume',
                style: const TextStyle(
                  color: AppTokens.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: AppTokens.accentLime),
                title: Text(
                  widget.isBangla ? 'পিডিএফ (অরিজিনাল ডার্ক থিম)' : 'PDF Book (OLED Dark Mode)',
                  style: const TextStyle(color: AppTokens.textPrimary),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final bytes = await BookExportService.exportMonthToPdf(
                    _monthDays,
                    _selectedMonth.year,
                    _selectedMonth.month,
                    blackOnWhite: false,
                    isBangla: widget.isBangla,
                  );
                  await LocalStorageService.shareBinaryFile(
                    fileName: 'daybook_${_selectedMonth.year}_${_selectedMonth.month}_dark.pdf',
                    bytes: bytes,
                    mimeType: 'application/pdf',
                  );
                  _showExportSuccess('PDF (Dark) ready (${bytes.lengthInBytes} bytes) & shared');
                },
              ),
              ListTile(
                leading: const Icon(Icons.print_outlined, color: AppTokens.accentLime),
                title: Text(
                  widget.isBangla ? 'পিডিএফ (প্রিন্ট-বান্ধব সাদা-কালো)' : 'PDF Book (Print-Friendly Black-on-White)',
                  style: const TextStyle(color: AppTokens.textPrimary),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final bytes = await BookExportService.exportMonthToPdf(
                    _monthDays,
                    _selectedMonth.year,
                    _selectedMonth.month,
                    blackOnWhite: true,
                    isBangla: widget.isBangla,
                  );
                  await LocalStorageService.shareBinaryFile(
                    fileName: 'daybook_${_selectedMonth.year}_${_selectedMonth.month}_print.pdf',
                    bytes: bytes,
                    mimeType: 'application/pdf',
                  );
                  _showExportSuccess('PDF (Print-Friendly) ready (${bytes.lengthInBytes} bytes) & shared');
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_snippet_outlined, color: AppTokens.textSecondary),
                title: Text(
                  widget.isBangla ? 'মার্কডাউন (.md)' : 'Markdown Export (.md)',
                  style: const TextStyle(color: AppTokens.textPrimary),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final md = BookExportService.exportMonthToMarkdown(
                    _monthDays,
                    _selectedMonth.year,
                    _selectedMonth.month,
                    isBangla: widget.isBangla,
                  );
                  await LocalStorageService.shareTextFile(
                    fileName: 'daybook_${_selectedMonth.year}_${_selectedMonth.month}.md',
                    content: md,
                    mimeType: 'text/markdown',
                  );
                  _showExportSuccess('Markdown export generated (${md.length} characters) & shared');
                },
              ),
              ListTile(
                leading: const Icon(Icons.data_object, color: AppTokens.textSecondary),
                title: Text(
                  widget.isBangla ? 'স্ট্রাকচার্ড জেএসওএন (.json)' : 'Structured JSON Backup (.json)',
                  style: const TextStyle(color: AppTokens.textPrimary),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final json = BookExportService.exportMonthToJson(
                    _monthDays,
                    _selectedMonth.year,
                    _selectedMonth.month,
                  );
                  await LocalStorageService.shareTextFile(
                    fileName: 'daybook_${_selectedMonth.year}_${_selectedMonth.month}.json',
                    content: json,
                    mimeType: 'application/json',
                  );
                  _showExportSuccess('JSON volume created (${json.length} characters) & shared');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExportSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTokens.surface2,
        content: Text(message, style: const TextStyle(color: AppTokens.accentLime)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCreateTimeCapsuleDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    DateTime unlockDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTokens.surface2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                side: const BorderSide(color: AppTokens.border),
              ),
              title: Text(
                widget.isBangla ? 'নতুন টাইম ক্যাপসুল তৈরি করুন' : 'Seal a Time Capsule',
                style: const TextStyle(color: AppTokens.textPrimary, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: AppTokens.textPrimary),
                      decoration: InputDecoration(
                        hintText: widget.isBangla ? 'ক্যাপসুলের নাম...' : 'Capsule Title...',
                        hintStyle: const TextStyle(color: AppTokens.textSecondary),
                        filled: true,
                        fillColor: AppTokens.surface1,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentCtrl,
                      maxLines: 3,
                      style: const TextStyle(color: AppTokens.textPrimary),
                      decoration: InputDecoration(
                        hintText: widget.isBangla ? 'ভবিষ্যতের জন্য গোপন বার্তা...' : 'Message for the future...',
                        hintStyle: const TextStyle(color: AppTokens.textSecondary),
                        filled: true,
                        fillColor: AppTokens.surface1,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.isBangla ? 'খোলার তারিখ:' : 'Unlock Date:',
                          style: const TextStyle(color: AppTokens.textSecondary, fontSize: 13),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: unlockDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 3650)),
                            );
                            if (picked != null) {
                              setDialogState(() => unlockDate = picked);
                            }
                          },
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(unlockDate),
                            style: const TextStyle(color: AppTokens.accentLime, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(widget.isBangla ? 'বাতিল' : 'Cancel', style: const TextStyle(color: AppTokens.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTokens.accentLime, foregroundColor: Colors.black),
                  onPressed: () {
                    if (titleCtrl.text.isNotEmpty && contentCtrl.text.isNotEmpty) {
                      widget.repository.addTimeCapsule(
                        TimeCapsuleItem(
                          id: 'capsule_${DateTime.now().millisecondsSinceEpoch}',
                          title: titleCtrl.text.trim(),
                          content: contentCtrl.text.trim(),
                          createdAt: DateTime.now(),
                          unlockAt: unlockDate,
                        ),
                      );
                      Navigator.pop(ctx);
                      setState(() {});
                      _showExportSuccess(widget.isBangla ? 'টাইম ক্যাপসুল সিল করা হয়েছে' : 'Time capsule sealed.');
                    }
                  },
                  child: Text(widget.isBangla ? 'সিল করুন' : 'Seal Capsule', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale(isBangla: widget.isBangla);
    final monthLabel = DateFormat('MMMM yyyy').format(_selectedMonth);
    final onThisDayList = widget.repository.getOnThisDay(DateTime.now());
    final capsules = widget.repository.getTimeCapsules();

    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(
        backgroundColor: AppTokens.bg,
        elevation: 0,
        title: Text(
          locale.theBook,
          style: const TextStyle(
            color: AppTokens.accentLime,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showOnlyBookmarks ? Icons.bookmark : Icons.bookmark_border,
              color: _showOnlyBookmarks ? AppTokens.accentLime : AppTokens.textSecondary,
            ),
            tooltip: 'Bookmarks',
            onPressed: () => setState(() => _showOnlyBookmarks = !_showOnlyBookmarks),
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined, color: AppTokens.textPrimary),
            tooltip: locale.exportBook,
            onPressed: _exportDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Shelf Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTokens.surface1,
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                border: Border.all(color: AppTokens.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: AppTokens.textPrimary),
                    onPressed: () => _changeMonth(-1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Text(
                    monthLabel.toUpperCase(),
                    style: const TextStyle(
                      color: AppTokens.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.0,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: AppTokens.textPrimary),
                    onPressed: () => _changeMonth(1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // "On This Day" Throwback Card
            if (onThisDayList.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTokens.surface1,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  border: Border.all(color: AppTokens.accentLime.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history, color: AppTokens.accentLime, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          locale.onThisDay,
                          style: const TextStyle(
                            color: AppTokens.accentLime,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...onThisDayList.map((throwback) {
                      final throwDate = DateFormat('yyyy-MM-dd').format(throwback.date);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '[$throwDate] ${throwback.title ?? throwback.entries.firstOrNull?.displayText(isBangla: widget.isBangla) ?? "Journal Entry"}',
                          style: const TextStyle(color: AppTokens.textPrimary, fontSize: 13),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Calendar Heatmap View
            Text(
              locale.heatCalendar,
              style: const TextStyle(
                color: AppTokens.accentLime,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTokens.surface1,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppTokens.border),
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 1.0,
                ),
                itemCount: _monthDays.length,
                itemBuilder: (ctx, index) {
                  final day = _monthDays[index];
                  final isSelected = index == _currentPageIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _currentPageIndex = index);
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTokens.accentLime.withValues(alpha: day.heatOpacity),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${day.date.day}',
                          style: TextStyle(
                            color: day.scoreTier >= 3 ? Colors.black : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Page-Turn Swiper between Day Pages
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isBangla ? 'পৃষ্ঠা ব্রাউজ করুন (বই মোড)' : 'PAGE-TURN BOOK MODE',
                  style: const TextStyle(
                    color: AppTokens.accentLime,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '${_currentPageIndex + 1} / ${_monthDays.length}',
                  style: const TextStyle(color: AppTokens.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 240,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _monthDays.length,
                onPageChanged: (idx) => setState(() => _currentPageIndex = idx),
                itemBuilder: (ctx, idx) {
                  final page = _monthDays[idx];
                  final formattedDate = DateFormat('EEEE, MMM d').format(page.date);
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DayPageScreen(
                            repository: widget.repository,
                            initialDate: page.date,
                            isBangla: widget.isBangla,
                          ),
                        ),
                      ).then((_) => _loadMonth());
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTokens.surface2,
                        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                        border: Border.all(color: AppTokens.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  color: AppTokens.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  if (page.isStarred)
                                    const Icon(Icons.star, color: AppTokens.accentLime, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Score: ${page.computeDayScore()}',
                                    style: const TextStyle(color: AppTokens.accentLime, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (page.title != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              page.title!,
                              style: const TextStyle(color: AppTokens.textSecondary, fontSize: 13),
                            ),
                          ],
                          const Divider(color: AppTokens.border, height: 24),
                          Expanded(
                            child: page.entries.isEmpty
                                ? Center(
                                    child: Text(
                                      widget.isBangla ? 'কোনো এন্ট্রি নেই (ট্যাপ করে খুলুন)' : 'Empty day (tap to open)',
                                      style: const TextStyle(color: AppTokens.textSecondary, fontSize: 12),
                                    ),
                                  )
                                : ListView.builder(
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: page.entries.take(3).length,
                                    itemBuilder: (_, i) {
                                      final e = page.entries[i];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Text(
                                          '${e.timeFormatted} • ${e.displayText(isBangla: widget.isBangla)}',
                                          style: const TextStyle(color: AppTokens.textPrimary, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              widget.isBangla ? 'সম্পূর্ণ পৃষ্ঠা খুলুন →' : 'Open Full Day Page →',
                              style: const TextStyle(color: AppTokens.accentLime, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            // Time Capsules Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  locale.timeCapsule,
                  style: const TextStyle(
                    color: AppTokens.accentLime,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                TextButton(
                  onPressed: _showCreateTimeCapsuleDialog,
                  child: Text(
                    widget.isBangla ? '+ নতুন ক্যাপসুল' : '+ New Capsule',
                    style: const TextStyle(color: AppTokens.accentLime, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (capsules.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTokens.surface1,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  border: Border.all(color: AppTokens.border),
                ),
                child: Center(
                  child: Text(
                    widget.isBangla
                        ? 'ভবিষ্যতের জন্য বার্তা সংরক্ষণ করতে টাইম ক্যাপসুল তৈরি করুন।'
                        : 'No sealed time capsules yet. Create one for future reflections.',
                    style: const TextStyle(color: AppTokens.textSecondary, fontSize: 12),
                  ),
                ),
              )
            else
              ...capsules.map((c) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTokens.surface1,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.isUnlocked ? AppTokens.accentLime : AppTokens.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.title,
                            style: const TextStyle(color: AppTokens.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            c.isUnlocked
                                ? (widget.isBangla ? 'উন্মুক্ত!' : 'Unlocked!')
                                : (widget.isBangla ? '${c.daysRemaining} দিন বাকি' : '${c.daysRemaining} days remaining'),
                            style: TextStyle(
                              color: c.isUnlocked ? AppTokens.accentLime : AppTokens.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        c.isUnlocked ? Icons.lock_open : Icons.lock_outline,
                        color: c.isUnlocked ? AppTokens.accentLime : AppTokens.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}
