import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../../models/subscription_model.dart';

abstract class SubscriptionRepository {
  Future<Either<AppFailure, int>> createSubscription(Subscription sub, int walletId);
  Future<Either<AppFailure, Subscription?>> getSubscription(int id);
  Future<Either<AppFailure, List<Subscription>>> getAllSubscriptions(int walletId);
  Stream<List<Subscription>> watchAllSubscriptions(int walletId);
  Future<Either<AppFailure, int>> updateSubscription(Subscription sub, int walletId);
  Future<Either<AppFailure, int>> deleteSubscription(int id);
}