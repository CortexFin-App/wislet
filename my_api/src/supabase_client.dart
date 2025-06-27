import 'package:supabase/supabase.dart';

extension SupabaseX on SupabaseClient {
  Future<String?> getUserRole(String userId, int walletId) async {
    try {
      final response = await from('wallet_users')
          .select('role')
          .eq('user_id', userId)
          .eq('wallet_id', walletId)
          .single();
      return response['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isUserMember(String userId, int walletId) async {
    final role = await getUserRole(userId, walletId);
    return role != null;
  }

  Future<bool> canUserEdit(String userId, int walletId) async {
    final role = await getUserRole(userId, walletId);
    return role == 'owner' || role == 'editor';
  }

  Future<bool> isUserOwner(String userId, int walletId) async {
    final role = await getUserRole(userId, walletId);
    return role == 'owner';
  }
}