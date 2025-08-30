import 'package:rxdart/rxdart.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/data/repositories/asset_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/liability_repository.dart';
import 'package:sage_wallet_reborn/models/asset.dart';
import 'package:sage_wallet_reborn/models/liability.dart';

class NetWorthData {
  NetWorthData({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
    required this.assets,
    required this.liabilities,
  });

  final double totalAssets;
  final double totalLiabilities;
  final double netWorth;
  final List<Asset> assets;
  final List<Liability> liabilities;
}

class NetWorthService {
  final AssetRepository _assetRepo = getIt<AssetRepository>();
  final LiabilityRepository _liabilityRepo = getIt<LiabilityRepository>();

  Stream<NetWorthData> watchNetWorth(int walletId) {
    return Rx.combineLatest2(
      _assetRepo.watchAllAssets(walletId),
      _liabilityRepo.watchAllLiabilities(walletId),
      (assets, liabilities) {
        final totalAssets =
            assets.fold<double>(0, (sum, asset) => sum + asset.value);
        final totalLiabilities = liabilities.fold<double>(
          0,
          (sum, liability) => sum + liability.amount,
        );
        final netWorth = totalAssets - totalLiabilities;

        return NetWorthData(
          totalAssets: totalAssets,
          totalLiabilities: totalLiabilities,
          netWorth: netWorth,
          assets: assets,
          liabilities: liabilities,
        );
      },
    );
  }
}
