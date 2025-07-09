import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/error/failures.dart';
import '../../../models/financial_goal.dart';
import '../../../services/error_monitoring_service.dart';
import '../goal_repository.dart';

class SupabaseGoalRepositoryImpl implements GoalRepository {
  final SupabaseClient _client;
  SupabaseGoalRepositoryImpl(this._client);

  @override
  Future<Either<AppFailure, List<FinancialGoal>>> getAllFinancialGoals(int walletId) async {
    try {
      final response = await _client.from('financial_goals').select().eq('wallet_id', walletId);
      final goals = (response as List).map((data) => FinancialGoal.fromMap(data)).toList();
      return Right(goals);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, FinancialGoal?>> getFinancialGoal(int id) async {
    try {
      final response = await _client.from('financial_goals').select().eq('id', id).maybeSingle();
      if (response == null) return const Right(null);
      return Right(FinancialGoal.fromMap(response));
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> createFinancialGoal(FinancialGoal goal, int walletId) async {
    try {
      final map = goal.toMap();
      map['wallet_id'] = walletId;
      map['user_id'] = _client.auth.currentUser!.id;
      final response = await _client.from('financial_goals').insert(map).select().single();
      return Right(response['id'] as int);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateFinancialGoal(FinancialGoal goal) async {
    try {
      final response = await _client.from('financial_goals').update(goal.toMap()).eq('id', goal.id!).select().single();
      return Right(response['id'] as int);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteFinancialGoal(int id) async {
    try {
      await _client.from('financial_goals').update({'is_deleted': true, 'updated_at': DateTime.now().toIso8601String()}).eq('id', id);
      return Right(id);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> updateFinancialGoalProgress(int goalId) async {
    try {
      await _client.rpc('update_goal_progress', params: {'p_goal_id': goalId});
      return const Right(null);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }
}