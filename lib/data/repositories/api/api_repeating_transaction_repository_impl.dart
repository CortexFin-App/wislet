import 'package:sage_wallet_reborn/models/repeating_transaction_model.dart';
import 'package:sage_wallet_reborn/services/api_client.dart';
import 'package:sage_wallet_reborn/data/repositories/repeating_transaction_repository.dart';

class ApiRepeatingTransactionRepositoryImpl implements RepeatingTransactionRepository {
  final ApiClient _apiClient;

  ApiRepeatingTransactionRepositoryImpl(this._apiClient);

  @override
  Future<List<RepeatingTransaction>> getAllRepeatingTransactions(int walletId) async {
    final responseData = await _apiClient.get('/repeating-transactions', queryParams: {'walletId': walletId.toString()}) as List;
    return responseData.map((data) => RepeatingTransaction.fromMap(data)).toList();
  }

  @override
  Future<int> createRepeatingTransaction(RepeatingTransaction rt, int walletId) async {
    final map = rt.toMap();
    map['wallet_id'] = walletId;
    final responseData = await _apiClient.post('/repeating-transactions', body: map);
    return responseData['id'] as int;
  }

  @override
  Future<RepeatingTransaction?> getRepeatingTransaction(int id) async {
    final responseData = await _apiClient.get('/repeating-transactions/$id');
    if (responseData == null) return null;
    return RepeatingTransaction.fromMap(responseData);
  }

  @override
  Future<int> updateRepeatingTransaction(RepeatingTransaction rt) async {
    final responseData = await _apiClient.put('/repeating-transactions/${rt.id}', body: rt.toMap());
    return responseData['id'] as int;
  }

  @override
  Future<int> deleteRepeatingTransaction(int id) async {
    await _apiClient.delete('/repeating-transactions/$id');
    return id;
  }
}