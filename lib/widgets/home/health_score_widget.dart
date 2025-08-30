import 'package:flutter/material.dart';
import 'package:sage_wallet_reborn/providers/dashboard_provider.dart';
import 'package:sage_wallet_reborn/services/financial_health_service.dart';

class HealthScoreWidget extends StatelessWidget {
  const HealthScoreWidget({
    required this.profile,
    required this.advice,
    super.key,
  });

  final HealthScoreProfile profile;
  final AiAdvice advice;

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green.shade400;
    if (score >= 50) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = _getScoreColor(profile.score);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: profile.score / 100,
                        strokeWidth: 6,
                        backgroundColor:
                            scoreColor.withAlpha((255 * 0.2).round()),
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      ),
                    ),
                    Text(
                      profile.score.toString(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI-Р Р°РґРЅРёРє',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        advice.title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(advice.positive, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              advice.suggestion,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
