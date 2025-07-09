import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/error/failures.dart';
import '../../../models/transaction.dart' as fin_transaction_model;
import '../../../models/transaction_view_data.dart';
import '../../../models/wallet.dart';
import '../../../services/error_monitoring_service.dart';
import '../transaction_repository.dart';

class SupabaseTransactionRepositoryImpl implements TransactionRepository {
  final SupabaseClient _client;
  SupabaseTransactionRepositoryImpl(this._client);

  @override
  Future<Either<AppFailure, List<TransactionViewData>>> getTransactionsWithDetails({
    required int walletId,
    String? orderBy,
    DateTime? startDate,
    DateTime? endDate,
    fin_transaction_model.TransactionType? filterTransactionType,
    int? filterCategoryId,
    int? limit,
    String? searchQuery,
  }) async {
    try {
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
      return Right((response as List).map((data) => TransactionViewData.fromMap(data)).toList());
    } catch(e,s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, fin_transaction_model.Transaction?>> getTransaction(int transactionId) async {
    try {
      final response = await _client
        .from('transactions')
        .select('*, categories(*)')
        .eq('id', transactionId)
        .maybeSingle();
      if (response == null) return const Right(null);
      return Right(fin_transaction_model.Transaction.fromMap(response));
    } catch(e,s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> createTransaction(fin_transaction_model.Transaction transaction, int walletId) async {
    try {
      final map = transaction.toMap();
      map['wallet_id'] = walletId;
      map['user_id'] = _client.auth.currentUser!.id;
      final response = await _client.from('transactions').insert(map).select().single();
      return Right(response['id'] as int);
    } catch(e,s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateTransaction(fin_transaction_model.Transaction transaction, int walletId) async {
    try {
      final map = transaction.toMap();
      map['wallet_id'] = walletId;
      final response = await _client.from('transactions').update(map).eq('id', transaction.id!).select().single();
      return Right(response['id'] as int);
    } catch(e,s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteTransaction(int transactionId) async {
    try {
      await _client.from('transactions').delete().eq('id', transactionId);
      return Right(transactionId);
    } catch(e,s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> createTransfer({
    required Wallet fromWallet,
    required Wallet toWallet,
    required double amount,
    required String currencyCode,
    required DateTime date,
    String? description,
  }) async {
    try {
      await _client.rpc('create_transfer', params: {
        'p_from_wallet_id': fromWallet.id,
        'p_to_wallet_id': toWallet.id,
        'p_amount': amount,
        'p_user_id': _client.auth.currentUser!.id,
        'p_currency_code': currencyCode,
        'p_description': description,
        'p_date': date.toIso8601String(),
      });
      return const Right(null);
    } catch(e,s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, double>> getOverallBalance(int walletId) async {
    try {
      final response = await _client.rpc('get_wallet_balance', params: {'p_wallet_id': walletId});
      return Right((response as num? ?? 0.0).toDouble());
    } catch(e,s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, double>> getTotalAmount({
    required int walletId,
    required DateTime startDate,
    required DateTime endDate,
    required fin_transaction_model.TransactionType transactionType,
    int? categoryId,
  }) async {
    try {
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
      return Right((response as List).fold<double>(0.0, (sum, item) => sum + (item['amount_in_base_currency'] as num)));
    } catch(e,s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<Map<String, dynamic>>>> getExpensesGroupedByCategory(int walletId, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client.rpc('get_expenses_grouped_by_category', params: {
        'p_wallet_id': walletId,
        'p_start_date': startDate.toIso8601String(),
        'p_end_date': endDate.toIso8601String(),
      });
      return Right(List<Map<String, dynamic>>.from(response));
    } catch(e,s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<fin_transaction_model.Transaction>>> getTransactionsForGoal(int goalId) async {
    try {
      final response = await _client.from('transactions').select().eq('linked_goal_id', goalId);
      return Right((response as List).map((data) => fin_transaction_model.Transaction.fromMap(data)).toList());
    } catch(e,s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<fin_transaction_model.Transaction>>> getTransactionsSince(int walletId, String? lastSyncTimestamp) async {
     try {
       var query = _client
           .from('transactions')
           .select()
           .eq('wallet_id', walletId);
       if(lastSyncTimestamp != null) {
          query = query.gt('updated_at', lastSyncTimestamp);
       }
       final response = await query;
       return Right((response as List).map((data) => fin_transaction_model.Transaction.fromMap(data)).toList());
     } catch (e,s) {
       ErrorMonitoringService.capture(e, stackTrace: s);
       return Left(NetworkFailure(details: e.toString()));
     }
  }
}