import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/day_page.dart';
import '../models/focus_session.dart';
import '../models/journal_entry.dart';
import '../../data/repositories/entries_repository.dart';

class FocusService extends ChangeNotifier {
  FocusState _state = FocusState.idle;
  int _targetSeconds = 25 * 60;
  int _secondsRemaining = 25 * 60;
  int _interruptions = 0;
  String? _currentTaskId;
  String _currentTaskTitle = 'General Deep Work';
  FocusSoundscape _soundscape = FocusSoundscape.silence;
  Timer? _timer;
  DateTime? _sessionStartedAt;

  // Flip-to-Focus settings
  bool isFlipToFocusEnabled = true;
  bool _isFaceDown = false;

  FocusState get state => _state;
  int get targetSeconds => _targetSeconds;
  int get secondsRemaining => _secondsRemaining;
  int get interruptions => _interruptions;
  String? get currentTaskId => _currentTaskId;
  String get currentTaskTitle => _currentTaskTitle;
  FocusSoundscape get soundscape => _soundscape;
  bool get isFaceDown => _isFaceDown;

  double get progressFraction {
    if (_targetSeconds == 0) return 0.0;
    return 1.0 - (_secondsRemaining / _targetSeconds);
  }

  String get timeFormatted {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void configureSession({
    String? taskId,
    String? taskTitle,
    int targetMinutes = 25,
    FocusSoundscape soundscape = FocusSoundscape.silence,
  }) {
    if (_state == FocusState.running) return;
    _currentTaskId = taskId;
    _currentTaskTitle = taskTitle ?? 'General Deep Work';
    _targetSeconds = targetMinutes * 60;
    _secondsRemaining = _targetSeconds;
    _soundscape = soundscape;
    _interruptions = 0;
    notifyListeners();
  }

  void setSoundscape(FocusSoundscape soundscape) {
    _soundscape = soundscape;
    notifyListeners();
  }

  void start() {
    if (_state == FocusState.running) return;
    _state = FocusState.running;
    _sessionStartedAt ??= DateTime.now();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        _timer?.cancel();
        _state = FocusState.completed;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void pause() {
    if (_state != FocusState.running) return;
    _timer?.cancel();
    _state = FocusState.paused;
    _interruptions++;
    notifyListeners();
  }

  void resume() {
    if (_state == FocusState.paused) {
      start();
    }
  }

  void reset() {
    _timer?.cancel();
    _state = FocusState.idle;
    _secondsRemaining = _targetSeconds;
    _interruptions = 0;
    _sessionStartedAt = null;
    notifyListeners();
  }

  /// Completes the session and writes it into the single event log.
  FocusSession completeSession({required EntriesRepository entriesRepo}) {
    _timer?.cancel();
    _state = FocusState.completed;

    final actualMins = (_targetSeconds - _secondsRemaining) ~/ 60;
    final dayKey = DayPageModel.formatDayKey(DateTime.now());

    final session = FocusSession(
      id: 'focus_${DateTime.now().microsecondsSinceEpoch}',
      taskId: _currentTaskId,
      taskTitle: _currentTaskTitle,
      targetMinutes: _targetSeconds ~/ 60,
      actualMinutes: actualMins > 0 ? actualMins : 1,
      interruptions: _interruptions,
      soundscape: _soundscape,
      wasCompleted: _secondsRemaining == 0,
      dayKey: dayKey,
      startedAt: _sessionStartedAt ?? DateTime.now(),
      endedAt: DateTime.now(),
    );

    entriesRepo.insertEntry(JournalEntry(
      id: 'entry_focus_${session.id}',
      type: EntryType.focusSession,
      ts: DateTime.now(),
      payload: {
        'sessionId': session.id,
        'taskId': session.taskId,
        'taskTitle': session.taskTitle,
        'actualMinutes': session.actualMinutes,
        'interruptions': session.interruptions,
        'qualityScore': session.qualityScore,
      },
      dayKey: dayKey,
      source: 'focus_zone',
    ));

    notifyListeners();
    return session;
  }

  /// Evaluates accelerometer coordinates for the "Flip-to-Focus" feature.
  /// When z < -8.5 m/s² and |x| < 3.0 and |y| < 3.0, the phone is resting face down.
  bool evaluateAccelerometer({
    required double x,
    required double y,
    required double z,
  }) {
    if (!isFlipToFocusEnabled) return false;

    final faceDown = z < -8.5 && x.abs() < 3.0 && y.abs() < 3.0;
    if (faceDown != _isFaceDown) {
      _isFaceDown = faceDown;
      if (_isFaceDown && (_state == FocusState.idle || _state == FocusState.paused)) {
        // Flipping phone face down automatically begins/resumes deep focus
        start();
      } else if (!_isFaceDown && _state == FocusState.running) {
        // Picking up the phone pauses the timer and logs an interruption
        pause();
      }
      notifyListeners();
    }
    return _isFaceDown;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
