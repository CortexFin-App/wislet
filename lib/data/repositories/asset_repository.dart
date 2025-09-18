import 'package:fpdart/fpdart.dart';
import 'package:wislet/core/error/failures.dart';
import 'package:wislet/models/asset.dart';

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
