import 'package:sage_wallet_reborn/models/wallet.dart';
import 'package:sage_wallet_reborn/services/api_client.dart';
import 'package:sage_wallet_reborn/data/repositories/wallet_repository.dart';

class ApiWalletRepositoryImpl implements WalletRepository {
  final ApiClient _apiClient;
  ApiWalletRepositoryImpl(this._apiClient);

  @override
  Future<List<Wallet>> getAllWallets() async {
    final responseData = await _apiClient.get('/wallets') as List;
    return responseData.map((data) => Wallet.fromMap(data)).toList();
  }

  @override
  Future<int> createWallet(
      {required String name, required String ownerUserId, bool isDefault = false}) async {
    final responseData = await _apiClient.post(
      '/wallets',
      body: {'name': name, 'is_default': isDefault, 'owner_user_id': ownerUserId},
    );
    return responseData['id'] as int;
  }

  @override
  Future<Wallet?> getWallet(int id) async {
    final responseData = await _apiClient.get('/wallets/$id');
    if (responseData == null) return null;
    return Wallet.fromMap(responseData);
  }

  @override
  Future<int> updateWallet(Wallet wallet) async {
    final responseData = await _apiClient.put(
      '/wallets/${wallet.id}',
      body: wallet.toMapForApi(),
    );
    return responseData['id'] as int;
  }

  @override
  Future<int> deleteWallet(int walletId) async {
    await _apiClient.delete('/wallets/$walletId');
    return walletId;
  }

  @override
  Future<void> changeUserRole(int walletId, String userId, String newRole) async {
    await _apiClient.put('/wallets/$walletId/members', body: {
      'user_id': userId,
      'role': newRole,
    });
  }

  @override
  Future<void> removeUserFromWallet(int walletId, String userId) async {
    await _apiClient.delete(
      '/wallets/$walletId/members',
      body: {'user_id': userId},
    );
  }

  @override
  Future<void> createInitialWallet() {
    throw UnimplementedError(
        'createInitialWallet is a local-only operation and should not be called in API mode.');
  }
}