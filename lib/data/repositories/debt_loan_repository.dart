import '../../models/debt_loan_model.dart';

abstract class DebtLoanRepository {
  Future<int> createDebtLoan(DebtLoan debtLoan, int walletId);
  Future<DebtLoan?> getDebtLoan(int id);
  Future<List<DebtLoan>> getAllDebtLoans(int walletId);
  Future<int> updateDebtLoan(DebtLoan debtLoan);
  Future<int> deleteDebtLoan(int id);
  Future<int> markAsSettled(int id, bool isSettled);
}