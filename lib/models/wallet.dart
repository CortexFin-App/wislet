import 'package:flutter/foundation.dart';
import 'package:wislet/models/user.dart';

@immutable
class WalletUser {
  const WalletUser({required this.user, required this.role});

  final User user;
  final String role;
}

class Wallet {
  Wallet({
    required this.name,
    required this.ownerUserId,
    this.id,
    this.isDefault = false,
    this.currentUserRole,
    this.members = const [],
    this.updatedAt,
    this.isDeleted = false,
  });

  factory Wallet.fromMap(Map<String, dynamic> map) {
    var parsedMembers = <WalletUser>[];
    if (map['wallet_users'] is List) {
      final membersData = map['wallet_users'] as List<dynamic>;
      parsedMembers = membersData
          .map((m) {
            final memberMap = m as Map<String, dynamic>;
            final userMap = memberMap['users'];
            if (userMap is Map<String, dynamic>) {
              return WalletUser(
                user: User.fromMap(userMap),
                role: memberMap['role'] as String? ?? 'viewer',
              );
            }
            return null;
          })
          .whereType<WalletUser>()
          .toList();
    }

    return Wallet(
      id: map['id'] as int?,
      name: map['name'] as String,
      ownerUserId: (map['owner_user_id'] ?? map['ownerUserId']).toString(),
      isDefault: (map['is_default'] is bool)
          ? map['is_default'] as bool
          : (map['is_default'] as int? ?? 0) == 1,
      members: parsedMembers,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      isDeleted: (map['is_deleted'] is bool)
          ? map['is_deleted'] as bool
          : (map['is_deleted'] as int? ?? 0) == 1,
    );
  }

  final int? id;
  final String name;
  final String ownerUserId;
  final bool isDefault;
  String? currentUserRole;
  List<WalletUser> members;
  final DateTime? updatedAt;
  final bool isDeleted;

  Map<String, dynamic> toMapForDb() {
    return {
      'id': id,
      'name': name,
      'owner_user_id': ownerUserId,
      'is_default': isDefault ? 1 : 0,
      'updated_at':
          updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Wallet && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
