import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/financial_goal.dart';
import '../goal_repository.dart';

class SupabaseGoalRepositoryImpl implements GoalRepository {
  final SupabaseClient _client;
  SupabaseGoalRepositoryImpl(this._client);

  @override
  Future<List<FinancialGoal>> getAllFinancialGoals(int walletId) async {
    final response = await _client.from('financial_goals').select().eq('wallet_id', walletId);
    return (response as List).map((data) => FinancialGoal.fromMap(data)).toList();
  }

  @override
  Future<FinancialGoal?> getFinancialGoal(int id) async {
    final response = await _client.from('financial_goals').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return FinancialGoal.fromMap(response);
  }

  @override
  Future<int> createFinancialGoal(FinancialGoal goal, int walletId) async {
    final map = goal.toMap();
    map['wallet_id'] = walletId;
    map['user_id'] = _client.auth.currentUser!.id;
    final response = await _client.from('financial_goals').insert(map).select().single();
    return response['id'] as int;
  }

  @override
  Future<int> updateFinancialGoal(FinancialGoal goal) async {
    final response = await _client.from('financial_goals').update(goal.toMap()).eq('id', goal.id!).select().single();
    return response['id'] as int;
  }

  @override
  Future<int> deleteFinancialGoal(int id) async {
    await _client.from('financial_goals').delete().eq('id', id);
    return id;
  }

  @override
  Future<void> updateFinancialGoalProgress(int goalId) async {
    await _client.rpc('update_goal_progress', params: {'p_goal_id': goalId});
  }
}