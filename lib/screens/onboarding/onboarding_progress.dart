import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingProgress {
  static const _kBasic = 'onboarding_basic_done_v1';
  static const _kInteractive = 'onboarding_interactive_done_v1';

  static Future<void> markBasicDone([BuildContext? context]) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kBasic, true);
    if (context != null && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  static Future<void> markInteractiveDone([BuildContext? context]) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kInteractive, true);
    if (context != null && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  static Future<bool> isBasicDone() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kBasic) ?? false;
  }

  static Future<bool> isInteractiveDone() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kInteractive) ?? false;
  }
}
