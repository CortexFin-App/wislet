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
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'walletId': walletId,
      'type': type.toString(),
      'personName': personName,
      'description': description,
      'originalAmount': originalAmount,
      'currencyCode': currencyCode,
      'amountInBaseCurrency': amountInBaseCurrency,
      'creationDate': creationDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'isSettled': isSettled ? 1 : 0,
    };
  }

  factory DebtLoan.fromMap(Map<String, dynamic> map) {
    return DebtLoan(
      id: map['id'] as int?,
      walletId: map['walletId'] as int,
      type: DebtLoanType.values.firstWhere((e) => e.toString() == map['type']),
      personName: map['personName'] as String,
      description: map['description'] as String?,
      originalAmount: (map['originalAmount'] as num).toDouble(),
      currencyCode: map['currencyCode'] as String,
      amountInBaseCurrency: (map['amountInBaseCurrency'] as num).toDouble(),
      creationDate: DateTime.parse(map['creationDate'] as String),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null,
      isSettled: (map['isSettled'] as int? ?? 0) == 1,
    );
  }
}