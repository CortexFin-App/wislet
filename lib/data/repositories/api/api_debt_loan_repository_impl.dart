import 'package:sage_wallet_reborn/models/debt_loan_model.dart';
import 'package:sage_wallet_reborn/services/api_client.dart';
import 'package:sage_wallet_reborn/data/repositories/debt_loan_repository.dart';

class ApiDebtLoanRepositoryImpl implements DebtLoanRepository {
  final ApiClient _apiClient;

  ApiDebtLoanRepositoryImpl(this._apiClient);

  @override
  Future<List<DebtLoan>> getAllDebtLoans(int walletId) async {
    final responseData = await _apiClient.get('/debts-loans', queryParams: {'walletId': walletId.toString()}) as List;
    return responseData.map((data) => DebtLoan.fromMap(data)).toList();
  }

  @override
  Future<int> createDebtLoan(DebtLoan debtLoan, int walletId) async {
    final map = debtLoan.toMap();
    map['wallet_id'] = walletId;
    final responseData = await _apiClient.post('/debts-loans', body: map);
    return responseData['id'] as int;
  }

  @override
  Future<DebtLoan?> getDebtLoan(int id) async {
    final responseData = await _apiClient.get('/debts-loans/$id');
    if (responseData == null) return null;
    return DebtLoan.fromMap(responseData);
  }

  @override
  Future<int> updateDebtLoan(DebtLoan debtLoan) async {
    final responseData = await _apiClient.put('/debts-loans/${debtLoan.id}', body: debtLoan.toMap());
    return responseData['id'] as int;
  }

  @override
  Future<int> deleteDebtLoan(int id) async {
    await _apiClient.delete('/debts-loans/$id');
    return id;
  }

  @override
  Future<int> markAsSettled(int id, bool isSettled) async {
    final responseData = await _apiClient.put('/debts-loans/$id/settle', body: {'is_settled': isSettled});
    return responseData['id'] as int;
  }
}