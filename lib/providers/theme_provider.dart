import 'package:flutter/material.dart';
import 'package:wislet/core/constants/app_constants.dart';
import 'package:wislet/data/repositories/theme_repository.dart';
import 'package:wislet/data/static/default_theme_profiles.dart';
import 'package:wislet/models/theme_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeProvider(this._themeRepository) {
    _loadThemeSettings();
  }

  final ThemeRepository _themeRepository;

  List<ThemeProfile> _customProfiles = [];
  late List<ThemeProfile> allProfiles;
  ThemeProfile _currentProfile = defaultThemeProfiles.first;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProfile get currentProfile => _currentProfile;
  ThemeMode get themeMode => _themeMode;
  Color get currentSeedColor => _currentProfile.seedColor;

  Future<void> _loadThemeSettings() async {
    _customProfiles = await _themeRepository.getSavedThemes();
    _updateAllProfilesList();

    final prefs = await SharedPreferences.getInstance();
    final profileName = prefs.getString(AppConstants.prefsKeyThemeProfileName);
    _currentProfile = allProfiles.firstWhere(
      (p) => p.name == profileName,
      orElse: () => defaultThemeProfiles.first,
    );

    final themeModeIndex =
        prefs.getInt(AppConstants.prefsKeyThemeMode) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeModeIndex];

    notifyListeners();
  }

  void _updateAllProfilesList() {
    allProfiles = [...defaultThemeProfiles, ..._customProfiles];
  }

  Future<void> setThemeProfile(ThemeProfile profile) async {
    if (_currentProfile.name == profile.name) return;
    _currentProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefsKeyThemeProfileName, profile.name);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefsKeyThemeMode, mode.index);
    notifyListeners();
  }

  Future<void> saveCustomTheme(ThemeProfile profile) async {
    await _themeRepository.saveTheme(profile);
    await _loadThemeSettings();
    await setThemeProfile(profile);
  }

  Future<void> deleteCustomTheme(ThemeProfile profile) async {
    if (defaultThemeProfiles.any((p) => p.name == profile.name)) return;
    await _themeRepository.deleteTheme(profile.name);
    await _loadThemeSettings();
  }
}
