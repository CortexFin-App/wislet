import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/error/failures.dart';
import '../../../models/asset.dart';
import '../../../services/error_monitoring_service.dart';
import '../asset_repository.dart';

class SupabaseAssetRepositoryImpl implements AssetRepository {
  final SupabaseClient _client;
  SupabaseAssetRepositoryImpl(this._client);

  @override
  Stream<List<Asset>> watchAllAssets(int walletId) {
    return _client
        .from('assets')
        .stream(primaryKey: ['id'])
        .map((listOfMaps) {
          return listOfMaps
              .where((item) => item['wallet_id'] == walletId && item['is_deleted'] == false)
              .map((item) => Asset.fromMap(item))
              .toList();
        });
  }

  @override
  Future<Either<AppFailure, int>> createAsset(Asset asset, int walletId, String userId) async {
    try {
      final map = asset.toMap();
      map['wallet_id'] = walletId;
      map['user_id'] = userId;
      final response = await _client.from('assets').insert(map).select().single();
      return Right(response['id'] as int);
    } catch (e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateAsset(Asset asset) async {
    try {
      final response = await _client.from('assets').update(asset.toMap()).eq('id', asset.id!).select().single();
      return Right(response['id'] as int);
    } catch (e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }
  
  @override
  Future<Either<AppFailure, int>> deleteAsset(int assetId) async {
    try {
      await _client
        .from('assets')
        .update({'is_deleted': true, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', assetId);
      return Right(assetId);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }
}