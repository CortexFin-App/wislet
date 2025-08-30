import 'package:sage_wallet_reborn/data/repositories/theme_repository.dart';
import 'package:sage_wallet_reborn/models/theme_profile.dart';
import 'package:sage_wallet_reborn/utils/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class LocalThemeRepositoryImpl implements ThemeRepository {
  LocalThemeRepositoryImpl(this._dbHelper);

  final DatabaseHelper _dbHelper;

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
    final List<Map<String, dynamic>> maps =
        await db.query(DatabaseHelper.tableThemeProfiles);
    return maps.map(_fromMap).toList();
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
