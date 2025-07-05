import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/transaction.dart' as FinTransactionModel;
import '../../../models/transaction_view_data.dart';
import '../../../models/wallet.dart';
import '../transaction_repository.dart';

class SupabaseTransactionRepositoryImpl implements TransactionRepository {
  final SupabaseClient _client;
  SupabaseTransactionRepositoryImpl(this._client);

  @override
  Future<List<TransactionViewData>> getTransactionsWithDetails({
    required int walletId,
    String? orderBy,
    DateTime? startDate,
    DateTime? endDate,
    FinTransactionModel.TransactionType? filterTransactionType,
    int? filterCategoryId,
    int? limit,
    String? searchQuery,
  }) async {
    var query = _client
        .from('transactions')
        .select('*, categories(*)')
        .eq('wallet_id', walletId);

    if (startDate != null) query = query.gte('date', startDate.toIso8601String());
    if (endDate != null) query = query.lte('date', endDate.toIso8601String());
    if (filterTransactionType != null) query = query.eq('type', filterTransactionType.name);
    if (filterCategoryId != null) query = query.eq('category_id', filterCategoryId);
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('description', '%$searchQuery%');
    }

    final finalQuery = query.order('date', ascending: false);
    if (limit != null) {
      finalQuery.limit(limit);
    }
    
    final response = await finalQuery;
    return (response as List).map((data) => TransactionViewData.fromMap(data)).toList();
  }
  
  @override
  Future<FinTransactionModel.Transaction?> getTransaction(int transactionId) async {
    final response = await _client
        .from('transactions')
        .select('*, categories(*)')
        .eq('id', transactionId)
        .maybeSingle();
    if (response == null) return null;
    return FinTransactionModel.Transaction.fromMap(response);
  }

  @override
  Future<int> createTransaction(FinTransactionModel.Transaction transaction, int walletId) async {
    final map = transaction.toMap();
    map['wallet_id'] = walletId;
    map['user_id'] = _client.auth.currentUser!.id;
    final response = await _client.from('transactions').insert(map).select().single();
    return response['id'] as int;
  }
  
  @override
  Future<int> updateTransaction(FinTransactionModel.Transaction transaction, int walletId) async {
    final map = transaction.toMap();
    map['wallet_id'] = walletId;
    final response = await _client.from('transactions').update(map).eq('id', transaction.id!).select().single();
    return response['id'] as int;
  }

  @override
  Future<int> deleteTransaction(int transactionId) async {
    await _client.from('transactions').delete().eq('id', transactionId);
    return transactionId;
  }
  
  @override
  Future<void> createTransfer({
    required Wallet fromWallet,
    required Wallet toWallet,
    required double amount,
    required String currencyCode,
    required DateTime date,
    String? description,
  }) async {
    await _client.rpc('create_transfer', params: {
      'p_from_wallet_id': fromWallet.id,
      'p_to_wallet_id': toWallet.id,
      'p_amount': amount,
      'p_user_id': _client.auth.currentUser!.id,
      'p_currency_code': currencyCode,
      'p_description': description,
      'p_date': date.toIso8601String(),
    });
  }

  @override
  Future<double> getOverallBalance(int walletId) async {
    final response = await _client.rpc('get_wallet_balance', params: {'p_wallet_id': walletId});
    return (response as num? ?? 0.0).toDouble();
  }

  @override
  Future<double> getTotalAmount({
    required int walletId,
    required DateTime startDate,
    required DateTime endDate,
    required FinTransactionModel.TransactionType transactionType,
    int? categoryId,
  }) async {
    var query = _client
        .from('transactions')
        .select('amount_in_base_currency')
        .eq('wallet_id', walletId)
        .eq('type', transactionType.name)
        .gte('date', startDate.toIso8601String())
        .lte('date', endDate.toIso8601String());
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    final response = await query;
    return (response as List).fold<double>(0.0, (sum, item) => sum + (item['amount_in_base_currency'] as num));
  }

  @override
  Future<List<Map<String, dynamic>>> getExpensesGroupedByCategory(int walletId, DateTime startDate, DateTime endDate) async {
    final response = await _client.rpc('get_expenses_grouped_by_category', params: {
      'p_wallet_id': walletId,
      'p_start_date': startDate.toIso8601String(),
      'p_end_date': endDate.toIso8601String(),
    });
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<List<FinTransactionModel.Transaction>> getTransactionsForGoal(int goalId) async {
    final response = await _client.from('transactions').select().eq('linked_goal_id', goalId);
    return (response as List).map((data) => FinTransactionModel.Transaction.fromMap(data)).toList();
  }
}