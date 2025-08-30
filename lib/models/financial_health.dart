class FinancialHealth {
  FinancialHealth({
    required this.income,
    required this.expenses,
    required this.balance,
    required this.dailyBalance,
  });

  factory FinancialHealth.initial() {
    return FinancialHealth(income: 0, expenses: 0, balance: 0, dailyBalance: 0);
  }

  final double income;
  final double expenses;
  final double balance;
  final double dailyBalance;
}
