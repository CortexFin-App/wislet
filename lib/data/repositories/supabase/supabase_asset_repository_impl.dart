import 'package:fpdart/fpdart.dart';
import 'package:wislet/core/error/failures.dart';
import 'package:wislet/data/repositories/asset_repository.dart';
import 'package:wislet/models/asset.dart';
import 'package:wislet/services/error_monitoring_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAssetRepositoryImpl implements AssetRepository {
  SupabaseAssetRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<Asset>> watchAllAssets(int walletId) {
    return _client.from('assets').stream(primaryKey: ['id']).map(
      (listOfMaps) => listOfMaps
          .where(
            (item) =>
                item['wallet_id'] == walletId && item['is_deleted'] == false,
          )
          .map(Asset.fromMap)
          .toList(),
    );
  }

  @override
  Future<Either<AppFailure, int>> createAsset(
    Asset asset,
    int walletId,
    String userId,
  ) async {
    try {
      final map = asset.toMap();
      map['wallet_id'] = walletId;
      map['user_id'] = userId;
      final response =
          await _client.from('assets').insert(map).select().single();
      return Right(response['id'] as int);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateAsset(Asset asset) async {
    try {
      final response = await _client
          .from('assets')
          .update(asset.toMap())
          .eq('id', asset.id!)
          .select()
          .single();
      return Right(response['id'] as int);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteAsset(int assetId) async {
    try {
      await _client.from('assets').update({
        'is_deleted': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', assetId);
      return Right(assetId);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }
}
