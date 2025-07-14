import 'user.dart';

class WalletUser {
  final User user;
  final String role;
  WalletUser({required this.user, required this.role});
}

class Wallet {
  final int? id;
  final String name;
  final String ownerUserId;
  final bool isDefault;
  String? currentUserRole;
  List<WalletUser> members;
  final DateTime? updatedAt;
  final bool isDeleted;

  Wallet({
    this.id,
    required this.name,
    required this.ownerUserId,
    this.isDefault = false,
    this.currentUserRole,
    this.members = const [],
    this.updatedAt,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMapForDb() {
    return {
      'id': id,
      'name': name,
      'owner_user_id': ownerUserId,
      'is_default': isDefault ? 1 : 0,
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  Map<String, dynamic> toMapForApi() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'is_default': isDefault,
      'owner_user_id': ownerUserId,
      'is_deleted': isDeleted,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    List<WalletUser> parsedMembers = [];
    if (map['wallet_users'] is List) {
      final List membersData = map['wallet_users'];
      parsedMembers = membersData.map((m) {
        final userMap = m['users'];
        if (userMap is Map<String, dynamic>) {
           return WalletUser(
            user: User.fromMap(userMap),
            role: m['role'] as String? ?? 'viewer',
          );
        }
        return null;
      }).where((item) => item != null).cast<WalletUser>().toList();
    }
    
    return Wallet(
      id: map['id'] as int?,
      name: map['name'] as String,
      ownerUserId: (map['owner_user_id'] ?? map['ownerUserId']).toString(),
      isDefault: (map['is_default'] is bool) ? map['is_default'] : ((map['is_default'] as int? ?? 0) == 1),
      members: parsedMembers,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      isDeleted: (map['is_deleted'] is bool) ? map['is_deleted'] : ((map['is_deleted'] as int? ?? 0) == 1),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Wallet && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}