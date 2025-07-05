import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

enum AppMode { local, online }

class AppModeProvider with ChangeNotifier {
  final AuthService _authService;
  AppMode _mode = AppMode.local;

  AppModeProvider(this._authService) {
    _updateMode();
    _authService.addListener(_updateMode);
  }

  void _updateMode() {
    final newMode = _authService.currentUser != null ? AppMode.online : AppMode.local;
    if (_mode != newMode) {
      _mode = newMode;
      notifyListeners();
    }
  }

  AppMode get mode => _mode;
  bool get isOnline => _mode == AppMode.online;

  @override
  void dispose() {
    _authService.removeListener(_updateMode);
    super.dispose();
  }
}