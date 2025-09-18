import 'package:wislet/models/user.dart';

abstract class UserRepository {
  Future<int> createDefaultUser();

  Future<List<User>> getAllUsers();

  Future<List<User>> getUsersForWallet(int walletId);

  Future<int> addUserToWallet(int walletId, String userId, String role);

  Future<int> removeUserFromWallet(int walletId, String userId);

  Future<int> updateUserRoleInWallet(
    int walletId,
    String userId,
    String newRole,
  );

  Future<User?> getUser(String id);
}
