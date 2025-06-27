import 'package:sage_wallet_reborn/models/subscription_model.dart';
import 'package:sage_wallet_reborn/services/api_client.dart';
import 'package:sage_wallet_reborn/data/repositories/subscription_repository.dart';

class ApiSubscriptionRepositoryImpl implements SubscriptionRepository {
  final ApiClient _apiClient;
  ApiSubscriptionRepositoryImpl(this._apiClient);
  
  @override
  Future<List<Subscription>> getAllSubscriptions(int walletId) async {
    final responseData = await _apiClient.get('/subscriptions', queryParams: {'walletId': walletId.toString()}) as List;
    return responseData.map((data) => Subscription.fromMap(data)).toList();
  }
  
  @override
  Future<int> createSubscription(Subscription sub, int walletId) async {
    final map = sub.toMap();
    map['wallet_id'] = walletId;
    final responseData = await _apiClient.post('/subscriptions', body: map);
    return responseData['id'] as int;
  }

  @override
  Future<int> updateSubscription(Subscription sub, int walletId) async {
    final map = sub.toMap();
    map['wallet_id'] = walletId;
    final responseData = await _apiClient.put('/subscriptions/${sub.id}', body: map);
    return responseData['id'] as int;
  }

  @override
  Future<int> deleteSubscription(int id) async {
    await _apiClient.delete('/subscriptions/$id');
    return id;
  }

  @override
  Future<Subscription?> getSubscription(int id) {
    throw UnimplementedError();
  }
}