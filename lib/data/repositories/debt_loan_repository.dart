import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../../models/debt_loan_model.dart';

abstract class DebtLoanRepository {
  Future<Either<AppFailure, int>> createDebtLoan(DebtLoan debtLoan, int walletId);
  Future<Either<AppFailure, DebtLoan?>> getDebtLoan(int id);
  Future<Either<AppFailure, List<DebtLoan>>> getAllDebtLoans(int walletId);
  Future<Either<AppFailure, int>> updateDebtLoan(DebtLoan debtLoan);
  Future<Either<AppFailure, int>> deleteDebtLoan(int id);
  Future<Either<AppFailure, int>> markAsSettled(int id, bool isSettled);
}