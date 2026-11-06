import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app_repository.dart';
import '../../domain/models/task_item.dart';
import '../../domain/models/alarm_item.dart';
import '../../domain/models/habit_item.dart';
import '../../domain/models/money_transaction.dart';
import '../../domain/models/dhar_record.dart';
import '../../domain/models/person_item.dart';
import '../../domain/models/journal_entry.dart';
import '../../domain/models/chat_and_memory.dart';
import '../../domain/models/daily_plan_block.dart';
import '../../domain/models/student_models.dart';

class LocalStorageService {
  static const String _stateFileName = 'daybook_state_v1.json';

  /// Resolves the storage directory safely for all platforms and test runners.
  static Future<Directory> _getStorageDirectory() async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      try {
        final temp = await getTemporaryDirectory();
        return temp;
      } catch (_) {
        return Directory.current;
      }
    }
  }

  /// Saves the complete AppRepository state to local disk.
  static Future<bool> saveAppState(AppRepository repo) async {
    try {
      final dir = await _getStorageDirectory();
      final file = File('${dir.path}/$_stateFileName');

      final stateMap = {
        'version': 1,
        'savedAt': DateTime.now().toIso8601String(),
        'settings': {
          'isBangla': repo.isBangla,
          'themeMode': repo.themeMode.index,
          'wakeHour': repo.wakeHour,
          'wakeMinute': repo.wakeMinute,
          'sleepHour': repo.sleepHour,
          'sleepMinute': repo.sleepMinute,
          'selectedCity': repo.selectedCity,
        },
        'tasks': repo.taskService.tasks.map((t) => t.toJson()).toList(),
        'alarms': repo.alarms.map((a) => a.toJson()).toList(),
        'planBlocks': repo.planBlocks.map((b) => b.toJson()).toList(),
        'chatMessages': repo.chatMessages.map((m) => m.toJson()).toList(),
        'memories': repo.memoryVaultService.memories.map((m) => m.toJson()).toList(),
        'habits': repo.habitService.habits.map((h) => h.toJson()).toList(),
        'transactions': repo.moneyService.transactions.map((t) => t.toJson()).toList(),
        'dharRecords': repo.dharService.allRecords.map((r) => r.toJson()).toList(),
        'people': repo.peopleService.allPeople.map((p) => p.toJson()).toList(),
        'entries': repo.entriesRepository.entries.map((e) => e.toJson()).toList(),
        'courses': repo.studentService.allCourses.map((c) => c.toJson()).toList(),
        'exams': repo.studentService.allExams.map((e) => e.toJson()).toList(),
        'assignments': repo.studentService.allAssignments.map((a) => a.toJson()).toList(),
      };

      final jsonStr = jsonEncode(stateMap);
      await file.writeAsString(jsonStr, flush: true);
      return true;
    } catch (e) {
      debugPrint('[LocalStorageService] Error saving state: $e');
      return false;
    }
  }

  /// Loads and restores the complete AppRepository state from local disk.
  /// Returns true if existing state was loaded, false if no prior state existed.
  static Future<bool> loadAppState(AppRepository repo) async {
    try {
      final dir = await _getStorageDirectory();
      final file = File('${dir.path}/$_stateFileName');
      if (!await file.exists()) {
        return false;
      }

      final jsonStr = await file.readAsString();
      if (jsonStr.trim().isEmpty) return false;

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // 1. Settings
      if (data['settings'] is Map<String, dynamic>) {
        final s = data['settings'] as Map<String, dynamic>;
        repo.isBangla = s['isBangla'] as bool? ?? repo.isBangla;
        repo.wakeHour = s['wakeHour'] as int? ?? repo.wakeHour;
        repo.wakeMinute = s['wakeMinute'] as int? ?? repo.wakeMinute;
        repo.sleepHour = s['sleepHour'] as int? ?? repo.sleepHour;
        repo.sleepMinute = s['sleepMinute'] as int? ?? repo.sleepMinute;
        repo.selectedCity = s['selectedCity'] as String? ?? repo.selectedCity;
      }

      // 2. Tasks
      if (data['tasks'] is List) {
        final tasksList = (data['tasks'] as List)
            .map((item) => TaskItem.fromJson(item as Map<String, dynamic>))
            .toList();
        repo.taskService.loadTasks(tasksList);
      }

      // 3. Alarms
      if (data['alarms'] is List) {
        repo.alarms = (data['alarms'] as List)
            .map((item) => AlarmItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // 4. Plan Blocks
      if (data['planBlocks'] is List) {
        repo.planBlocks = (data['planBlocks'] as List)
            .map((item) => DailyPlanBlock.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // 5. Chat Messages
      if (data['chatMessages'] is List) {
        repo.chatMessages = (data['chatMessages'] as List)
            .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // 6. Memories
      if (data['memories'] is List) {
        final memList = (data['memories'] as List)
            .map((item) => PersonalMemory.fromJson(item as Map<String, dynamic>))
            .toList();
        repo.memoryVaultService.loadMemories(memList);
      }

      // 7. Habits
      if (data['habits'] is List) {
        for (final item in (data['habits'] as List)) {
          repo.habitService.saveHabit(HabitItem.fromJson(item as Map<String, dynamic>));
        }
      }

      // 8. Transactions
      if (data['transactions'] is List) {
        for (final item in (data['transactions'] as List)) {
          final tx = MoneyTransaction.fromJson(item as Map<String, dynamic>);
          repo.moneyService.recordTransaction(
            amountPaisa: tx.amountPaisa,
            type: tx.type,
            category: tx.category,
            account: tx.account,
            notes: tx.notes,
            date: tx.date,
            linkedPersonId: tx.linkedPersonId,
          );
        }
      }

      // 9. Dhar Records
      if (data['dharRecords'] is List) {
        for (final item in (data['dharRecords'] as List)) {
          final r = DharRecord.fromJson(item as Map<String, dynamic>);
          repo.dharService.restoreRecord(r);
        }
      }

      // 10. People
      if (data['people'] is List) {
        for (final item in (data['people'] as List)) {
          final p = PersonItem.fromJson(item as Map<String, dynamic>);
          repo.peopleService.restorePerson(p);
        }
      }

      // 11. Journal Entries
      if (data['entries'] is List) {
        for (final item in (data['entries'] as List)) {
          repo.entriesRepository.insertEntry(JournalEntry.fromJson(item as Map<String, dynamic>));
        }
      }

      // 12. Student
      if (data['courses'] is List) {
        for (final item in (data['courses'] as List)) {
          repo.studentService.restoreCourse(CourseItem.fromJson(item as Map<String, dynamic>));
        }
      }
      if (data['exams'] is List) {
        for (final item in (data['exams'] as List)) {
          repo.studentService.restoreExam(ExamItem.fromJson(item as Map<String, dynamic>));
        }
      }
      if (data['assignments'] is List) {
        for (final item in (data['assignments'] as List)) {
          repo.studentService.restoreAssignment(AssignmentItem.fromJson(item as Map<String, dynamic>));
        }
      }

      repo.notifyDataChanged();
      return true;
    } catch (e) {
      debugPrint('[LocalStorageService] Error loading state: $e');
      return false;
    }
  }

  /// Exports text content to a shared file via Android/system Share Sheet.
  static Future<void> shareTextFile({
    required String fileName,
    required String content,
    String mimeType = 'text/plain',
  }) async {
    try {
      final dir = await _getStorageDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(content, flush: true);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType, name: fileName)],
        subject: fileName,
      );
    } catch (_) {
      // Fallback to clipboard
      await Clipboard.setData(ClipboardData(text: content));
    }
  }

  /// Exports binary bytes (such as PDF) to a shared file via Android/system Share Sheet.
  static Future<void> shareBinaryFile({
    required String fileName,
    required Uint8List bytes,
    String mimeType = 'application/pdf',
  }) async {
    try {
      final dir = await _getStorageDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType, name: fileName)],
        subject: fileName,
      );
    } catch (e) {
      debugPrint('[LocalStorageService] Share binary error: $e');
    }
  }
}
