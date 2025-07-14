import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/financial_health.dart';
import '../../../utils/app_colors.dart';

class PulseDetailsView extends StatelessWidget {
  final FinancialHealth health;
  final bool isVisible;

  const PulseDetailsView({
    super.key,
    required this.health,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'uk_UA', symbol: '₴', decimalDigits: 2);
    
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isVisible ? 1.0 : 0.0,
      child: IgnorePointer(
        ignoring: !isVisible,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDetailRow(
              context,
              'Доходи',
              currencyFormat.format(health.income),
              AppColors.sphereGreen,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              'Витрати',
              currencyFormat.format(health.expenses),
              AppColors.sphereRed,
            ),
            const Divider(
              color: AppColors.secondaryText,
              height: 24,
              thickness: 0.5,
              indent: 40,
              endIndent: 40,
            ),
            _buildDetailRow(
              context,
              'Залишок',
              currencyFormat.format(health.balance),
              AppColors.primaryText,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: valueColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}