import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/error/failures.dart';
import '../../../models/debt_loan_model.dart';
import '../../../services/error_monitoring_service.dart';
import '../debt_loan_repository.dart';

class SupabaseDebtLoanRepositoryImpl implements DebtLoanRepository {
  final SupabaseClient _client;
  SupabaseDebtLoanRepositoryImpl(this._client);

  @override
  Stream<List<DebtLoan>> watchAllDebtLoans(int walletId) {
    return _client
        .from('debts_loans')
        .stream(primaryKey: ['id'])
        .map((listOfMaps) {
          return listOfMaps
              .map((item) => DebtLoan.fromMap(item))
              .where((debt) => debt.isDeleted == false && debt.walletId == walletId)
              .toList()
              ..sort((a,b) => b.creationDate.compareTo(a.creationDate));
        });
  }

  @override
  Future<Either<AppFailure, List<DebtLoan>>> getAllDebtLoans(
      int walletId) async {
    try {
      final response = await _client
          .from('debts_loans')
          .select()
          .eq('wallet_id', walletId)
          .eq('is_deleted', false)
          .order('creation_date', ascending: false);
      return Right(
          (response).map((data) => DebtLoan.fromMap(data)).toList());
    } catch (e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, DebtLoan?>> getDebtLoan(int id) async {
    try {
      final response =
          await _client.from('debts_loans').select().eq('id', id).maybeSingle();
      if (response == null) return const Right(null);
      return Right(DebtLoan.fromMap(response));
    } catch (e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> createDebtLoan(
      DebtLoan debtLoan, int walletId) async {
    try {
      final map = debtLoan.toMap();
      map['wallet_id'] = walletId;
      final response =
          await _client.from('debts_loans').insert(map).select().single();
      return Right(response['id'] as int);
    } catch (e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateDebtLoan(DebtLoan debtLoan) async {
    try {
      final response = await _client
          .from('debts_loans')
          .update(debtLoan.toMap())
          .eq('id', debtLoan.id!)
          .select()
          .single();
      return Right(response['id'] as int);
    } catch (e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteDebtLoan(int id) async {
    try {
      await _client.from('debts_loans').update({
        'is_deleted': true,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', id);
      return Right(id);
    } catch (e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> markAsSettled(int id, bool isSettled) async {
    try {
      final response = await _client
          .from('debts_loans')
          .update({'is_settled': isSettled})
          .eq('id', id)
          .select()
          .single();
      return Right(response['id'] as int);
    } catch (e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }
}