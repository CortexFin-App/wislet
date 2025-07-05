import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/user.dart' as FinUser;
import '../user_repository.dart';

class SupabaseUserRepositoryImpl implements UserRepository {
  final SupabaseClient _client;
  SupabaseUserRepositoryImpl(this._client);

  @override
  Future<List<FinUser.User>> getUsersForWallet(int walletId) async {
    final response = await _client
        .from('wallet_users')
        .select('users!inner(*)')
        .eq('wallet_id', walletId);

    return (response as List)
        .map((data) => FinUser.User.fromMap(data['users']))
        .toList();
  }

  @override
  Future<FinUser.User?> getUser(String id) async {
    final response = await _client.from('users').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return FinUser.User.fromMap(response);
  }

  @override
  Future<int> createDefaultUser() {
    throw UnimplementedError('createDefaultUser is a local-only operation.');
  }

  @override
  Future<List<FinUser.User>> getAllUsers() {
    throw UnimplementedError('getAllUsers is not a client feature.');
  }

  @override
  Future<int> addUserToWallet(int walletId, String userId, String role) {
    throw UnimplementedError('This is handled by invitations.');
  }

  @override
  Future<int> removeUserFromWallet(int walletId, String userId) {
    throw UnimplementedError('This is handled by WalletRepository.');
  }

  @override
  Future<int> updateUserRoleInWallet(
      int walletId, String userId, String newRole) {
    throw UnimplementedError('This is handled by WalletRepository.');
  }
}