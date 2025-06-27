import 'package:sage_wallet_reborn/models/financial_goal.dart';
import 'package:sage_wallet_reborn/services/api_client.dart';
import 'package:sage_wallet_reborn/data/repositories/goal_repository.dart';

class ApiGoalRepositoryImpl implements GoalRepository {
  final ApiClient _apiClient;

  ApiGoalRepositoryImpl(this._apiClient);

  @override
  Future<List<FinancialGoal>> getAllFinancialGoals(int walletId) async {
    final responseData = await _apiClient.get('/goals', queryParams: {'walletId': walletId.toString()}) as List;
    return responseData.map((data) => FinancialGoal.fromMap(data)).toList();
  }

  @override
  Future<int> createFinancialGoal(FinancialGoal goal, int walletId) async {
    final map = goal.toMap();
    map['wallet_id'] = walletId;
    final responseData = await _apiClient.post('/goals', body: map);
    return responseData['id'] as int;
  }

  @override
  Future<FinancialGoal?> getFinancialGoal(int id) async {
    final responseData = await _apiClient.get('/goals/$id');
    if (responseData == null) return null;
    return FinancialGoal.fromMap(responseData);
  }

  @override
  Future<int> updateFinancialGoal(FinancialGoal goal) async {
    final responseData = await _apiClient.put('/goals/${goal.id}', body: goal.toMap());
    return responseData['id'] as int;
  }

  @override
  Future<int> deleteFinancialGoal(int id) async {
    await _apiClient.delete('/goals/$id');
    return id;
  }

  @override
  Future<void> updateFinancialGoalProgress(int goalId) async {
    await _apiClient.post('/goals/$goalId/update-progress', body: {});
  }
}