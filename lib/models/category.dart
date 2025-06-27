enum CategoryType { income, expense }

enum Bucket { needs, wants, savings }

Bucket stringToExpenseBucket(String? s) {
  if (s == Bucket.needs.toString()) return Bucket.needs;
  if (s == Bucket.wants.toString()) return Bucket.wants;
  if (s == Bucket.savings.toString()) return Bucket.savings;
  return Bucket.wants;
}

class Category {
  final int? id;
  final String name;
  final CategoryType type;
  final Bucket? bucket;

  Category({this.id, required this.name, required this.type, this.bucket});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'bucket': bucket?.toString(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: CategoryType.values.firstWhere((e) => e.toString() == map['type']),
      bucket: map['bucket'] != null
          ? Bucket.values.firstWhere((e) => e.toString() == map['bucket'])
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Category &&
      other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}