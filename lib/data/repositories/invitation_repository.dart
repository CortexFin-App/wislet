import '../../models/invitation_model.dart';

enum InvitationStatus { accepted, declined }

abstract class InvitationRepository {
  Future<String> generateInvitation(int walletId);
  Future<void> acceptInvitation(String invitationToken);
  Future<List<Invitation>> getMyPendingInvitations();
  Future<void> respondToInvitation(String invitationId, InvitationStatus status);
}