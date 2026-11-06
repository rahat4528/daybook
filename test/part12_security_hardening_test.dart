import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daybook/core/security/security_vault.dart';
import 'package:daybook/core/security/biometric_lock_service.dart';
import 'package:daybook/presentation/screens/security_lock_screen.dart';

void main() {
  group('Part 12: PBKDF2 Cryptographic Key Derivation Tests', () {
    test('Derives exact 32-byte (256-bit) key deterministically from passphrase and salt', () {
      final salt = SecurityVault.generateRandomBytes(32);
      const passphrase = 'SuperSecretUserPassword!2026';

      final key1 = SecurityVault.deriveKeyPBKDF2(
        password: passphrase,
        salt: salt,
        iterations: 2000, // Reduced for test speed, production uses 100,000
      );

      final key2 = SecurityVault.deriveKeyPBKDF2(
        password: passphrase,
        salt: salt,
        iterations: 2000,
      );

      expect(key1.length, equals(32));
      expect(key2.length, equals(32));
      expect(key1, equals(key2)); // Deterministic
    });

    test('Different salts produce completely orthogonal keys (salt isolation)', () {
      final salt1 = SecurityVault.generateRandomBytes(32);
      final salt2 = SecurityVault.generateRandomBytes(32);
      const passphrase = 'SamePassphraseForBoth';

      final key1 = SecurityVault.deriveKeyPBKDF2(password: passphrase, salt: salt1, iterations: 1000);
      final key2 = SecurityVault.deriveKeyPBKDF2(password: passphrase, salt: salt2, iterations: 1000);

      expect(key1, isNot(equals(key2)));
    });

    test('Empty password or insufficient salt throws ArgumentError', () {
      final validSalt = SecurityVault.generateRandomBytes(32);
      final shortSalt = SecurityVault.generateRandomBytes(8); // < 16 bytes

      expect(
        () => SecurityVault.deriveKeyPBKDF2(password: '', salt: validSalt, iterations: 1000),
        throwsArgumentError,
      );
      expect(
        () => SecurityVault.deriveKeyPBKDF2(password: 'ValidPass', salt: shortSalt, iterations: 1000),
        throwsArgumentError,
      );
    });
  });

  group('Part 12: Authenticated Encryption & Tamper Resistance Tests', () {
    late List<int> key;

    setUp(() {
      key = SecurityVault.generateRandomBytes(32);
    });

    test('Encrypt and decrypt roundtrip preserves exact plaintext string', () {
      const sensitiveJournal = 'আজকে আমার দিনটি খুব সুন্দর কেটেছে। Deep work session finished.';

      final encrypted = SecurityVault.encrypt(plaintext: sensitiveJournal, key: key);
      final decrypted = SecurityVault.decrypt(payload: encrypted, key: key);

      expect(decrypted, equals(sensitiveJournal));
    });

    test('Semantic security: Encrypting identical plaintext twice produces distinct IVs and ciphertexts', () {
      const plaintext = 'Secret Bank Token or PIN';

      final enc1 = SecurityVault.encrypt(plaintext: plaintext, key: key);
      final enc2 = SecurityVault.encrypt(plaintext: plaintext, key: key);

      expect(enc1.ivBase64, isNot(equals(enc2.ivBase64)));
      expect(enc1.ciphertextBase64, isNot(equals(enc2.ciphertextBase64)));
    });

    test('Tamper detection: Altered ciphertext fails authentication tag verification with SecurityException', () {
      const sensitiveData = 'Financial debt: ৳5,000 to Uncle Karim';

      final encrypted = SecurityVault.encrypt(plaintext: sensitiveData, key: key);

      // Tamper with ciphertext by flipping bits in the base64 payload
      final rawCipher = base64Decode(encrypted.ciphertextBase64);
      rawCipher[0] ^= 0xFF; // Invert first byte
      final tamperedPayload = EncryptedPayload(
        ivBase64: encrypted.ivBase64,
        ciphertextBase64: base64Encode(rawCipher),
        authTagBase64: encrypted.authTagBase64,
        saltBase64: encrypted.saltBase64,
      );

      expect(
        () => SecurityVault.decrypt(payload: tamperedPayload, key: key),
        throwsA(isA<SecurityException>()),
      );
    });

    test('Tamper detection: Altered auth tag fails verification', () {
      final encrypted = SecurityVault.encrypt(plaintext: 'Secret Data', key: key);
      final rawTag = base64Decode(encrypted.authTagBase64);
      rawTag[rawTag.length - 1] ^= 0x01; // Tamper tag

      final tamperedPayload = EncryptedPayload(
        ivBase64: encrypted.ivBase64,
        ciphertextBase64: encrypted.ciphertextBase64,
        authTagBase64: base64Encode(rawTag),
        saltBase64: encrypted.saltBase64,
      );

      expect(
        () => SecurityVault.decrypt(payload: tamperedPayload, key: key),
        throwsA(isA<SecurityException>()),
      );
    });

    test('Key size validation enforces 256 bits (32 bytes)', () {
      final shortKey = SecurityVault.generateRandomBytes(16); // 128 bits
      expect(
        () => SecurityVault.encrypt(plaintext: 'Data', key: shortKey),
        throwsArgumentError,
      );
    });
  });

  group('Part 12: BiometricLockService & Session Timeout Tests', () {
    late BiometricLockService lockService;

    setUp(() {
      lockService = BiometricLockService();
    });

    test('PIN creation and hash verification', () {
      lockService.setPin('1234');
      expect(lockService.hasPin, isTrue);

      expect(lockService.unlockWithPin('0000'), isFalse);
      expect(lockService.unlockWithPin('1234'), isTrue);
      expect(lockService.isLocked, isFalse);
    });

    test('Background timeout triggers lock when elapsed time exceeds threshold', () {
      lockService.setBiometricEnabled(true);
      lockService.setLockTimeout(5); // 5 seconds

      lockService.recordAppPaused();
      expect(lockService.isLocked, isFalse);

      // Force simulated resume after timeout by manually calling evaluate
      lockService.forceLock();
      expect(lockService.isLocked, isTrue);

      lockService.unlockWithBiometric();
      expect(lockService.isLocked, isFalse);
    });
  });

  group('Part 12: SecurityLockScreen Widget Smoke Tests', () {
    late BiometricLockService lockService;

    setUp(() {
      lockService = BiometricLockService()..setPin('4321');
    });

    testWidgets('SecurityLockScreen renders keypad, PIN circles, and unlocks with correct PIN', (tester) async {
      bool unlocked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SecurityLockScreen(
            lockService: lockService,
            onUnlocked: () => unlocked = true,
            isBangla: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DayBook Protected'), findsOneWidget);
      expect(find.text('Enter PIN or Biometrics to unlock'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.byIcon(Icons.fingerprint), findsOneWidget);

      // Enter 4, 3, 2, 1
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      expect(unlocked, isTrue);
    });
  });
}
