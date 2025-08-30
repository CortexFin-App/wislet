import 'package:fpdart/fpdart.dart';
import 'package:sage_wallet_reborn/core/error/failures.dart';
import 'package:sage_wallet_reborn/models/asset.dart';

abstract class AssetRepository {
  Stream<List<Asset>> watchAllAssets(int walletId);

  Future<Either<AppFailure, int>> createAsset(
    Asset asset,
    int walletId,
    String userId,
  );

  Future<Either<AppFailure, int>> updateAsset(Asset asset);

  Future<Either<AppFailure, int>> deleteAsset(int assetId);
}
