import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/subscription_model.dart';
import '../subscription_repository.dart';

class SupabaseSubscriptionRepositoryImpl implements SubscriptionRepository {
  final SupabaseClient _client;
  SupabaseSubscriptionRepositoryImpl(this._client);

  @override
  Future<List<Subscription>> getAllSubscriptions(int walletId) async {
    final response = await _client
        .from('subscriptions')
        .select()
        .eq('wallet_id', walletId)
        .order('next_payment_date', ascending: true);
    return (response as List).map((data) => Subscription.fromMap(data)).toList();
  }
  
  @override
  Future<Subscription?> getSubscription(int id) async {
    final response = await _client.from('subscriptions').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return Subscription.fromMap(response);
  }

  @override
  Future<int> createSubscription(Subscription sub, int walletId) async {
    final map = sub.toMap();
    map['wallet_id'] = walletId;
    final response = await _client.from('subscriptions').insert(map).select().single();
    return response['id'] as int;
  }

  @override
  Future<int> updateSubscription(Subscription sub, int walletId) async {
    final map = sub.toMap();
    map['wallet_id'] = walletId;
    final response = await _client.from('subscriptions').update(map).eq('id', sub.id!).select().single();
    return response['id'] as int;
  }

  @override
  Future<int> deleteSubscription(int id) async {
    await _client.from('subscriptions').delete().eq('id', id);
    return id;
  }
}