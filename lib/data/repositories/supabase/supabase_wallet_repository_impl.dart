import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/wallet.dart';
import '../wallet_repository.dart';

class SupabaseWalletRepositoryImpl implements WalletRepository {
  final SupabaseClient _client;
  SupabaseWalletRepositoryImpl(this._client);

  @override
  Future<List<Wallet>> getAllWallets() async {
    final response = await _client
        .from('wallets')
        .select('*, wallet_users(*, users!inner(*))');
    return (response as List).map((data) => Wallet.fromMap(data)).toList();
  }

  @override
  Future<Wallet?> getWallet(int id) async {
    final response = await _client
        .from('wallets')
        .select('*, wallet_users(*, users!inner(*))')
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Wallet.fromMap(response);
  }

  @override
  Future<int> createWallet({
    required String name,
    required String ownerUserId,
    bool isDefault = false,
  }) async {
    final response = await _client.rpc(
      'create_wallet_and_assign_owner',
      params: {'wallet_name': name, 'is_default_wallet': isDefault},
    );
    return response as int;
  }

  @override
  Future<int> updateWallet(Wallet wallet) async {
    final response = await _client
        .from('wallets')
        .update(wallet.toMapForApi())
        .eq('id', wallet.id!)
        .select()
        .single();
    return response['id'] as int;
  }

  @override
  Future<int> deleteWallet(int walletId) async {
    await _client.from('wallets').delete().eq('id', walletId);
    return walletId;
  }

  @override
  Future<void> changeUserRole(int walletId, String userId, String newRole) async {
    await _client
        .from('wallet_users')
        .update({'role': newRole})
        .eq('wallet_id', walletId)
        .eq('user_id', userId);
  }

  @override
  Future<void> removeUserFromWallet(int walletId, String userId) async {
    await _client
        .from('wallet_users')
        .delete()
        .eq('wallet_id', walletId)
        .eq('user_id', userId);
  }

  @override
  Future<void> createInitialWallet() {
    throw UnimplementedError('createInitialWallet is a local-only operation.');
  }
}