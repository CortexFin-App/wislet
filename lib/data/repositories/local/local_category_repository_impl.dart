import 'package:sage_wallet_reborn/models/category.dart';
import 'package:sage_wallet_reborn/utils/database_helper.dart';
import 'package:sage_wallet_reborn/data/repositories/category_repository.dart';

class LocalCategoryRepositoryImpl implements CategoryRepository {
  final DatabaseHelper _dbHelper;
  LocalCategoryRepositoryImpl(this._dbHelper);

  @override
  Future<int> createCategory(Category category, int walletId) async {
    final db = await _dbHelper.database;
    final map = category.toMap();
    map[DatabaseHelper.colCategoryWalletId] = walletId;
    return await db.insert(DatabaseHelper.tableCategories, map);
  }

  @override
  Future<Category> createCategoryFromMap(
      Map<String, dynamic> categoryMap, int walletId) async {
    final category = Category.fromMap(categoryMap);
    final newId = await createCategory(category, walletId);
    return Category(
      id: newId,
      name: category.name,
      type: category.type,
      bucket: category.bucket,
    );
  }

  @override
  Future<List<Category>> getAllCategories(int walletId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableCategories,
      where: '${DatabaseHelper.colCategoryWalletId} = ?',
      whereArgs: [walletId],
    );
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  @override
  Future<List<Category>> getCategoriesByType(
      int walletId, CategoryType type) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableCategories,
      where:
          '${DatabaseHelper.colCategoryWalletId} = ? AND ${DatabaseHelper.colCategoryType} = ?',
      whereArgs: [walletId, type.toString()],
    );
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  @override
  Future<int> updateCategory(Category category) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableCategories,
      category.toMap(),
      where: '${DatabaseHelper.colCategoryId} = ?',
      whereArgs: [category.id],
    );
  }

  @override
  Future<int> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableCategories,
      where: '${DatabaseHelper.colCategoryId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<String> getCategoryNameById(int categoryId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableCategories,
      columns: [DatabaseHelper.colCategoryName],
      where: '${DatabaseHelper.colCategoryId} = ?',
      whereArgs: [categoryId],
    );
    if (maps.isNotEmpty) {
      return maps.first[DatabaseHelper.colCategoryName] as String;
    }
    return 'Категорія не знайдена';
  }
}