import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/di/injector.dart';
import '../../services/auth_service.dart';
import 'widgets/pin_indicator.dart';
import 'widgets/pin_pad.dart';

class PinEntryScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback? onForgotPin;

  const PinEntryScreen({
    super.key,
    required this.onSuccess,
    this.onForgotPin,
  });

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final AuthService _authService = getIt<AuthService>();
  String _pin = '';
  String? _errorMessage;
  bool _isLoading = false;
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricsAndAuthenticate();
  }

  Future<void> _checkBiometricsAndAuthenticate() async {
    final canUse = await _authService.canUseBiometrics();
    if (mounted) {
      setState(() {
        _canUseBiometrics = canUse;
      });
      if (canUse) {
        _tryBiometrics();
      }
    }
  }

  Future<void> _tryBiometrics() async {
    final authenticated = await _authService.authenticateWithBiometrics();
    if (authenticated && mounted) {
      widget.onSuccess();
    }
  }

  void _onNumberPressed(String number) {
    if (_isLoading || _pin.length >= 4) return;
    setState(() {
      _pin += number;
      _errorMessage = null;
    });
    if (_pin.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspacePressed() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 200));

    final isCorrect = await _authService.verifyPin(_pin);

    if (!mounted) return;

    if (isCorrect) {
      widget.onSuccess();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'Невірний PIN-код';
        _pin = '';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
          child: Column(
            children: [
              Text(
                'Введіть PIN-код',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              PinIndicator(pinLength: _pin.length),
              const SizedBox(height: 16),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 24,
                child: _isLoading
                    ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2,)))
                    : Text(
                        _errorMessage ?? '',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
              ),
              const Spacer(),
              SizedBox(
                width: 300,
                child: PinPadWidget(
                  onNumberPressed: _onNumberPressed,
                  onBackspacePressed: _onBackspacePressed,
                  onBiometricPressed: _canUseBiometrics ? _tryBiometrics : null,
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