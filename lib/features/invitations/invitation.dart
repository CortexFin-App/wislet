class Invitation {
  Invitation({
    required this.id,
    required this.walletId,
    required this.token,
    required this.createdAt,
    required this.expiresAt,
    this.usedAt,
    this.usedBy,
  });
  factory Invitation.fromJson(Map<String, dynamic> j) {
    return Invitation(
      id: j['id'] as int,
      walletId: j['wallet_id'] as int,
      token: j['token'] as String,
      createdAt: DateTime.parse(j['created_at'] as String),
      expiresAt: DateTime.parse(j['expires_at'] as String),
      usedAt:
          j['used_at'] == null ? null : DateTime.parse(j['used_at'] as String),
      usedBy: j['used_by'] as String?,
    );
  }
  final int id;
  final int walletId;
  final String token;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final String? usedBy;
}
