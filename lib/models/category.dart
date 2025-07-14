enum CategoryType { income, expense }

enum Bucket { needs, wants, savings }

Bucket stringToExpenseBucket(String? s) {
  if (s == Bucket.needs.name) return Bucket.needs;
  if (s == Bucket.wants.name) return Bucket.wants;
  if (s == Bucket.savings.name) return Bucket.savings;
  return Bucket.wants;
}

class Category {
  final int? id;
  final String name;
  final CategoryType type;
  final Bucket? bucket;
  final DateTime? updatedAt;
  final bool isDeleted;

  Category({
    this.id,
    required this.name,
    required this.type,
    this.bucket,
    this.updatedAt,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type.name,
      'bucket': bucket?.name,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: CategoryType.values.byName(map['type']),
      bucket: map['bucket'] != null
          ? Bucket.values.byName(map['bucket'])
          : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      isDeleted: (map['is_deleted'] is bool) ? map['is_deleted'] : ((map['is_deleted'] as int? ?? 0) == 1),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}