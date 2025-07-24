import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/error/failures.dart';
import '../../../models/liability.dart';
import '../../../services/error_monitoring_service.dart';
import '../liability_repository.dart';

class SupabaseLiabilityRepositoryImpl implements LiabilityRepository {
  final SupabaseClient _client;
  SupabaseLiabilityRepositoryImpl(this._client);

  @override
  Stream<List<Liability>> watchAllLiabilities(int walletId) {
    return _client
        .from('liabilities')
        .stream(primaryKey: ['id'])
        .map((listOfMaps) {
          return listOfMaps
              .where((item) => item['wallet_id'] == walletId && item['is_deleted'] == false)
              .map((item) => Liability.fromMap(item))
              .toList();
        });
  }

  @override
  Future<Either<AppFailure, int>> createLiability(Liability liability, int walletId, String userId) async {
    try {
      final map = liability.toMap();
      map['wallet_id'] = walletId;
      map['user_id'] = userId;
      final response = await _client.from('liabilities').insert(map).select().single();
      return Right(response['id'] as int);
    } catch (e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateLiability(Liability liability) async {
    try {
      final response = await _client.from('liabilities').update(liability.toMap()).eq('id', liability.id!).select().single();
      return Right(response['id'] as int);
    } catch (e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteLiability(int liabilityId) async {
    try {
      await _client
        .from('liabilities')
        .update({'is_deleted': true, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', liabilityId);
      return Right(liabilityId);
    } catch (e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }
}