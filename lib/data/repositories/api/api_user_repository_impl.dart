import 'package:sage_wallet_reborn/models/user.dart';
import 'package:sage_wallet_reborn/services/api_client.dart';
import 'package:sage_wallet_reborn/data/repositories/user_repository.dart';

class ApiUserRepositoryImpl implements UserRepository {
  final ApiClient _apiClient;
  ApiUserRepositoryImpl(this._apiClient);

  @override
  Future<int> createDefaultUser() {
    throw UnimplementedError(
        'Default user creation is a local-only concept.');
  }

  @override
  Future<List<User>> getUsersForWallet(int walletId) async {
    final responseData =
        await _apiClient.get('/wallets/$walletId/users') as List;
    return responseData.map((data) => User.fromMap(data)).toList();
  }

  @override
  Future<List<User>> getAllUsers() {
    throw UnimplementedError('Get ALL users is not a client feature.');
  }

  @override
  Future<int> addUserToWallet(int walletId, String userId, String role) {
    throw UnimplementedError();
  }

  @override
  Future<int> removeUserFromWallet(int walletId, String userId) {
    throw UnimplementedError();
  }

  @override
  Future<int> updateUserRoleInWallet(
      int walletId, String userId, String newRole) {
    throw UnimplementedError();
  }

  @override
  Future<User?> getUser(String id) {
    throw UnimplementedError();
  }
}