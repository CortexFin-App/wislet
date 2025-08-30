import 'package:supabase_flutter/supabase_flutter.dart';

extension SupabaseRoleExtensions on SupabaseClient {
  Future<String?> _getUserRole(String userId, int walletId) async {
    try {
      final response = await from('wallet_users')
          .select('role')
          .eq('user_id', userId)
          .eq('wallet_id', walletId)
          .single();
      return response['role'] as String?;
    } on Exception {
      return null;
    }
  }

  Future<bool> isUserOwner(String userId, int walletId) async {
    final role = await _getUserRole(userId, walletId);
    return role == 'owner';
  }

  Future<bool> canUserEdit(String userId, int walletId) async {
    final role = await _getUserRole(userId, walletId);
    return role == 'owner' || role == 'editor';
  }

  Future<bool> isUserMember(String userId, int walletId) async {
    final role = await _getUserRole(userId, walletId);
    return role != null;
  }
}
