import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/repeating_transaction_model.dart';
import '../repeating_transaction_repository.dart';

class SupabaseRepeatingTransactionRepositoryImpl
    implements RepeatingTransactionRepository {
  final SupabaseClient _client;
  SupabaseRepeatingTransactionRepositoryImpl(this._client);

  @override
  Future<List<RepeatingTransaction>> getAllRepeatingTransactions(
      int walletId) async {
    final response = await _client
        .from('repeating_transactions')
        .select()
        .eq('wallet_id', walletId)
        .order('next_due_date', ascending: true);
    return (response as List)
        .map((data) => RepeatingTransaction.fromMap(data))
        .toList();
  }
  
  @override
  Future<RepeatingTransaction?> getRepeatingTransaction(int id) async {
    final response = await _client
        .from('repeating_transactions')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return RepeatingTransaction.fromMap(response);
  }

  @override
  Future<int> createRepeatingTransaction(
      RepeatingTransaction rt, int walletId) async {
    final map = rt.toMap();
    map['wallet_id'] = walletId;
    final response = await _client
        .from('repeating_transactions')
        .insert(map)
        .select()
        .single();
    return response['id'] as int;
  }

  @override
  Future<int> updateRepeatingTransaction(RepeatingTransaction rt) async {
    final response = await _client
        .from('repeating_transactions')
        .update(rt.toMap())
        .eq('id', rt.id!)
        .select()
        .single();
    return response['id'] as int;
  }

  @override
  Future<int> deleteRepeatingTransaction(int id) async {
    await _client.from('repeating_transactions').delete().eq('id', id);
    return id;
  }
}