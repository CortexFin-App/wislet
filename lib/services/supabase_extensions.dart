import 'package:supabase_flutter/supabase_flutter.dart';

extension SupabaseRoleExtensions on SupabaseClient {
  /// Internal helper to get a user's role for a specific wallet.
  Future<String?> _getUserRole(String userId, int walletId) async {
    try {
      final response = await from('wallet_users')
          .select('role')
          .eq('user_id', userId)
          .eq('wallet_id', walletId)
          .single();
      return response['role'] as String?;
    } catch (e) {
      // If no record is found or another error occurs, the user has no role.
      return null;
    }
  }

  /// Checks if the user is the owner of the wallet.
  Future<bool> isUserOwner(String userId, int walletId) async {
    final role = await _getUserRole(userId, walletId);
    return role == 'owner';
  }

  /// Checks if the user has editing rights for the wallet (owner or editor).
  Future<bool> canUserEdit(String userId, int walletId) async {
    final role = await _getUserRole(userId, walletId);
    return role == 'owner' || role == 'editor';
  }

  /// Checks if the user is any kind of member of the wallet.
  Future<bool> isUserMember(String userId, int walletId) async {
    final role = await _getUserRole(userId, walletId);
    return role != null;
  }
}