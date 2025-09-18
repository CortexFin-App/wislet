import 'package:fpdart/fpdart.dart';
import 'package:wislet/core/error/failures.dart';
import 'package:wislet/data/repositories/budget_repository.dart';
import 'package:wislet/models/budget_models.dart';
import 'package:wislet/models/transaction.dart' as fin_transaction;
import 'package:wislet/services/error_monitoring_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBudgetRepositoryImpl implements BudgetRepository {
  SupabaseBudgetRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<Budget>> watchAllBudgets(int walletId) {
    return _client.from('budgets').stream(primaryKey: ['id']).map(
      (listOfMaps) {
        final budgets = listOfMaps
            .where(
              (item) =>
                  item['wallet_id'] == walletId && item['is_deleted'] == false,
            )
            .map(Budget.fromMap)
            .toList();
        budgets.sort((a, b) => b.startDate.compareTo(a.startDate));
        return budgets;
      },
    );
  }

  @override
  Future<Either<AppFailure, List<Budget>>> getAllBudgets(int walletId) async {
    try {
      final response = await _client
          .from('budgets')
          .select()
          .eq('wallet_id', walletId)
          .eq('is_deleted', false)
          .order('start_date', ascending: false);
      return Right(response.map(Budget.fromMap).toList());
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> createBudget(
    Budget budget,
    int walletId,
  ) async {
    try {
      final map = budget.toMap();
      map['wallet_id'] = walletId;
      map['user_id'] = _client.auth.currentUser!.id;
      final response =
          await _client.from('budgets').insert(map).select().single();
      return Right(response['id'] as int);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateBudget(Budget budget) async {
    try {
      final response = await _client
          .from('budgets')
          .update(budget.toMap())
          .eq('id', budget.id!)
          .select()
          .single();
      return Right(response['id'] as int);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteBudget(int budgetId) async {
    try {
      await _client
          .from('budgets')
          .update({'is_deleted': true}).eq('id', budgetId);
      return Right(budgetId);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, Budget?>> getActiveBudgetForDate(
    int walletId,
    DateTime date,
  ) async {
    try {
      final dateString = date.toIso8601String();
      final response = await _client
          .from('budgets')
          .select()
          .eq('wallet_id', walletId)
          .eq('is_active', true)
          .lte('start_date', dateString)
          .gte('end_date', dateString)
          .limit(1)
          .maybeSingle();
      if (response == null) return const Right(null);
      return Right(Budget.fromMap(response));
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> createBudgetEnvelope(
    BudgetEnvelope envelope,
  ) async {
    try {
      final response = await _client
          .from('budget_envelopes')
          .insert(envelope.toMap())
          .select()
          .single();
      return Right(response['id'] as int);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateBudgetEnvelope(
    BudgetEnvelope envelope,
  ) async {
    try {
      final response = await _client
          .from('budget_envelopes')
          .update(envelope.toMap())
          .eq('id', envelope.id!)
          .select()
          .single();
      return Right(response['id'] as int);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteBudgetEnvelope(int id) async {
    try {
      await _client.from('budget_envelopes').delete().eq('id', id);
      return Right(id);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<BudgetEnvelope>>> getEnvelopesForBudget(
    int budgetId,
  ) async {
    try {
      final response = await _client
          .from('budget_envelopes')
          .select()
          .eq('budget_id', budgetId);
      return Right(response.map(BudgetEnvelope.fromMap).toList());
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, BudgetEnvelope?>> getEnvelopeForCategory(
    int budgetId,
    int categoryId,
  ) async {
    try {
      final response = await _client
          .from('budget_envelopes')
          .select()
          .eq('budget_id', budgetId)
          .eq('category_id', categoryId)
          .limit(1)
          .maybeSingle();
      if (response == null) return const Right(null);
      return Right(BudgetEnvelope.fromMap(response));
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> checkAndNotifyEnvelopeLimits(
    fin_transaction.Transaction transaction,
    int walletId,
  ) async {
    return const Right(null);
  }
}
