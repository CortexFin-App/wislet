import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/screens/auth/widgets/pin_indicator.dart';
import 'package:sage_wallet_reborn/screens/auth/widgets/pin_pad.dart';
import 'package:sage_wallet_reborn/services/auth_service.dart';

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
        return 'РЎС‚РІРѕСЂС–С‚СЊ РЅРѕРІРёР№ PIN-РєРѕРґ';
      case _PinSetupStage.confirm:
        return 'РџС–РґС‚РІРµСЂРґСЊС‚Рµ PIN-РєРѕРґ';
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
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage =
              'PIN-РєРѕРґРё РЅРµ Р·Р±С–РіР°СЋС‚СЊСЃСЏ. РЎРїСЂРѕР±СѓР№С‚Рµ С‰Рµ СЂР°Р·.';
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
          content: Text('PIN-РєРѕРґ СѓСЃРїС–С€РЅРѕ РІСЃС‚Р°РЅРѕРІР»РµРЅРѕ!'),
        ),
      );
      navigator.pop(true);
    } on Exception catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('РџРѕРјРёР»РєР° Р·Р±РµСЂРµР¶РµРЅРЅСЏ PIN-РєРѕРґСѓ: $e'),
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
        title: const Text('Р’СЃС‚Р°РЅРѕРІР»РµРЅРЅСЏ PIN-РєРѕРґСѓ'),
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
