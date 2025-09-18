import 'package:wislet/data/repositories/invitation_repository.dart';
import 'package:wislet/models/invitation_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseInvitationRepositoryImpl implements InvitationRepository {
  SupabaseInvitationRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<String> generateInvitation(int walletId) async {
    final response = await _client.functions.invoke(
      'create-invite',
      body: {'wallet_id': walletId},
    );
    if (response.status != 200) {
      final map = response.data as Map<String, dynamic>?;
      throw Exception(map?['error'] ?? 'Failed to create invite token');
    }
    final map = response.data as Map<String, dynamic>?;
    final token = (map?['token'] ?? map?['invite_token']) as String?;
    if (token == null || token.isEmpty) {
      throw Exception('No invite token');
    }
    return token;
  }

  @override
  Future<void> acceptInvitation(String token) async {
    final response = await _client.functions.invoke(
      'accept-invite',
      body: {'token': token},
    );
    if (response.status != 200) {
      final err = response.data?.toString() ?? 'accept failed';
      if (err.contains('duplicate key') || err.contains('23505')) return;
      throw Exception(err);
    }
  }

  @override
  Future<List<Invitation>> getMyPendingInvitations() async {
    return [];
  }

  @override
  Future<void> respondToInvitation(
    String invitationId,
    InvitationStatus status,
  ) async {
    throw UnimplementedError(
      'respondToInvitation has not been implemented yet.',
    );
  }
}
