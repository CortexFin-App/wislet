enum DebtLoanType { debt, loan }

class DebtLoan {
  final int? id;
  final int walletId;
  final DebtLoanType type;
  final String personName;
  final String? description;
  final double originalAmount;
  final String currencyCode;
  final double amountInBaseCurrency;
  final DateTime creationDate;
  final DateTime? dueDate;
  bool isSettled;
  final DateTime? updatedAt;
  final bool isDeleted;

  DebtLoan({
    this.id,
    required this.walletId,
    required this.type,
    required this.personName,
    this.description,
    required this.originalAmount,
    required this.currencyCode,
    required this.amountInBaseCurrency,
    required this.creationDate,
    this.dueDate,
    this.isSettled = false,
    this.updatedAt,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'wallet_id': walletId,
      'type': type.name,
      'person_name': personName,
      'description': description,
      'original_amount': originalAmount,
      'currency_code': currencyCode,
      'amount_in_base_currency': amountInBaseCurrency,
      'creation_date': creationDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'is_settled': isSettled ? 1 : 0,
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory DebtLoan.fromMap(Map<String, dynamic> map) {
    return DebtLoan(
      id: map['id'] as int?,
      walletId: map['wallet_id'] as int,
      type: DebtLoanType.values.byName(map['type']),
      personName: map['person_name'] as String,
      description: map['description'] as String?,
      originalAmount: (map['original_amount'] as num).toDouble(),
      currencyCode: map['currency_code'] as String,
      amountInBaseCurrency: (map['amount_in_base_currency'] as num).toDouble(),
      creationDate: DateTime.parse(map['creation_date'] as String),
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      isSettled: (map['is_settled'] is bool) ? map['is_settled'] : ((map['is_settled'] as int? ?? 0) == 1),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      isDeleted: (map['is_deleted'] is bool) ? map['is_deleted'] : ((map['is_deleted'] as int? ?? 0) == 1),
    );
  }
}