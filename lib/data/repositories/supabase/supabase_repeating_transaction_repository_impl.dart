import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/error/failures.dart';
import '../../../models/repeating_transaction_model.dart';
import '../../../services/error_monitoring_service.dart';
import '../repeating_transaction_repository.dart';

class SupabaseRepeatingTransactionRepositoryImpl implements RepeatingTransactionRepository {
  final SupabaseClient _client;
  SupabaseRepeatingTransactionRepositoryImpl(this._client);
  
  @override
  Future<Either<AppFailure, List<RepeatingTransaction>>> getAllRepeatingTransactions(int walletId) async {
    try {
      final response = await _client
          .from('repeating_transactions')
          .select()
          .eq('wallet_id', walletId)
          .eq('is_deleted', false)
          .order('next_due_date', ascending: true);
      final transactions = (response as List).map((data) => RepeatingTransaction.fromMap(data)).toList();
      return Right(transactions);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }
  
  @override
  Future<Either<AppFailure, RepeatingTransaction?>> getRepeatingTransaction(int id) async {
    try {
      final response = await _client
          .from('repeating_transactions')
          .select()
          .eq('id', id)
          .eq('is_deleted', false)
          .maybeSingle();
      if (response == null) {
        return const Right(null);
      }
      return Right(RepeatingTransaction.fromMap(response));
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> createRepeatingTransaction(RepeatingTransaction rt, int walletId) async {
    try {
      final map = rt.toMap();
      map['wallet_id'] = walletId;
      final response = await _client
        .from('repeating_transactions')
        .insert(map)
        .select()
        .single();
      return Right(response['id'] as int);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateRepeatingTransaction(RepeatingTransaction rt) async {
    try {
      final response = await _client
          .from('repeating_transactions')
          .update(rt.toMap())
          .eq('id', rt.id!)
          .select()
          .single();
      return Right(response['id'] as int);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteRepeatingTransaction(int id) async {
    try {
      await _client
        .from('repeating_transactions')
        .update({'is_deleted': true, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
      return Right(id);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }
}