import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/debt_loan_model.dart';
import '../debt_loan_repository.dart';

class SupabaseDebtLoanRepositoryImpl implements DebtLoanRepository {
  final SupabaseClient _client;
  SupabaseDebtLoanRepositoryImpl(this._client);

  @override
  Future<List<DebtLoan>> getAllDebtLoans(int walletId) async {
    final response = await _client
        .from('debts_loans')
        .select()
        .eq('wallet_id', walletId)
        .order('creation_date', ascending: false);
    return (response as List).map((data) => DebtLoan.fromMap(data)).toList();
  }

  @override
  Future<DebtLoan?> getDebtLoan(int id) async {
    final response =
        await _client.from('debts_loans').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return DebtLoan.fromMap(response);
  }

  @override
  Future<int> createDebtLoan(DebtLoan debtLoan, int walletId) async {
    final map = debtLoan.toMap();
    map['wallet_id'] = walletId;
    final response =
        await _client.from('debts_loans').insert(map).select().single();
    return response['id'] as int;
  }

  @override
  Future<int> updateDebtLoan(DebtLoan debtLoan) async {
    final response = await _client
        .from('debts_loans')
        .update(debtLoan.toMap())
        .eq('id', debtLoan.id!)
        .select()
        .single();
    return response['id'] as int;
  }

  @override
  Future<int> deleteDebtLoan(int id) async {
    await _client.from('debts_loans').delete().eq('id', id);
    return id;
  }

  @override
  Future<int> markAsSettled(int id, bool isSettled) async {
    final response = await _client
        .from('debts_loans')
        .update({'is_settled': isSettled})
        .eq('id', id)
        .select()
        .single();
    return response['id'] as int;
  }
}