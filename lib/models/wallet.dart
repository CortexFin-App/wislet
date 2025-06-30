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

  Wallet({
    this.id,
    required this.name,
    required this.ownerUserId,
    this.isDefault = false,
    this.currentUserRole,
    this.members = const [],
  });

  Map<String, dynamic> toMapForDb() {
    return {
      'id': id,
      'name': name,
      'ownerUserId': ownerUserId,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  Map<String, dynamic> toMapForApi() {
    return {
      'id': id,
      'name': name,
      'owner_user_id': ownerUserId,
      'is_default': isDefault,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    final List membersList = map['members'] as List? ?? [];
    return Wallet(
      id: map['id'] as int?,
      name: map['name'] as String,
      ownerUserId: (map['owner_user_id'] ?? map['ownerUserId']).toString(),
      isDefault: (map['is_default'] is bool)
          ? map['is_default']
          : ((map['isDefault'] as int? ?? 0) == 1),
      members: membersList.map((m) {
        final userMap = m['user'] as Map<String, dynamic>?;
        if (userMap == null) {
          return WalletUser(user: User(id: '-1', name: 'Unknown'), role: m['role']);
        }
        return WalletUser(
          user: User.fromMap(userMap),
          role: m['role'],
        );
      }).toList(),
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