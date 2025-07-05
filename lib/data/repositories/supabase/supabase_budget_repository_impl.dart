import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/budget_models.dart';
import '../../../models/transaction.dart' as fin_transaction;
import '../budget_repository.dart';

class SupabaseBudgetRepositoryImpl implements BudgetRepository {
  final SupabaseClient _client;
  SupabaseBudgetRepositoryImpl(this._client);

  @override
  Future<List<Budget>> getAllBudgets(int walletId) async {
    final response =
        await _client.from('budgets').select().eq('wallet_id', walletId);
    return (response as List).map((data) => Budget.fromMap(data)).toList();
  }

  @override
  Future<int> createBudget(Budget budget, int walletId) async {
    final map = budget.toMap();
    map['wallet_id'] = walletId;
    map['user_id'] = _client.auth.currentUser!.id;
    final response =
        await _client.from('budgets').insert(map).select().single();
    return response['id'] as int;
  }

  @override
  Future<int> updateBudget(Budget budget) async {
    final response = await _client
        .from('budgets')
        .update(budget.toMap())
        .eq('id', budget.id!)
        .select()
        .single();
    return response['id'] as int;
  }

  @override
  Future<int> deleteBudget(int budgetId) async {
    await _client.from('budgets').delete().eq('id', budgetId);
    return budgetId;
  }

  @override
  Future<Budget?> getActiveBudgetForDate(int walletId, DateTime date) async {
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
    if (response == null) return null;
    return Budget.fromMap(response);
  }

  @override
  Future<int> createBudgetEnvelope(BudgetEnvelope envelope) async {
    final response = await _client
        .from('budget_envelopes')
        .insert(envelope.toMap())
        .select()
        .single();
    return response['id'] as int;
  }

  @override
  Future<int> updateBudgetEnvelope(BudgetEnvelope envelope) async {
    final response = await _client
        .from('budget_envelopes')
        .update(envelope.toMap())
        .eq('id', envelope.id!)
        .select()
        .single();
    return response['id'] as int;
  }

  @override
  Future<int> deleteBudgetEnvelope(int id) async {
    await _client.from('budget_envelopes').delete().eq('id', id);
    return id;
  }

  @override
  Future<List<BudgetEnvelope>> getEnvelopesForBudget(int budgetId) async {
    final response =
        await _client.from('budget_envelopes').select().eq('budget_id', budgetId);
    return (response as List)
        .map((data) => BudgetEnvelope.fromMap(data))
        .toList();
  }

  @override
  Future<BudgetEnvelope?> getEnvelopeForCategory(
      int budgetId, int categoryId) async {
    final response = await _client
        .from('budget_envelopes')
        .select()
        .eq('budget_id', budgetId)
        .eq('category_id', categoryId)
        .limit(1)
        .maybeSingle();
    if (response == null) return null;
    return BudgetEnvelope.fromMap(response);
  }

  @override
  Future<void> checkAndNotifyEnvelopeLimits(
      fin_transaction.Transaction transaction, int walletId) async {
    return;
  }
}