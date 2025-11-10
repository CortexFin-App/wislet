import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wislet/core/error/failures.dart';
import 'package:wislet/data/repositories/goal_repository.dart';
import 'package:wislet/models/financial_goal.dart';
import 'package:wislet/services/error_monitoring_service.dart';

class SupabaseGoalRepositoryImpl implements GoalRepository {
  SupabaseGoalRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<FinancialGoal>> watchAllFinancialGoals(int walletId) {
    return _client.from('financial_goals').stream(primaryKey: ['id']).map(
      (listOfMaps) => listOfMaps
          .where(
            (item) =>
                item['wallet_id'] == walletId && item['is_deleted'] == false,
          )
          .map(FinancialGoal.fromMap)
          .toList(),
    );
  }

  @override
  Future<Either<AppFailure, List<FinancialGoal>>> getAllFinancialGoals(
    int walletId,
  ) async {
    try {
      final response = await _client
          .from('financial_goals')
          .select()
          .eq('wallet_id', walletId)
          .eq('is_deleted', false);
      final goals = response.map(FinancialGoal.fromMap).toList();
      return Right(goals);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, FinancialGoal?>> getFinancialGoal(int id) async {
    try {
      final response = await _client
          .from('financial_goals')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return const Right(null);
      return Right(FinancialGoal.fromMap(response));
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> createFinancialGoal(
    FinancialGoal goal,
    int walletId,
  ) async {
    try {
      final map = goal.toMap();
      map['wallet_id'] = walletId;
      map['user_id'] = _client.auth.currentUser!.id;
      final response =
          await _client.from('financial_goals').insert(map).select().single();
      return Right(response['id'] as int);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateFinancialGoal(
    FinancialGoal goal,
  ) async {
    try {
      final response = await _client
          .from('financial_goals')
          .update(goal.toMap())
          .eq('id', goal.id!)
          .select()
          .single();
      return Right(response['id'] as int);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteFinancialGoal(int id) async {
    try {
      await _client.from('financial_goals').update({
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
  Future<Either<AppFailure, void>> updateFinancialGoalProgress(
    int goalId,
  ) async {
    try {
      await _client
          .rpc<void>('update_goal_progress', params: {'p_goal_id': goalId});
      return const Right(null);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }
}
