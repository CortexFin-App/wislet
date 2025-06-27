import 'package:flutter/foundation.dart';

enum AppMode { local, online }

class AppModeProvider with ChangeNotifier {
  AppMode _mode = AppMode.local;

  AppMode get mode => _mode;
  bool get isOnline => _mode == AppMode.online;

  void switchToOnlineMode() {
    if (_mode != AppMode.online) {
      _mode = AppMode.online;
      notifyListeners();
    }
  }

  void switchToLocalMode() {
    if (_mode != AppMode.local) {
      _mode = AppMode.local;
      notifyListeners();
    }
  }
}