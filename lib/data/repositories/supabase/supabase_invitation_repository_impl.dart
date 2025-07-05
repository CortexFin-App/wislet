import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/di/injector.dart';
import '../../../models/invitation_model.dart';
import '../../../services/api_client.dart';
import '../invitation_repository.dart';

class SupabaseInvitationRepositoryImpl implements InvitationRepository {
  final SupabaseClient _client;
  SupabaseInvitationRepositoryImpl(this._client);

  @override
  Future<String> generateInvitation(int walletId) async {
    try {
      final response = await _client.functions.invoke(
        'create-invite',
        body: {'wallet_id': walletId},
      );
      if (response.status != 200) {
        throw ApiException(
          message: response.data['error'] ?? 'Failed to create invite token',
          statusCode: response.status!,
        );
      }
      return response.data['invite_token'] as String;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> acceptInvitation(String token) async {
    throw UnimplementedError('acceptInvitation has not been implemented yet.');
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