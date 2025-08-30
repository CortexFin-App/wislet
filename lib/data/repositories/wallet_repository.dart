import 'package:fpdart/fpdart.dart';
import 'package:sage_wallet_reborn/core/error/failures.dart';
import 'package:sage_wallet_reborn/models/wallet.dart';

abstract class WalletRepository {
  Future<Either<AppFailure, List<Wallet>>> getAllWallets();

  Future<Either<AppFailure, Wallet?>> getWallet(int id);

  Future<Either<AppFailure, int>> createWallet({
    required String name,
    required String ownerUserId,
    bool isDefault = false,
  });

  Future<Either<AppFailure, void>> createInitialWallet();

  Future<Either<AppFailure, int>> updateWallet(Wallet wallet);

  Future<Either<AppFailure, int>> deleteWallet(int walletId);

  Future<Either<AppFailure, void>> changeUserRole(
    int walletId,
    String userId,
    String newRole,
  );

  Future<Either<AppFailure, void>> removeUserFromWallet(
    int walletId,
    String userId,
  );
}
