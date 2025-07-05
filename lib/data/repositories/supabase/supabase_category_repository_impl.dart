import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/category.dart';
import '../category_repository.dart';

class SupabaseCategoryRepositoryImpl implements CategoryRepository {
  final SupabaseClient _client;
  SupabaseCategoryRepositoryImpl(this._client);

  @override
  Future<List<Category>> getAllCategories(int walletId) async {
    final response = await _client.from('categories').select().eq('wallet_id', walletId);
    return (response as List).map((data) => Category.fromMap(data)).toList();
  }

  @override
  Future<List<Category>> getCategoriesByType(int walletId, CategoryType type) async {
    final response = await _client
        .from('categories')
        .select()
        .eq('wallet_id', walletId)
        .eq('type', type.name);
    return (response as List).map((data) => Category.fromMap(data)).toList();
  }

  @override
  Future<int> createCategory(Category category, int walletId) async {
    final map = category.toMap();
    map['wallet_id'] = walletId;
    map['user_id'] = _client.auth.currentUser!.id;
    final response = await _client.from('categories').insert(map).select().single();
    return response['id'] as int;
  }
  
  @override
  Future<Category> createCategoryFromMap(Map<String, dynamic> categoryMap, int walletId) async {
     final map = categoryMap;
    map['wallet_id'] = walletId;
    map['user_id'] = _client.auth.currentUser!.id;
    final response = await _client.from('categories').insert(map).select().single();
    return Category.fromMap(response);
  }

  @override
  Future<int> updateCategory(Category category) async {
    final response = await _client.from('categories').update(category.toMap()).eq('id', category.id!).select().single();
    return response['id'] as int;
  }

  @override
  Future<int> deleteCategory(int id) async {
    await _client.from('categories').delete().eq('id', id);
    return id;
  }

  @override
  Future<String> getCategoryNameById(int categoryId) async {
    final response = await _client.from('categories').select('name').eq('id', categoryId).maybeSingle();
    return response?['name'] as String? ?? 'Категорія не знайдена';
  }
}