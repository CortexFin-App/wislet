import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/invitation_model.dart';
import '../invitation_repository.dart';

class SupabaseInvitationRepositoryImpl implements InvitationRepository {
  final SupabaseClient _client;
  SupabaseInvitationRepositoryImpl(this._client);

  @override
  Future<String> generateInvitation(int walletId) async {
    final response = await _client.functions.invoke(
      'create-invite',
      body: {'wallet_id': walletId},
    );
    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to create invite token');
    }
    return response.data['invite_token'] as String;
  }

  @override
  Future<void> acceptInvitation(String token) async {
    await _client.functions.invoke(
      'accept-invite',
      body: {'token': token},
    );
  }

  @override
  Future<List<Invitation>> getMyPendingInvitations() async {
    return [];
  }

  @override
  Future<void> respondToInvitation(
      String invitationId, InvitationStatus status) async {
    throw UnimplementedError('respondToInvitation has not been implemented yet.');
  }
}