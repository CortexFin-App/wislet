import 'package:flutter/foundation.dart';
import 'package:wislet/services/auth_service.dart';

enum AppMode { local, online }

class AppModeProvider with ChangeNotifier {
  AppModeProvider(this._authService) {
    _updateMode();
    _authService.addListener(_updateMode);
  }

  final AuthService _authService;
  AppMode _mode = AppMode.local;

  AppMode get mode => _mode;
  bool get isOnline => _mode == AppMode.online;

  void _updateMode() {
    final newMode =
        _authService.currentUser != null ? AppMode.online : AppMode.local;
    if (_mode != newMode) {
      _mode = newMode;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authService.removeListener(_updateMode);
    super.dispose();
  }
}
