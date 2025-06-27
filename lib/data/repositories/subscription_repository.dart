import '../../models/subscription_model.dart';

abstract class SubscriptionRepository {
  Future<int> createSubscription(Subscription sub, int walletId);
  Future<Subscription?> getSubscription(int id);
  Future<List<Subscription>> getAllSubscriptions(int walletId);
  Future<int> updateSubscription(Subscription sub, int walletId);
  Future<int> deleteSubscription(int id);
}