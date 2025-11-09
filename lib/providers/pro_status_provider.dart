import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wislet/core/constants/app_constants.dart';

class ProStatusProvider with ChangeNotifier {
  ProStatusProvider() {
    loadProStatus();
  }

  bool _isPro = false;
  bool get isPro => _isPro;

  Future<void> loadProStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool(AppConstants.prefsKeyIsProUser) ?? false;
    notifyListeners();
  }

  Future<void> setProStatus({required bool isPro}) async {
    _isPro = isPro;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefsKeyIsProUser, isPro);
    notifyListeners();
  }
}
