import '../../../services/api_client.dart';
import '../invitation_repository.dart';
import '../../../models/invitation_model.dart';

class ApiInvitationRepositoryImpl implements InvitationRepository {
  final ApiClient _apiClient;
  ApiInvitationRepositoryImpl(this._apiClient);

  @override
  Future<String> generateInvitation(int walletId) async {
    final response =
        await _apiClient.post('/invitations', body: {'wallet_id': walletId});
    return response['token'] as String;
  }

  @override
  Future<void> acceptInvitation(String token) async {
    await _apiClient.put('/invitations/$token', body: {});
  }

  @override
  Future<List<Invitation>> getMyPendingInvitations() async {
    final responseData = await _apiClient.get('/invitations') as List;
    return responseData.map((data) => Invitation.fromMap(data)).toList();
  }

  @override
  Future<void> respondToInvitation(
      String invitationId, InvitationStatus status) async {
    await _apiClient
        .put('/invitations/$invitationId', body: {'status': status.name});
  }
}