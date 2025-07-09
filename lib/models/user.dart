class User {
  final String id;
  final String name;
  final DateTime? updatedAt;

  User({required this.id, required this.name, this.updatedAt});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'].toString(),
      name: map['name'] as String,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }
}