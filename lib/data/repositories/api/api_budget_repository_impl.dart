import 'package:sage_wallet_reborn/models/budget_models.dart';
import 'package:sage_wallet_reborn/models/transaction.dart' as FinTransactionModel;
import 'package:sage_wallet_reborn/services/api_client.dart';
import 'package:sage_wallet_reborn/data/repositories/budget_repository.dart';

class ApiBudgetRepositoryImpl implements BudgetRepository {
  final ApiClient _apiClient;

  ApiBudgetRepositoryImpl(this._apiClient);

  @override
  Future<List<Budget>> getAllBudgets(int walletId) async {
    final responseData = await _apiClient.get('/budgets', queryParams: {'walletId': walletId.toString()}) as List;
    return responseData.map((data) => Budget.fromMap(data)).toList();
  }

  @override
  Future<int> createBudget(Budget budget, int walletId) async {
    final map = budget.toMap();
    map['wallet_id'] = walletId;
    final responseData = await _apiClient.post('/budgets', body: map);
    return responseData['id'] as int;
  }

  @override
  Future<int> updateBudget(Budget budget) async {
    final responseData = await _apiClient.put('/budgets/${budget.id}', body: budget.toMap());
    return responseData['id'] as int;
  }

  @override
  Future<int> deleteBudget(int budgetId) async {
    await _apiClient.delete('/budgets/$budgetId');
    return budgetId;
  }

  @override
  Future<Budget?> getActiveBudgetForDate(int walletId, DateTime date) async {
    final responseData = await _apiClient.get(
      '/budgets/active',
      queryParams: {
        'walletId': walletId.toString(),
        'date': date.toIso8601String(),
      },
    );
    if (responseData == null) return null;
    return Budget.fromMap(responseData);
  }

  @override
  Future<int> createBudgetEnvelope(BudgetEnvelope envelope) async {
    final responseData = await _apiClient.post('/budgets/envelopes', body: envelope.toMap());
    return responseData['id'] as int;
  }

  @override
  Future<int> updateBudgetEnvelope(BudgetEnvelope envelope) async {
    final responseData = await _apiClient.put('/budgets/envelopes/${envelope.id}', body: envelope.toMap());
    return responseData['id'] as int;
  }

  @override
  Future<int> deleteBudgetEnvelope(int id) async {
    await _apiClient.delete('/budgets/envelopes/$id');
    return id;
  }

  @override
  Future<List<BudgetEnvelope>> getEnvelopesForBudget(int budgetId) async {
    final responseData = await _apiClient.get('/budgets/$budgetId/envelopes') as List;
    return responseData.map((data) => BudgetEnvelope.fromMap(data)).toList();
  }

  @override
  Future<BudgetEnvelope?> getEnvelopeForCategory(int budgetId, int categoryId) async {
    final responseData = await _apiClient.get(
      '/budgets/$budgetId/envelopes',
      queryParams: {'categoryId': categoryId.toString()},
    );
    if (responseData == null || (responseData as List).isEmpty) return null;
    return BudgetEnvelope.fromMap(responseData.first);
  }

  @override
  Future<void> checkAndNotifyEnvelopeLimits(FinTransactionModel.Transaction transaction, int walletId) async {
    return;
  }
}