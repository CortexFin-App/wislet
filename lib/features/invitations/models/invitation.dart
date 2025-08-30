class Invitation {
  const Invitation({
    required this.id,
    required this.walletId,
    required this.token,
    required this.createdAt,
    this.expiresAt,
    this.usedAt,
    this.usedBy,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'] as int,
      walletId: json['wallet_id'] as int,
      token: json['token'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      usedAt: json['used_at'] == null
          ? null
          : DateTime.parse(json['used_at'] as String),
      usedBy: json['used_by'] as String?,
    );
  }
  final int id;
  final int walletId;
  final String token;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? usedAt;
  final String? usedBy;
}
