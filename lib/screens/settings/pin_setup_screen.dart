import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/screens/auth/widgets/pin_indicator.dart';
import 'package:wislet/screens/auth/widgets/pin_pad.dart';
import 'package:wislet/services/auth_service.dart';

enum _PinSetupStage { createNew, confirm }

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final AuthService _authService = getIt<AuthService>();

  _PinSetupStage _stage = _PinSetupStage.createNew;
  String _firstPinAttempt = '';
  String _currentPin = '';
  String? _errorMessage;
  bool _isSaving = false;

  String get _title {
    switch (_stage) {
      case _PinSetupStage.createNew:
        return 'Створіть новий PIN-код';
      case _PinSetupStage.confirm:
        return 'Підтвердьте PIN-код';
    }
  }

  void _onNumberPressed(String number) {
    if (_isSaving || _currentPin.length >= 4) return;
    setState(() {
      _currentPin += number;
      _errorMessage = null;
    });

    if (_currentPin.length == 4) {
      _handlePinEntered();
    }
  }

  void _onBackspacePressed() {
    if (_currentPin.isEmpty) return;
    setState(() {
      _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _handlePinEntered() async {
    if (_stage == _PinSetupStage.createNew) {
      setState(() {
        _firstPinAttempt = _currentPin;
        _currentPin = '';
        _stage = _PinSetupStage.confirm;
      });
    } else {
      if (_currentPin == _firstPinAttempt) {
        await _savePin();
      } else {
        await HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage =
              'PIN-коди не збігаються. Спробуйте ще раз.';
          _firstPinAttempt = '';
          _currentPin = '';
          _stage = _PinSetupStage.createNew;
        });
      }
    }
  }

  Future<void> _savePin() async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await _authService.setPin(_currentPin);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('PIN-код успішно встановлено!'),
        ),
      );
      navigator.pop(true);
    } on Exception catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Помилка збереження PIN-коду: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Встановлення PIN-коду'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            children: [
              Text(
                _title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              PinIndicator(pinLength: _currentPin.length),
              const SizedBox(height: 16),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 48,
                alignment: Alignment.center,
                child: _isSaving
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Text(
                        _errorMessage ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          height: 1.2,
                        ),
                      ),
              ),
              const Spacer(),
              SizedBox(
                width: 300,
                child: PinPadWidget(
                  onNumberPressed: _onNumberPressed,
                  onBackspacePressed: _onBackspacePressed,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
