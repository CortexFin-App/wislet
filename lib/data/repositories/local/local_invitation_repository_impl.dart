import '../../../models/invitation_model.dart';
import '../invitation_repository.dart';

class LocalInvitationRepositoryImpl implements InvitationRepository {
  @override
  Future<String> generateInvitation(int walletId) async {
    throw UnimplementedError('Local invitations are not supported.');
  }

  @override
  Future<void> acceptInvitation(String invitationId) async {
    throw UnimplementedError('Local invitations are not supported.');
  }

  @override
  Future<List<Invitation>> getMyPendingInvitations() async {
    return [];
  }

  @override
  Future<void> respondToInvitation(
      String invitationId, InvitationStatus status) async {
    throw UnimplementedError('Local invitations are not supported.');
  }
}