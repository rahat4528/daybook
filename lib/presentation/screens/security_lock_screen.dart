import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../core/design/app_typography.dart';
import '../../core/security/biometric_lock_service.dart';

class SecurityLockScreen extends StatefulWidget {
  final BiometricLockService lockService;
  final VoidCallback onUnlocked;
  final bool isBangla;

  const SecurityLockScreen({
    super.key,
    required this.lockService,
    required this.onUnlocked,
    this.isBangla = false,
  });

  @override
  State<SecurityLockScreen> createState() => _SecurityLockScreenState();
}

class _SecurityLockScreenState extends State<SecurityLockScreen> {
  String _enteredPin = '';
  String _errorMessage = '';

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = '';
      });

      if (_enteredPin.length >= 4 && widget.lockService.hasPin) {
        final success = widget.lockService.unlockWithPin(_enteredPin);
        if (success) {
          widget.onUnlocked();
        } else if (_enteredPin.length == 6 || _enteredPin.length == 4) {
          setState(() {
            _errorMessage = widget.isBangla ? 'ভুল পিন কোড' : 'Incorrect PIN';
            _enteredPin = '';
          });
        }
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = '';
      });
    }
  }

  void _triggerBiometric() {
    widget.lockService.unlockWithBiometric();
    widget.onUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface1,
                      border: Border.all(color: AppColors.accentLime, width: 2),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: AppColors.accentLime,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isBangla ? 'দিনবই সুরক্ষিত' : 'DayBook Protected',
                    style: AppTypography.screenTitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isBangla ? 'আনলক করতে বায়োমেট্রিক বা পিন দিন' : 'Enter PIN or Biometrics to unlock',
                    style: AppTypography.caption,
                  ),
                ],
              ),

              // PIN Indicators
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < _enteredPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? AppColors.accentLime : AppColors.surface2,
                          border: Border.all(
                            color: isFilled ? AppColors.accentLime : AppColors.border,
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: AppColors.errorRed, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),

              // Numeric Keypad
              Column(
                children: [
                  for (var row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: row.map((digit) => _keypadButton(digit)).toList(),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Biometrics button
                        IconButton(
                          iconSize: 32,
                          color: AppColors.accentLime,
                          icon: const Icon(Icons.fingerprint),
                          onPressed: _triggerBiometric,
                        ),
                        _keypadButton('0'),
                        // Backspace
                        IconButton(
                          iconSize: 28,
                          color: AppColors.textPrimary,
                          icon: const Icon(Icons.backspace_outlined),
                          onPressed: _onBackspace,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _keypadButton(String digit) {
    return InkWell(
      borderRadius: BorderRadius.circular(36),
      onTap: () => _onDigitPressed(digit),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface1,
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}
