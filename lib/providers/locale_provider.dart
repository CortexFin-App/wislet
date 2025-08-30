// lib/providers/locale_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _prefsKey = 'app_locale_code';

  Locale _locale = const Locale('uk');

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null) {
      _locale = Locale(code);
    }
    notifyListeners();
  }

  Locale get locale => _locale;

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }

  List<Locale> get supportedLocales => const [
        Locale('uk'),
        Locale('en'),
      ];

  String currentLanguageName() {
    switch (_locale.languageCode) {
      case 'uk':
        return 'Українська';
      case 'en':
        return 'English';
      default:
        return _locale.languageCode;
    }
  }
}
