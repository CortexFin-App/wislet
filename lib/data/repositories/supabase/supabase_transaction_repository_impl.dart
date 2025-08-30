import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:sage_wallet_reborn/core/error/failures.dart';
import 'package:sage_wallet_reborn/data/repositories/transaction_repository.dart';
import 'package:sage_wallet_reborn/models/transaction.dart'
    as fin_transaction_model;
import 'package:sage_wallet_reborn/models/transaction_view_data.dart';
import 'package:sage_wallet_reborn/models/wallet.dart';
import 'package:sage_wallet_reborn/services/error_monitoring_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseTransactionRepositoryImpl implements TransactionRepository {
  SupabaseTransactionRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Either<AppFailure, List<TransactionViewData>>>
      getTransactionsWithDetails({
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

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String());
      }
      if (filterTransactionType != null) {
        query = query.eq('type', filterTransactionType.name);
      }
      if (filterCategoryId != null) {
        query = query.eq('category_id', filterCategoryId);
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('description', '%$searchQuery%');
      }

      final finalQuery = query.order('date', ascending: false);
      if (limit != null) {
        finalQuery.limit(limit);
      }

      final response = await finalQuery;
      return Right(
        response
            .map(
              TransactionViewData.fromMap,
            )
            .toList(),
      );
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Stream<List<TransactionViewData>> watchTransactionsWithDetails({
    required int walletId,
  }) {
    final query = _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('wallet_id', walletId)
        .order('date');

    return query.map(
      (data) => data.map(TransactionViewData.fromMap).toList(),
    );
  }

  @override
  Future<Either<AppFailure, int>> createTransaction(
    fin_transaction_model.Transaction transaction,
    int walletId,
    String userId,
  ) async {
    try {
      final map = transaction.toMap();
      map['wallet_id'] = walletId;
      map['user_id'] = userId;
      final response =
          await _client.from('transactions').insert(map).select().single();
      return Right(response['id'] as int);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateTransaction(
    fin_transaction_model.Transaction transaction,
    int walletId,
    String userId,
  ) async {
    try {
      final map = transaction.toMap();
      map['wallet_id'] = walletId;
      map['user_id'] = userId;
      final response = await _client
          .from('transactions')
          .update(map)
          .eq('id', transaction.id!)
          .select()
          .single();
      return Right(response['id'] as int);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, fin_transaction_model.Transaction?>> getTransaction(
    int transactionId,
  ) async {
    try {
      final response = await _client
          .from('transactions')
          .select('*, categories(*)')
          .eq('id', transactionId)
          .maybeSingle();
      if (response == null) return const Right(null);
      return Right(fin_transaction_model.Transaction.fromMap(response));
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteTransaction(int transactionId) async {
    try {
      await _client.from('transactions').delete().eq('id', transactionId);
      return Right(transactionId);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
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
      await _client.rpc<void>(
        'create_transfer',
        params: {
          'p_from_wallet_id': fromWallet.id,
          'p_to_wallet_id': toWallet.id,
          'p_amount': amount,
          'p_user_id': _client.auth.currentUser!.id,
          'p_currency_code': currencyCode,
          'p_description': description,
          'p_date': date.toIso8601String(),
        },
      );
      return const Right(null);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, double>> getOverallBalance(int walletId) async {
    try {
      final response = await _client.rpc<dynamic>(
        'get_wallet_balance',
        params: {'p_wallet_id': walletId},
      );
      return Right((response as num? ?? 0.0).toDouble());
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
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
      return Right(
        response.fold<double>(
          0,
          (sum, item) =>
              sum + (item['amount_in_base_currency'] as num).toDouble(),
        ),
      );
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<Map<String, dynamic>>>>
      getExpensesGroupedByCategory(
    int walletId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _client.rpc<List<dynamic>>(
        'get_expenses_grouped_by_category',
        params: {
          'p_wallet_id': walletId,
          'p_start_date': startDate.toIso8601String(),
          'p_end_date': endDate.toIso8601String(),
        },
      );
      return Right(List<Map<String, dynamic>>.from(response));
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<fin_transaction_model.Transaction>>>
      getTransactionsForGoal(int goalId) async {
    try {
      final response = await _client
          .from('transactions')
          .select()
          .eq('linked_goal_id', goalId);
      return Right(
        response
            .map(
              fin_transaction_model.Transaction.fromMap,
            )
            .toList(),
      );
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<fin_transaction_model.Transaction>>>
      getTransactionsSince(int walletId, String? lastSyncTimestamp) async {
    try {
      var query =
          _client.from('transactions').select().eq('wallet_id', walletId);
      if (lastSyncTimestamp != null) {
        query = query.gt('updated_at', lastSyncTimestamp);
      }
      final response = await query;
      return Right(
        response
            .map(
              fin_transaction_model.Transaction.fromMap,
            )
            .toList(),
      );
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }
}
