class User {
  User({required this.id, required this.name, this.email, this.updatedAt});

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'].toString(),
      name: map['username'] as String? ??
          map['name'] as String? ??
          'РљРѕСЂРёСЃС‚СѓРІР°С‡',
      email: map['email'] as String?,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
  final String id;
  final String name;
  final String? email;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': name,
      'email': email,
      'updated_at':
          updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }
}
