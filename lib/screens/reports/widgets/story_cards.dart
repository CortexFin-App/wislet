import 'package:flutter/material.dart';
import 'package:sage_wallet_reborn/models/financial_story.dart';

class TopExpenseStoryCard extends StatelessWidget {
  const TopExpenseStoryCard({required this.story, super.key});
  final TopExpensesStory story;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _StoryCardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'РљСѓРґРё РїС–С€Р»Рё РіСЂРѕС€С– ${story.period}?',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...story.topExpenses.map((item) => _ExpenseBar(item: item)),
        ],
      ),
    );
  }
}

class _ExpenseBar extends StatelessWidget {
  const _ExpenseBar({required this.item});
  final ExpenseItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(item.icon, color: item.color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.categoryName,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: item.percentage / 100,
                    backgroundColor: theme.colorScheme.surfaceContainer,
                    valueColor: AlwaysStoppedAnimation<Color>(item.color),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${item.percentage.toStringAsFixed(0)}%',
            style: TextStyle(color: item.color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class ComparisonStoryCard extends StatelessWidget {
  const ComparisonStoryCard({required this.story, super.key});
  final ComparisonStory story;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        story.isPositiveChange ? Colors.green : theme.colorScheme.error;
    final icon = story.isPositiveChange
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    return _StoryCardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            story.title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            story.comparisonText,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 8),
              Text(
                '(${story.changePercentage.toStringAsFixed(0)}%)',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                'Р§СѓРґРѕРІР° СЂРѕР±РѕС‚Р°! рџ’Є',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AiTipStoryCard extends StatelessWidget {
  const AiTipStoryCard({required this.story, super.key});
  final AiTipStory story;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _StoryCardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber.shade600),
              const SizedBox(width: 8),
              Text(
                story.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            story.content,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class MostExpensiveDayStoryCard extends StatelessWidget {
  const MostExpensiveDayStoryCard({required this.story, super.key});
  final MostExpensiveDayStory story;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _StoryCardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            story.title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            story.content,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryCardBase extends StatelessWidget {
  const _StoryCardBase({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
