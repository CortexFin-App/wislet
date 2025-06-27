import 'package:sage_wallet_reborn/models/category.dart';
import 'package:sage_wallet_reborn/services/api_client.dart';
import 'package:sage_wallet_reborn/data/repositories/category_repository.dart';

class ApiCategoryRepositoryImpl implements CategoryRepository {
  final ApiClient _apiClient;

  ApiCategoryRepositoryImpl(this._apiClient);

  @override
  Future<List<Category>> getAllCategories(int walletId) async {
    final responseData = await _apiClient.get('/categories',
        queryParams: {'walletId': walletId.toString()}) as List;
    return responseData.map((data) => Category.fromMap(data)).toList();
  }

  @override
  Future<List<Category>> getCategoriesByType(
      int walletId, CategoryType type) async {
    final responseData = await _apiClient.get('/categories', queryParams: {
      'walletId': walletId.toString(),
      'type': type.toString(),
    }) as List;
    return responseData.map((data) => Category.fromMap(data)).toList();
  }

  @override
  Future<int> createCategory(Category category, int walletId) async {
    final map = category.toMap();
    map['wallet_id'] = walletId;
    final responseData = await _apiClient.post(
      '/categories',
      body: map,
    );
    return responseData['id'] as int;
  }

  @override
  Future<Category> createCategoryFromMap(
      Map<String, dynamic> categoryMap, int walletId) async {
    final map = categoryMap;
    map['wallet_id'] = walletId;
    final responseData = await _apiClient.post(
      '/categories',
      body: map,
    );
    return Category.fromMap(responseData);
  }

  @override
  Future<int> updateCategory(Category category) async {
    final responseData =
        await _apiClient.put('/categories/${category.id}', body: category.toMap());
    return responseData['id'] as int;
  }

  @override
  Future<int> deleteCategory(int id) async {
    await _apiClient.delete('/categories/$id');
    return id;
  }

  @override
  Future<String> getCategoryNameById(int categoryId) async {
    try {
      final responseData = await _apiClient.get('/categories/$categoryId');
      return responseData['name'] as String? ?? 'Категорія не знайдена';
    } catch (e) {
      return 'Категорія не знайдена';
    }
  }
}