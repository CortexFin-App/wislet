import 'package:wislet/models/transaction_view_data.dart';

typedef TransactionGroup = ({DateTime date, List<TransactionViewData> items});

List<TransactionGroup> groupTransactionsByDate(
    List<TransactionViewData> transactions,
    ) {
  final map = <DateTime, List<TransactionViewData>>{};
  for (final tx in transactions) {
    final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
    map.putIfAbsent(day, () => []).add(tx);
  }
  final sorted = map.entries.toList()
    ..sort((a, b) => b.key.compareTo(a.key));
  return sorted.map((e) => (date: e.key, items: e.value)).toList();
}
