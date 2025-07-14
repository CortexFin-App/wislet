import 'transaction.dart';

enum Frequency { daily, weekly, monthly, yearly }

class RepeatingTransaction {
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

  RepeatingTransaction({
    this.id,
    required this.description,
    required this.originalAmount,
    required this.originalCurrencyCode,
    required this.categoryId,
    required this.type,
    required this.frequency,
    this.interval = 1,
    required this.startDate,
    this.endDate,
    this.occurrences,
    this.generatedOccurrencesCount = 0,
    required this.nextDueDate,
    this.isActive = true,
    this.weekDays,
    this.monthDay,
    this.yearMonth,
    this.yearDay,
    this.updatedAt,
    this.isDeleted = false,
  });

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
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory RepeatingTransaction.fromMap(Map<String, dynamic> map) {
    return RepeatingTransaction(
      id: map['id'],
      description: map['description'],
      originalAmount: (map['original_amount'] as num).toDouble(),
      originalCurrencyCode: map['original_currency_code'],
      categoryId: map['category_id'],
      type: TransactionType.values.byName(map['type']),
      frequency: Frequency.values.byName(map['frequency']),
      interval: map['interval'] ?? 1,
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      occurrences: map['occurrences'],
      generatedOccurrencesCount: map['generated_occurrences_count'] ?? 0,
      nextDueDate: DateTime.parse(map['next_due_date']),
      isActive: (map['is_active'] is bool) ? map['is_active'] : ((map['is_active'] as int? ?? 1) == 1),
      weekDays: (map['week_days'] as String?)?.split(',').map(int.parse).toList(),
      monthDay: map['month_day'],
      yearMonth: map['year_month'],
      yearDay: map['year_day'],
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      isDeleted: (map['is_deleted'] is bool) ? map['is_deleted'] : ((map['is_deleted'] as int? ?? 0) == 1),
    );
  }

  static DateTime calculateNextDueDate(DateTime lastDueDate, Frequency frequency, {int interval = 1}) {
    switch (frequency) {
      case Frequency.daily:
        return lastDueDate.add(Duration(days: interval));
      case Frequency.weekly:
        return lastDueDate.add(Duration(days: 7 * interval));
      case Frequency.monthly:
        return DateTime(lastDueDate.year, lastDueDate.month + interval, lastDueDate.day);
      case Frequency.yearly:
        return DateTime(lastDueDate.year + interval, lastDueDate.month, lastDueDate.day);
    }
  }
}

String frequencyToString(Frequency frequency) {
  switch (frequency) {
    case Frequency.daily:
      return 'Щодня';
    case Frequency.weekly:
      return 'Щотижня';
    case Frequency.monthly:
      return 'Щомісяця';
    case Frequency.yearly:
      return 'Щороку';
  }
}