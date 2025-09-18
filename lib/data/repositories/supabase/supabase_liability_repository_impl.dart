import 'package:fpdart/fpdart.dart';
import 'package:wislet/core/error/failures.dart';
import 'package:wislet/data/repositories/liability_repository.dart';
import 'package:wislet/models/liability.dart';
import 'package:wislet/services/error_monitoring_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseLiabilityRepositoryImpl implements LiabilityRepository {
  SupabaseLiabilityRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<Liability>> watchAllLiabilities(int walletId) {
    return _client.from('liabilities').stream(primaryKey: ['id']).map(
      (listOfMaps) => listOfMaps
          .where(
            (item) =>
                item['wallet_id'] == walletId && item['is_deleted'] == false,
          )
          .map(Liability.fromMap)
          .toList(),
    );
  }

  @override
  Future<Either<AppFailure, int>> createLiability(
    Liability liability,
    int walletId,
    String userId,
  ) async {
    try {
      final map = liability.toMap();
      map['wallet_id'] = walletId;
      map['user_id'] = userId;
      final response =
          await _client.from('liabilities').insert(map).select().single();
      return Right(response['id'] as int);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateLiability(Liability liability) async {
    try {
      final response = await _client
          .from('liabilities')
          .update(liability.toMap())
          .eq('id', liability.id!)
          .select()
          .single();
      return Right(response['id'] as int);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteLiability(int liabilityId) async {
    try {
      await _client.from('liabilities').update({
        'is_deleted': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', liabilityId);
      return Right(liabilityId);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }
}
