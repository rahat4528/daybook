import 'package:flutter/foundation.dart';
import 'security_vault.dart';

class BiometricLockService extends ChangeNotifier {
  bool _isBiometricEnabled = false;
  bool _isLocked = false;
  int _lockTimeoutSeconds = 60; // 1 minute default
  DateTime? _lastPausedAt;
  String? _hashedPin;

  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isLocked => _isLocked;
  int get lockTimeoutSeconds => _lockTimeoutSeconds;
  bool get hasPin => _hashedPin != null;

  void setBiometricEnabled(bool enabled) {
    _isBiometricEnabled = enabled;
    if (!enabled) {
      _isLocked = false;
    }
    notifyListeners();
  }

  void setLockTimeout(int seconds) {
    _lockTimeoutSeconds = seconds;
    notifyListeners();
  }

  void setPin(String pin) {
    if (pin.length < 4) {
      throw ArgumentError('PIN must be at least 4 digits.');
    }
    _hashedPin = SecurityVault.computeSHA256(pin);
    notifyListeners();
  }

  bool unlockWithPin(String pin) {
    if (_hashedPin == null) return false;
    final hash = SecurityVault.computeSHA256(pin);
    if (hash == _hashedPin) {
      _isLocked = false;
      _lastPausedAt = null;
      notifyListeners();
      return true;
    }
    return false;
  }

  void unlockWithBiometric() {
    _isLocked = false;
    _lastPausedAt = null;
    notifyListeners();
  }

  void recordAppPaused() {
    if (_isBiometricEnabled) {
      _lastPausedAt = DateTime.now();
    }
  }

  bool evaluateAppResumed() {
    if (!_isBiometricEnabled) return false;
    if (_lastPausedAt == null) return false;

    final elapsed = DateTime.now().difference(_lastPausedAt!).inSeconds;
    if (elapsed >= _lockTimeoutSeconds) {
      _isLocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void forceLock() {
    if (_isBiometricEnabled) {
      _isLocked = true;
      notifyListeners();
    }
  }
}
