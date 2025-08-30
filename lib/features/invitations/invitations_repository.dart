import 'package:supabase_flutter/supabase_flutter.dart';

class InvitationsRepository {
  InvitationsRepository(this.client);
  final SupabaseClient client;

  Future<String> generateInvitation(int walletId) async {
    final res = await client.functions
        .invoke('create-invite', body: {'wallet_id': walletId});
    final data = res.data as Map<String, dynamic>;
    return data['token'] as String;
  }

  Future<void> acceptInvitation(String token) async {
    await client.functions.invoke('accept-invite', body: {'token': token});
  }
}
