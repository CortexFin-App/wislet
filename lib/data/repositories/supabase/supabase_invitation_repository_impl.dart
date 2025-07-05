import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/invitation_model.dart';
import '../invitation_repository.dart';

class SupabaseInvitationRepositoryImpl implements InvitationRepository {
  final SupabaseClient _client;
  SupabaseInvitationRepositoryImpl(this._client);

  @override
  Future<String> generateInvitation(int walletId) async {
    final response = await _client.functions.invoke(
      'invitations',
      method: HttpMethod.post,
      body: {'wallet_id': walletId},
    );
    if (response.status != 200) {
      throw Exception(response.data?['error'] ?? 'Failed to generate invitation');
    }
    return response.data['token'] as String;
  }

  @override
  Future<void> acceptInvitation(String invitationToken) async {
    await _client.rpc('accept_invitation', params: {'p_token': invitationToken});
  }

  @override
  Future<List<Invitation>> getMyPendingInvitations() async {
    final response = await _client
      .from('invitations')
      .select('*, wallets(*), users!invitations_inviter_id_fkey(*)')
      .eq('status', 'pending');
    return (response as List).map((data) => Invitation.fromMap(data)).toList();
  }

  @override
  Future<void> respondToInvitation(String invitationId, InvitationStatus status) async {
    await _client.from('invitations').update({'status': status.name}).eq('id', invitationId);
  }
}