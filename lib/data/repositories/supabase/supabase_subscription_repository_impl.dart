import 'package:fpdart/fpdart.dart';
import 'package:wislet/core/error/failures.dart';
import 'package:wislet/data/repositories/subscription_repository.dart';
import 'package:wislet/models/subscription_model.dart';
import 'package:wislet/services/error_monitoring_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSubscriptionRepositoryImpl implements SubscriptionRepository {
  SupabaseSubscriptionRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<Subscription>> watchAllSubscriptions(int walletId) {
    return _client.from('subscriptions').stream(primaryKey: ['id']).map(
      (listOfMaps) {
        final subscriptions = listOfMaps
            .where(
              (item) =>
                  item['wallet_id'] == walletId && item['is_deleted'] == false,
            )
            .map(Subscription.fromMap)
            .toList();
        subscriptions
            .sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
        return subscriptions;
      },
    );
  }

  @override
  Future<Either<AppFailure, List<Subscription>>> getAllSubscriptions(
    int walletId,
  ) async {
    try {
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('wallet_id', walletId)
          .eq('is_deleted', false)
          .order('next_payment_date', ascending: true);
      final subscriptions = response.map(Subscription.fromMap).toList();
      return Right(subscriptions);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, Subscription?>> getSubscription(int id) async {
    try {
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('id', id)
          .eq('is_deleted', false)
          .maybeSingle();
      if (response == null) {
        return const Right(null);
      }
      return Right(Subscription.fromMap(response));
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> createSubscription(
    Subscription sub,
    int walletId,
  ) async {
    try {
      final map = sub.toMap();
      map['wallet_id'] = walletId;
      map['user_id'] = _client.auth.currentUser!.id;
      final response =
          await _client.from('subscriptions').insert(map).select().single();
      return Right(response['id'] as int);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateSubscription(
    Subscription sub,
    int walletId,
  ) async {
    try {
      final map = sub.toMap();
      map['wallet_id'] = walletId;
      map['user_id'] = _client.auth.currentUser!.id;
      final response = await _client
          .from('subscriptions')
          .update(map)
          .eq('id', sub.id!)
          .select()
          .single();
      return Right(response['id'] as int);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteSubscription(int id) async {
    try {
      await _client.from('subscriptions').update({
        'is_deleted': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      return Right(id);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }
}
