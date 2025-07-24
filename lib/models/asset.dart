class Asset {
  final int? id;
  final String name;
  final String type;
  final double value;
  final String currencyCode;
  final DateTime? updatedAt;
  final bool isDeleted;

  Asset({
    this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.currencyCode,
    this.updatedAt,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'value': value,
      'currency_code': currencyCode,
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      value: (map['value'] as num).toDouble(),
      currencyCode: map['currency_code'] as String,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      isDeleted: (map['is_deleted'] is bool) ? map['is_deleted'] : ((map['is_deleted'] as int? ?? 0) == 1),
    );
  }
}