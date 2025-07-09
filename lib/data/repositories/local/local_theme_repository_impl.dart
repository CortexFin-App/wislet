import 'package:sqflite/sqflite.dart';
import '../../../models/theme_profile.dart';
import '../../../utils/database_helper.dart';
import '../theme_repository.dart';

class LocalThemeRepositoryImpl implements ThemeRepository {
  final DatabaseHelper _dbHelper;
  LocalThemeRepositoryImpl(this._dbHelper);

  Map<String, dynamic> _toMap(ThemeProfile profile) {
    return profile.toMap();
  }

  ThemeProfile _fromMap(Map<String, dynamic> map) {
    return ThemeProfile.fromMap(map);
  }

  @override
  Future<void> saveTheme(ThemeProfile profile) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tableThemeProfiles,
      _toMap(profile),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<ThemeProfile>> getSavedThemes() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(DatabaseHelper.tableThemeProfiles);
    return maps.map((map) => _fromMap(map)).toList();
  }

  @override
  Future<void> deleteTheme(String profileName) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableThemeProfiles,
      where: '${DatabaseHelper.colProfileName} = ?',
      whereArgs: [profileName],
    );
  }
}