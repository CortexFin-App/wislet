import '../../models/wallet.dart';

abstract class WalletRepository {
  Future<List<Wallet>> getAllWallets();
  Future<Wallet?> getWallet(int id);
  Future<int> createWallet(
      {required String name, required int ownerUserId, bool isDefault = false});
  Future<void> createInitialWallet();
  Future<int> updateWallet(Wallet wallet);
  Future<int> deleteWallet(int walletId);
  Future<void> changeUserRole(int walletId, String userId, String newRole);
  Future<void> removeUserFromWallet(int walletId, String userId);
}