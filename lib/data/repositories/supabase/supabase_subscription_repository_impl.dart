import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/error/failures.dart';
import '../../../models/subscription_model.dart';
import '../../../services/error_monitoring_service.dart';
import '../subscription_repository.dart';

class SupabaseSubscriptionRepositoryImpl implements SubscriptionRepository {
  final SupabaseClient _client;
  SupabaseSubscriptionRepositoryImpl(this._client);

  @override
  Future<Either<AppFailure, List<Subscription>>> getAllSubscriptions(int walletId) async {
    try {
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('wallet_id', walletId)
          .eq('is_deleted', false)
          .order('next_payment_date', ascending: true);
      final subscriptions = (response as List).map((data) => Subscription.fromMap(data)).toList();
      return Right(subscriptions);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }
  
  @override
  Future<Either<AppFailure, Subscription?>> getSubscription(int id) async {
    try {
      final response = await _client.from('subscriptions').select().eq('id', id).eq('is_deleted', false).maybeSingle();
      if (response == null) {
        return const Right(null);
      }
      return Right(Subscription.fromMap(response));
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> createSubscription(Subscription sub, int walletId) async {
    try {
      final map = sub.toMap();
      map['wallet_id'] = walletId;
      map['user_id'] = _client.auth.currentUser!.id;
      final response = await _client.from('subscriptions').insert(map).select().single();
      return Right(response['id'] as int);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateSubscription(Subscription sub, int walletId) async {
    try {
      final map = sub.toMap();
      map['wallet_id'] = walletId;
      map['user_id'] = _client.auth.currentUser!.id;
      final response = await _client.from('subscriptions').update(map).eq('id', sub.id!).select().single();
      return Right(response['id'] as int);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteSubscription(int id) async {
    try {
      await _client
        .from('subscriptions')
        .update({'is_deleted': true, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
      return Right(id);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }
}