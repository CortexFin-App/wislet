class Invitation {
  final String id;
  final int walletId;
  final String walletName;
  final String inviterName;
  final String status;

  Invitation({
    required this.id,
    required this.walletId,
    required this.walletName,
    required this.inviterName,
    required this.status,
  });

  factory Invitation.fromMap(Map<String, dynamic> map) {
    return Invitation(
      id: map['id'] as String,
      walletId: map['wallet_id'] as int,
      walletName: (map['wallet'] as Map<String, dynamic>?)?['name'] as String? ?? 'Невідомий гаманець',
      inviterName: (map['inviter'] as Map<String, dynamic>?)?['username'] as String? ?? 'Невідомий користувач',
      status: map['status'] as String,
    );
  }
}