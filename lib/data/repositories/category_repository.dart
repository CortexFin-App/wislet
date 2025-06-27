import '../../models/category.dart';

abstract class CategoryRepository {
  Future<int> createCategory(Category category, int walletId);
  Future<List<Category>> getAllCategories(int walletId);
  Future<List<Category>> getCategoriesByType(int walletId, CategoryType type);
  Future<int> updateCategory(Category category);
  Future<int> deleteCategory(int id);
  Future<String> getCategoryNameById(int categoryId);
  // Додано новий абстрактний метод, який потрібно реалізувати
  Future<Category> createCategoryFromMap(
      Map<String, dynamic> categoryMap, int walletId);
}