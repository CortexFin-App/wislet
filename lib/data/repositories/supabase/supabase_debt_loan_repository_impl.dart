import 'package:fpdart/fpdart.dart';
import 'package:wislet/core/error/failures.dart';
import 'package:wislet/data/repositories/debt_loan_repository.dart';
import 'package:wislet/models/debt_loan_model.dart';
import 'package:wislet/services/error_monitoring_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDebtLoanRepositoryImpl implements DebtLoanRepository {
  SupabaseDebtLoanRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<DebtLoan>> watchAllDebtLoans(int walletId) {
    return _client.from('debts_loans').stream(primaryKey: ['id']).map(
      (listOfMaps) {
        final debts = listOfMaps
            .map(DebtLoan.fromMap)
            .where(
              (debt) => debt.isDeleted == false && debt.walletId == walletId,
            )
            .toList();
        debts.sort((a, b) => b.creationDate.compareTo(a.creationDate));
        return debts;
      },
    );
  }

  @override
  Future<Either<AppFailure, List<DebtLoan>>> getAllDebtLoans(
    int walletId,
  ) async {
    try {
      final response = await _client
          .from('debts_loans')
          .select()
          .eq('wallet_id', walletId)
          .eq('is_deleted', false)
          .order('creation_date', ascending: false);
      return Right(response.map(DebtLoan.fromMap).toList());
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
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
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> createDebtLoan(
    DebtLoan debtLoan,
    int walletId,
  ) async {
    try {
      final map = debtLoan.toMap();
      map['wallet_id'] = walletId;
      final response =
          await _client.from('debts_loans').insert(map).select().single();
      return Right(response['id'] as int);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
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
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteDebtLoan(int id) async {
    try {
      await _client.from('debts_loans').update({
        'is_deleted': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      return Right(id);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> markAsSettled(
    int id, {
    required bool isSettled,
  }) async {
    try {
      final response = await _client
          .from('debts_loans')
          .update({'is_settled': isSettled})
          .eq('id', id)
          .select()
          .single();
      return Right(response['id'] as int);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }
}
