import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daybook/core/enums/core_enums.dart';
import 'package:daybook/domain/challenges/wake_challenge.dart';
import 'package:daybook/domain/models/alarm_item.dart';
import 'package:daybook/domain/models/sleep_log.dart';
import 'package:daybook/domain/services/wake_quest_engine.dart';
import 'package:daybook/domain/services/sleep_service.dart';
import 'package:daybook/domain/services/alarm_health_service.dart';
import 'package:daybook/presentation/screens/wake_quest_screen.dart';
import 'package:daybook/presentation/screens/alarm_health_screen.dart';
import 'package:daybook/presentation/screens/sleep_tracker_screen.dart';

void main() {
  group('PART 4 — Wake Challenge Implementations', () {
    test('Math Challenge generates difficulty-tuned problems and verifies solutions', () {
      final easyChallenge = MathChallenge(difficulty: ChallengeDifficulty.easy);
      expect(easyChallenge.totalProblems, 2);

      // Verify current problem
      final current = easyChallenge.currentProblem;
      final wrongRes = easyChallenge.verify(current.answer + 99);
      expect(wrongRes.isSuccess, false);
      expect(wrongRes.errorMessageEnglish, contains('Incorrect'));

      final correctRes1 = easyChallenge.verify(current.answer);
      expect(correctRes1.isSuccess, true);
      expect(easyChallenge.currentProblemIndex, 1);

      // Solve second problem
      final current2 = easyChallenge.currentProblem;
      final correctRes2 = easyChallenge.verify(current2.answer);
      expect(correctRes2.isSuccess, true);
      expect(easyChallenge.isCompleted, true);
    });

    test('Simon 3x3 Memory Sequence verifies correct pattern and triggers replay on error', () {
      final simon = MemorySequenceChallenge(
        difficulty: ChallengeDifficulty.easy,
        pregeneratedSequence: [0, 4, 8, 2],
      );

      // Step 1: correct
      final step1 = simon.verify(0);
      expect(step1.isSuccess, true);
      expect(simon.userSequence, [0]);

      // Step 2: error!
      final step2Wrong = simon.verify(7);
      expect(step2Wrong.isSuccess, false);
      expect(step2Wrong.requiresReplay, true);
      expect(simon.userSequence.isEmpty, true); // Reset on error

      // Retap entire correct sequence: 0, 4, 8, 2
      simon.verify(0);
      simon.verify(4);
      simon.verify(8);
      simon.verify(2);
      expect(simon.isCompleted, true);
    });

    test('Movement Challenge accumulates steps and supports accelerometer peaks', () {
      final move = MovementChallenge(customTargetSteps: 10);

      // Normal steps
      move.verify(4);
      expect(move.currentSteps, 4);

      // Accelerometer peak (e.g. 13.5 m/s^2 shake)
      move.verify(14.2);
      expect(move.currentSteps, 5);

      // Accelerometer low noise (ignored)
      move.verify(9.8);
      expect(move.currentSteps, 5);

      // Reach target
      move.verify(5);
      expect(move.isCompleted, true);
    });

    test('QR Scan Challenge verifies against SHA-256 target hash', () {
      const secret = 'DAYBOOK_BATHROOM_MIRROR_KEY';
      final expectedHash = QrScanChallenge.hashValue(secret);

      final qrChallenge = QrScanChallenge(expectedHash: expectedHash);

      final failRes = qrChallenge.verify('WRONG_CODE');
      expect(failRes.isSuccess, false);

      final passRes = qrChallenge.verify(secret);
      expect(passRes.isSuccess, true);
      expect(qrChallenge.isCompleted, true);
    });

    test('On-Device AI Vision requires high confidence and anti-spoofing camera motion', () {
      final aiChallenge = AiVisionChallenge(
        targetLabel: 'coffee mug',
        requiredConsecutiveFrames: 2,
        confidenceThreshold: 0.75,
      );

      // Frame 1: Match but no motion yet
      aiChallenge.verify(
        const AiVisionFrameResult(label: 'ceramic coffee mug', confidence: 0.85, cameraGyroDelta: 0.01),
      );
      expect(aiChallenge.isCompleted, false);

      // Frame 2: Match with required gyro motion
      aiChallenge.verify(
        const AiVisionFrameResult(label: 'coffee mug', confidence: 0.90, cameraGyroDelta: 0.06),
      );
      expect(aiChallenge.isCompleted, true);
    });

    test('Typing, Voice and Intention Line Challenges', () {
      final typing = TypingChallenge(customPhrase: 'Rise and shine');
      expect(typing.verify('Rise and shine').isSuccess, true);
      expect(typing.isCompleted, true);

      final voice = VoicePhraseChallenge(customPhrase: 'I am awake');
      expect(voice.verify('I am awake now').isSuccess, true);
      expect(voice.isCompleted, true);

      final intention = IntentionLineChallenge();
      expect(intention.verify('Deploy MVP Parts').isSuccess, true);
      expect(intention.capturedIntention, 'Deploy MVP Parts');
      expect(intention.isCompleted, true);
    });
  });

  group('PART 4 — WakeQuestEngine & Safety Escape Hatch', () {
    test('Challenge Chaining transitions from Math to Movement to Dismissal', () {
      const alarm = AlarmItem(
        id: 'alm_chain_test',
        hour: 7,
        minute: 0,
        challengeChain: [AlarmChallengeType.math, AlarmChallengeType.movement],
      );

      final math = MathChallenge(pregenerated: const [MathProblem(question: '2+2', answer: 4)]);
      final move = MovementChallenge(customTargetSteps: 2);

      final engine = WakeQuestEngine(
        alarm: alarm,
        customChain: [math, move],
      );

      expect(engine.currentChallengeIndex, 0);
      expect(engine.isAlarmRinging, true);

      // Pass first challenge (Math)
      engine.submitChallengeInput(4);
      expect(engine.currentChallengeIndex, 1);
      expect(engine.isAlarmRinging, true);

      // Pass second challenge (Movement)
      engine.submitChallengeInput(2);
      expect(engine.isChainComplete, true);
      expect(engine.isAlarmRinging, false);
      expect(engine.dismissedTime, isNotNull);
    });

    test('Safety Escape Hatch unlocks after 5 failed attempts or 15 minutes', () {
      const alarm = AlarmItem(id: 'alm_escape_test', hour: 6, minute: 30);
      final math = MathChallenge(pregenerated: const [MathProblem(question: '10+10', answer: 20)]);

      final startTime = DateTime(2026, 10, 15, 6, 30);
      final engine = WakeQuestEngine(
        alarm: alarm,
        simulatedStartTime: startTime,
        customChain: [math],
      );

      expect(engine.isEscapeHatchUnlocked(startTime), false);
      expect(engine.emergencySafeDismiss(startTime), false);

      // Fail 4 times: still locked
      for (int i = 0; i < 4; i++) {
        engine.submitChallengeInput(99);
      }
      expect(engine.isEscapeHatchUnlocked(startTime), false);

      // 5th failure unlocks escape hatch!
      engine.submitChallengeInput(99);
      expect(engine.failedAttempts, 5);
      expect(engine.isEscapeHatchUnlocked(startTime), true);

      // Emergency dismiss succeeds!
      final dismissed = engine.emergencySafeDismiss(startTime.add(const Duration(minutes: 2)));
      expect(dismissed, true);
      expect(engine.isAlarmRinging, false);
      expect(engine.escapeHatchUsed, true);

      final history = engine.toHistoryEvent();
      expect(history.escapeHatchUsed, true);
    });

    test('Sunrise glow factor ramps over 60 seconds from 0.0 to 1.0', () {
      const alarm = AlarmItem(id: 'alm_glow_test', hour: 6, minute: 0);
      final start = DateTime(2026, 10, 15, 6, 0, 0);
      final engine = WakeQuestEngine(alarm: alarm, simulatedStartTime: start);

      expect(engine.getSunriseGlowFactor(start), 0.0);
      expect(engine.getSunriseGlowFactor(start.add(const Duration(seconds: 30))), closeTo(0.5, 0.01));
      expect(engine.getSunriseGlowFactor(start.add(const Duration(seconds: 60))), 1.0);
      expect(engine.getSunriseGlowFactor(start.add(const Duration(seconds: 120))), 1.0);
    });
  });

  group('PART 4 — Sleep Analytics & Wake Score', () {
    test('Sleep Service computes weekly debt and optimal wind-down alert', () {
      final baseDate = DateTime(2026, 10, 15);
      final sleepService = SleepService(
        initialLogs: [
          SleepLog(
            id: 's1',
            bedtime: baseDate.add(const Duration(hours: 0)), // midnight
            wakeTime: baseDate.add(const Duration(hours: 7)), // 7h (1h deficit)
            qualityRating: 4,
          ),
          SleepLog(
            id: 's2',
            bedtime: baseDate.subtract(const Duration(days: 1)),
            wakeTime: baseDate.subtract(const Duration(days: 1)).add(const Duration(hours: 6)), // 6h (2h deficit)
            qualityRating: 3,
          ),
        ],
      );

      // 1h deficit + 2h deficit = 3 hours = 180 minutes debt
      expect(sleepService.calculateWeeklySleepDebt(), 180);
      expect(sleepService.getAverageSleepDurationHours(), 6.5);

      // Wind-down calculation: alarm at 6:30 AM tomorrow -> 8h sleep needs 10:30 PM bedtime -> 30m wind-down lead = 10:00 PM
      final windDown = sleepService.calculateWindDownTime(
        alarmHour: 6,
        alarmMinute: 30,
        targetSleepHours: 8,
        windDownLeadMinutes: 30,
        referenceDate: DateTime(2026, 10, 15, 12, 0),
      );

      expect(windDown.hour, 22); // 10 PM
      expect(windDown.minute, 0);
    });

    test('WakeScoreCalculator scores promptness, penalizes snoozing and rewards morning momentum', () {
      // Ideal wake up: 45 seconds to dismiss, 0 snoozes, first action in 10 minutes
      final idealScore = SleepService.computeWakeScore(
        ringToDismissSeconds: 45,
        snoozeCount: 0,
        minutesToFirstAction: 10,
      );
      expect(idealScore.score, 100);

      // Poor wake up: 12 minutes to dismiss, 2 snoozes (-30 pts), escape hatch used (-30 pts)
      final poorScore = SleepService.computeWakeScore(
        ringToDismissSeconds: 720,
        snoozeCount: 2,
        escapeHatchUsed: true,
      );
      expect(poorScore.score, lessThan(40));
    });
  });

  group('PART 4 — Presentation Screens Smoke Tests', () {
    testWidgets('WakeQuestScreen renders header, live clock, and challenge submission', (tester) async {
      const alarm = AlarmItem(id: 'alm_ui_test', hour: 6, minute: 30, label: 'Hero Wake Quest');
      final math = MathChallenge(pregenerated: const [MathProblem(question: '12 + 15', answer: 27)]);
      final engine = WakeQuestEngine(alarm: alarm, customChain: [math]);

      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: WakeQuestScreen(
            alarm: alarm,
            customEngine: engine,
            onDismissed: () => dismissed = true,
          ),
        ),
      );

      expect(find.text('Hero Wake Quest'), findsOneWidget);
      expect(find.text('12 + 15 = ?'), findsOneWidget);
      expect(find.text('Submit Calculation'), findsOneWidget);

      // Submit correct answer
      await tester.enterText(find.byType(TextField), '27');
      await tester.tap(find.text('Submit Calculation'));
      await tester.pumpAndSettle();

      // Should transition to success view
      expect(find.text('Good Morning!'), findsOneWidget);
      expect(find.text('Proceed to Day Page'), findsOneWidget);

      await tester.tap(find.text('Proceed to Day Page'));
      expect(dismissed, true);
    });

    testWidgets('AlarmHealthScreen renders diagnostic checks and OEM autostart tabs', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.daybook.daybook/alarm_engine'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'canScheduleExactAlarms') return true;
          if (methodCall.method == 'isBatteryOptimizationIgnored') return true;
          return null;
        },
      );

      final healthService = AlarmHealthService();
      final report = await healthService.runDiagnosticSelfTest();

      await tester.pumpWidget(
        MaterialApp(
          home: AlarmHealthScreen(
            healthService: healthService,
            initialReport: report,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Alarm Health & Diagnostics'), findsOneWidget);
      expect(find.text('Exact Alarm Scheduling Permission'), findsOneWidget);
      expect(find.text('Battery Optimization Exemption'), findsOneWidget);
      expect(find.text('Xiaomi / POCO'), findsOneWidget);
      expect(find.text('Samsung'), findsOneWidget);
    });

    testWidgets('SleepTrackerScreen renders metrics, wind-down card, and logs', (tester) async {
      final sleepService = SleepService();

      await tester.pumpWidget(
        MaterialApp(
          home: SleepTrackerScreen(
            sleepService: sleepService,
            nextAlarmHour: 7,
            nextAlarmMinute: 0,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Sleep Analytics & Wind-down'), findsOneWidget);
      expect(find.text('Tonight\'s Bedtime Wind-down'), findsOneWidget);
      expect(find.text('Average Sleep'), findsOneWidget);
      expect(find.text('Sleep Debt'), findsOneWidget);
      expect(find.text('Wake Score'), findsOneWidget);
    });
  });
}
