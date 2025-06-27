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
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'originalAmount': originalAmount,
      'originalCurrencyCode': originalCurrencyCode,
      'categoryId': categoryId,
      'type': type.toString(),
      'frequency': frequency.toString(),
      'interval': interval,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'occurrences': occurrences,
      'generatedOccurrencesCount': generatedOccurrencesCount,
      'nextDueDate': nextDueDate.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'weekDays': weekDays?.join(','),
      'monthDay': monthDay,
      'yearMonth': yearMonth,
      'yearDay': yearDay,
    };
  }

  factory RepeatingTransaction.fromMap(Map<String, dynamic> map) {
    return RepeatingTransaction(
      id: map['id'],
      description: map['description'],
      originalAmount: (map['originalAmount'] as num).toDouble(),
      originalCurrencyCode: map['originalCurrencyCode'],
      categoryId: map['categoryId'],
      type: TransactionType.values.firstWhere((e) => e.toString() == map['type']),
      frequency: Frequency.values.firstWhere((e) => e.toString() == map['frequency']),
      interval: map['interval'] ?? 1,
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      occurrences: map['occurrences'],
      generatedOccurrencesCount: map['generatedOccurrencesCount'] ?? 0,
      nextDueDate: DateTime.parse(map['nextDueDate']),
      isActive: (map['isActive'] as int) == 1,
      weekDays: (map['weekDays'] as String?)?.split(',').map(int.parse).toList(),
      monthDay: map['monthDay'],
      yearMonth: map['yearMonth'],
      yearDay: map['yearDay'],
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