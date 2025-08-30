import 'package:fpdart/fpdart.dart';
import 'package:sage_wallet_reborn/core/error/failures.dart';
import 'package:sage_wallet_reborn/data/repositories/category_repository.dart';
import 'package:sage_wallet_reborn/models/category.dart';
import 'package:sage_wallet_reborn/services/error_monitoring_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCategoryRepositoryImpl implements CategoryRepository {
  SupabaseCategoryRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<void> addDefaultCategories(int walletId) async {
    return;
  }

  @override
  Future<Either<AppFailure, List<Category>>> getAllCategories(
    int walletId,
  ) async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('wallet_id', walletId)
          .eq('is_deleted', false);
      final categories = response.map(Category.fromMap).toList();
      return Right(categories);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<Category>>> getCategoriesByType(
    int walletId,
    CategoryType type,
  ) async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('wallet_id', walletId)
          .eq('type', type.name)
          .eq('is_deleted', false);
      final categories = response.map(Category.fromMap).toList();
      return Right(categories);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> createCategory(
    Category category,
    int walletId,
  ) async {
    try {
      final map = category.toMap();
      map['wallet_id'] = walletId;
      map['user_id'] = _client.auth.currentUser!.id;
      final response =
          await _client.from('categories').insert(map).select().single();
      return Right(response['id'] as int);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateCategory(Category category) async {
    try {
      final response = await _client
          .from('categories')
          .update(category.toMap())
          .eq('id', category.id!)
          .select()
          .single();
      return Right(response['id'] as int);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteCategory(int id) async {
    try {
      await _client.from('categories').update({
        'is_deleted': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      return Right(id);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, String>> getCategoryNameById(int categoryId) async {
    try {
      final response = await _client
          .from('categories')
          .select('name')
          .eq('id', categoryId)
          .maybeSingle();
      return Right(response?['name'] as String? ?? 'Категорія не знайдена');
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, Category>> createCategoryFromMap(
    Map<String, dynamic> categoryMap,
    int walletId,
  ) async {
    try {
      final map = Map<String, dynamic>.from(categoryMap);
      map['wallet_id'] = walletId;
      map['user_id'] = _client.auth.currentUser!.id;
      final response =
          await _client.from('categories').insert(map).select().single();
      return Right(Category.fromMap(response));
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }
}
