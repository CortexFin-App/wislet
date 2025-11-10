import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wislet/models/currency_model.dart';
import 'package:wislet/models/financial_goal.dart';

class MainGoalCard extends StatelessWidget {
  const MainGoalCard({required this.goal, super.key});
  final FinancialGoal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double progress = 0;
    if (goal.originalTargetAmount > 0) {
      progress = (goal.originalCurrentAmount / goal.originalTargetAmount)
          .clamp(0.0, 1.0);
    }

    final goalCurrencyDetails = appCurrencies.firstWhere(
      (c) => c.code == goal.currencyCode,
      orElse: () => Currency(
        code: goal.currencyCode,
        symbol: goal.currencyCode,
        name: '',
        locale: 'uk_UA',
      ),
    );
    final currencyFormatter = NumberFormat.currency(
      locale: goalCurrencyDetails.locale,
      symbol: goalCurrencyDetails.symbol,
      decimalDigits: 0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_outlined, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Головна ціль',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              goal.name,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currencyFormatter.format(goal.originalCurrentAmount),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currencyFormatter.format(goal.originalTargetAmount),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor:
                  theme.colorScheme.primary.withAlpha((255 * 0.2).round()),
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
