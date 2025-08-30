import 'package:sage_wallet_reborn/models/transaction.dart';

enum Frequency { daily, weekly, monthly, yearly }

class RepeatingTransaction {
  RepeatingTransaction({
    required this.description,
    required this.originalAmount,
    required this.originalCurrencyCode,
    required this.categoryId,
    required this.type,
    required this.frequency,
    required this.startDate,
    required this.nextDueDate,
    this.id,
    this.interval = 1,
    this.endDate,
    this.occurrences,
    this.generatedOccurrencesCount = 0,
    this.isActive = true,
    this.weekDays,
    this.monthDay,
    this.yearMonth,
    this.yearDay,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory RepeatingTransaction.fromMap(Map<String, dynamic> map) {
    return RepeatingTransaction(
      id: map['id'] as int?,
      description: map['description'] as String,
      originalAmount: (map['original_amount'] as num).toDouble(),
      originalCurrencyCode: map['original_currency_code'] as String,
      categoryId: map['category_id'] as int,
      type: TransactionType.values.byName(map['type'] as String),
      frequency: Frequency.values.byName(map['frequency'] as String),
      interval: map['interval'] as int? ?? 1,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      occurrences: map['occurrences'] as int?,
      generatedOccurrencesCount:
          map['generated_occurrences_count'] as int? ?? 0,
      nextDueDate: DateTime.parse(map['next_due_date'] as String),
      isActive: (map['is_active'] is bool)
          ? map['is_active'] as bool
          : (map['is_active'] as int? ?? 1) == 1,
      weekDays:
          (map['week_days'] as String?)?.split(',').map(int.parse).toList(),
      monthDay: map['month_day'] as String?,
      yearMonth: map['year_month'] as int?,
      yearDay: map['year_day'] as int?,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      isDeleted: (map['is_deleted'] is bool)
          ? map['is_deleted'] as bool
          : (map['is_deleted'] as int? ?? 0) == 1,
    );
  }
  final int? id;
  final String description;
  final double originalAmount;
  final String originalCurrencyCode;
  final int categoryId;
  final TransactionType type;
  final Frequency frequency;
  final int interval;
  final DateTime startDate;
  final DateTime? endDate;
  final int? occurrences;
  int? generatedOccurrencesCount;
  DateTime nextDueDate;
  bool isActive;
  final List<int>? weekDays;
  final String? monthDay;
  final int? yearMonth;
  final int? yearDay;
  final DateTime? updatedAt;
  final bool isDeleted;

  static DateTime calculateNextDueDate(
    DateTime lastDueDate,
    Frequency frequency, {
    int interval = 1,
  }) {
    switch (frequency) {
      case Frequency.daily:
        return lastDueDate.add(Duration(days: interval));
      case Frequency.weekly:
        return lastDueDate.add(Duration(days: 7 * interval));
      case Frequency.monthly:
        return DateTime(
          lastDueDate.year,
          lastDueDate.month + interval,
          lastDueDate.day,
        );
      case Frequency.yearly:
        return DateTime(
          lastDueDate.year + interval,
          lastDueDate.month,
          lastDueDate.day,
        );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'description': description,
      'original_amount': originalAmount,
      'original_currency_code': originalCurrencyCode,
      'category_id': categoryId,
      'type': type.name,
      'frequency': frequency.name,
      'interval': interval,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'occurrences': occurrences,
      'generated_occurrences_count': generatedOccurrencesCount,
      'next_due_date': nextDueDate.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'week_days': weekDays?.join(','),
      'month_day': monthDay,
      'year_month': yearMonth,
      'year_day': yearDay,
      'updated_at':
          updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }
}

String frequencyToString(Frequency frequency) {
  switch (frequency) {
    case Frequency.daily:
      return 'Р©РѕРґРЅСЏ';
    case Frequency.weekly:
      return 'Р©РѕС‚РёР¶РЅСЏ';
    case Frequency.monthly:
      return 'Р©РѕРјС–СЃСЏС†СЏ';
    case Frequency.yearly:
      return 'Р©РѕСЂРѕРєСѓ';
  }
}
