import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wislet/core/error/failures.dart';
import 'package:wislet/data/repositories/repeating_transaction_repository.dart';
import 'package:wislet/models/repeating_transaction_model.dart';
import 'package:wislet/services/error_monitoring_service.dart';

class SupabaseRepeatingTransactionRepositoryImpl
    implements RepeatingTransactionRepository {
  SupabaseRepeatingTransactionRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Either<AppFailure, List<RepeatingTransaction>>>
      getAllRepeatingTransactions(int walletId) async {
    try {
      final response = await _client
          .from('repeating_transactions')
          .select()
          .eq('wallet_id', walletId)
          .eq('is_deleted', false)
          .order('next_due_date', ascending: true);
      final transactions = response.map(RepeatingTransaction.fromMap).toList();
      return Right(transactions);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, RepeatingTransaction?>> getRepeatingTransaction(
    int id,
  ) async {
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
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> createRepeatingTransaction(
    RepeatingTransaction rt,
    int walletId,
  ) async {
    try {
      final map = rt.toMap();
      map['wallet_id'] = walletId;
      final response = await _client
          .from('repeating_transactions')
          .insert(map)
          .select()
          .single();
      return Right(response['id'] as int);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateRepeatingTransaction(
    RepeatingTransaction rt,
  ) async {
    try {
      final response = await _client
          .from('repeating_transactions')
          .update(rt.toMap())
          .eq('id', rt.id!)
          .select()
          .single();
      return Right(response['id'] as int);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteRepeatingTransaction(int id) async {
    try {
      await _client.from('repeating_transactions').update({
        'is_deleted': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      return Right(id);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }
}
