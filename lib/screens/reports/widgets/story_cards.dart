import 'package:flutter/material.dart';
import '../../../models/financial_story.dart';
import '../../../utils/app_colors.dart';

class TopExpenseStoryCard extends StatelessWidget {
  final TopExpensesStory story;
  const TopExpenseStoryCard({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return _StoryCardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Куди пішли гроші ${story.period}?", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...story.topExpenses.map((item) => _ExpenseBar(item: item)),
        ],
      ),
    );
  }
}

class _ExpenseBar extends StatelessWidget {
  final ExpenseItem item;
  const _ExpenseBar({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(item.icon, color: item.color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.categoryName, style: const TextStyle(color: AppColors.primaryText)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: item.percentage / 100,
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(item.color),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text("${item.percentage.toStringAsFixed(0)}%", style: TextStyle(color: item.color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}


class ComparisonStoryCard extends StatelessWidget {
  final ComparisonStory story;
  const ComparisonStoryCard({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    final color = story.isPositiveChange ? AppColors.sphereGreen : AppColors.sphereRed;
    final icon = story.isPositiveChange ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    
    return _StoryCardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(story.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(story.comparisonText, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.secondaryText)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 8),
              Text(
                "(${story.changePercentage.toStringAsFixed(0)}%)",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              const Text("Чудова робота! 💪", style: TextStyle(color: AppColors.primaryText)),
            ],
          )
        ],
      ),
    );
  }
}

class AiTipStoryCard extends StatelessWidget {
  final AiTipStory story;
  const AiTipStoryCard({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return _StoryCardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             children: [
               const Icon(Icons.lightbulb_outline, color: AppColors.sphereYellow),
               const SizedBox(width: 8),
               Text(story.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
             ],
           ),
          const SizedBox(height: 16),
          Text(story.content, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.secondaryText, height: 1.5)),
        ],
      ),
    );
  }
}

class MostExpensiveDayStoryCard extends StatelessWidget {
    final MostExpensiveDayStory story;
    const MostExpensiveDayStoryCard({super.key, required this.story});
    
    @override
    Widget build(BuildContext context) {
        return _StoryCardBase(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(story.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text(story.content, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.secondaryText, height: 1.5)),
                ],
            ),
        );
    }
}


class _StoryCardBase extends StatelessWidget {
  final Widget child;
  const _StoryCardBase({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}