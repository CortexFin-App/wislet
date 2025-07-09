import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../../models/category.dart';

abstract class CategoryRepository {
  Future<Either<AppFailure, int>> createCategory(Category category, int walletId);
  Future<Either<AppFailure, List<Category>>> getAllCategories(int walletId);
  Future<Either<AppFailure, List<Category>>> getCategoriesByType(int walletId, CategoryType type);
  Future<Either<AppFailure, int>> updateCategory(Category category);
  Future<Either<AppFailure, int>> deleteCategory(int id);
  Future<Either<AppFailure, String>> getCategoryNameById(int categoryId);
  Future<Either<AppFailure, Category>> createCategoryFromMap(Map<String, dynamic> categoryMap, int walletId);
}