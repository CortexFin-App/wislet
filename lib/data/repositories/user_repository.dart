import '../../models/user.dart';

abstract class UserRepository {
  Future<int> createDefaultUser();
  Future<List<User>> getAllUsers();
  Future<List<User>> getUsersForWallet(int walletId);
  Future<int> addUserToWallet(int walletId, int userId, String role);
  Future<int> removeUserFromWallet(int walletId, int userId);
  Future<int> updateUserRoleInWallet(int walletId, int userId, String newRole);
  Future<User?> getUser(int id);
}