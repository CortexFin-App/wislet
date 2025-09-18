import 'package:wislet/models/theme_profile.dart';

abstract class ThemeRepository {
  Future<void> saveTheme(ThemeProfile profile);

  Future<List<ThemeProfile>> getSavedThemes();

  Future<void> deleteTheme(String profileName);
}
