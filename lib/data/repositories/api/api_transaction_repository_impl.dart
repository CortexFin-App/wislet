import 'package:sage_wallet_reborn/models/transaction.dart' as FinTransactionModel;
import 'package:sage_wallet_reborn/models/transaction_view_data.dart';
import 'package:sage_wallet_reborn/models/wallet.dart';
import 'package:sage_wallet_reborn/services/api_client.dart';
import 'package:sage_wallet_reborn/data/repositories/transaction_repository.dart';

class ApiTransactionRepositoryImpl implements TransactionRepository {
  final ApiClient _apiClient;

  ApiTransactionRepositoryImpl(this._apiClient);

  @override
  Future<void> createTransfer({
    required Wallet fromWallet,
    required Wallet toWallet,
    required double amount,
    required String currencyCode,
    required DateTime date,
    String? description,
  }) async {
    await _apiClient.post(
      '/transfers',
      body: {
        'from_wallet_id': fromWallet.id,
        'to_wallet_id': toWallet.id,
        'amount': amount,
        'currency_code': currencyCode,
        'date': date.toIso8601String(),
        'description': description,
      },
    );
  }

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
    final queryParams = <String, String>{
      'walletId': walletId.toString(),
    };
    if (orderBy != null) queryParams['orderBy'] = orderBy;
    if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
    if (filterTransactionType != null) queryParams['type'] = filterTransactionType.toString();
    if (filterCategoryId != null) queryParams['categoryId'] = filterCategoryId.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (searchQuery != null && searchQuery.isNotEmpty) queryParams['q'] = searchQuery;

    final responseData = await _apiClient.get('/transactions', queryParams: queryParams) as List;
    return responseData.map((data) => TransactionViewData.fromMap(data)).toList();
  }

  @override
  Future<int> createTransaction(FinTransactionModel.Transaction transaction, int walletId) async {
    final map = transaction.toMap();
    map['wallet_id'] = walletId;
    final responseData = await _apiClient.post('/transactions', body: map);
    return responseData['id'] as int;
  }

  @override
  Future<double> getOverallBalance(int walletId) async {
    final responseData = await _apiClient.get('/wallets/$walletId/balance');
    return (responseData['balance'] as num).toDouble();
  }

  @override
  Future<int> deleteTransaction(int transactionId) async {
    await _apiClient.delete('/transactions/$transactionId');
    return transactionId;
  }

  @override
  Future<int> updateTransaction(FinTransactionModel.Transaction transaction, int walletId) async {
    final map = transaction.toMap();
    map['wallet_id'] = walletId;
    final responseData = await _apiClient.put('/transactions/${transaction.id}', body: map);
    return responseData['id'] as int;
  }

  @override
  Future<FinTransactionModel.Transaction?> getTransaction(int transactionId) async {
    final responseData = await _apiClient.get('/transactions/$transactionId');
    if (responseData == null) return null;
    return FinTransactionModel.Transaction.fromMap(responseData);
  }

  @override
  Future<List<FinTransactionModel.Transaction>> getTransactionsForGoal(int goalId) async {
    final responseData = await _apiClient.get('/goals/$goalId/transactions') as List;
    return responseData.map((data) => FinTransactionModel.Transaction.fromMap(data)).toList();
  }

  @override
  Future<double> getTotalAmount({
    required int walletId,
    required DateTime startDate,
    required DateTime endDate,
    required FinTransactionModel.TransactionType transactionType,
    int? categoryId,
  }) async {
    final queryParams = <String, String>{
      'walletId': walletId.toString(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'type': transactionType.toString(),
    };
    if (categoryId != null) {
      queryParams['categoryId'] = categoryId.toString();
    }
    final responseData = await _apiClient.get('/reports/total-amount', queryParams: queryParams);
    return (responseData['total'] as num).toDouble();
  }

  @override
  Future<List<Map<String, dynamic>>> getExpensesGroupedByCategory(int walletId, DateTime startDate, DateTime endDate) async {
    final queryParams = {
      'walletId': walletId.toString(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
    final responseData = await _apiClient.get('/reports/expenses-by-category', queryParams: queryParams) as List;
    return List<Map<String, dynamic>>.from(responseData);
  }
}