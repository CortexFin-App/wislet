import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

enum AppMode { local, online }

class AppModeProvider with ChangeNotifier {
  AppMode _mode = AppMode.local;

  AppMode get mode => _mode;
  bool get isOnline => _mode == AppMode.online;

  void update(AuthService authService) {
    final newMode = authService.currentUser != null ? AppMode.online : AppMode.local;
    if (_mode != newMode) {
      _mode = newMode;
      // Важливо! Сповіщуємо слухачів у наступному кадрі, щоб уникнути помилок під час білду.
      Future.microtask(() => notifyListeners());
    }
  }
}