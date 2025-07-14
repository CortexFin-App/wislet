import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/financial_story.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/reports_provider.dart';
import 'widgets/story_cards.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStories();
    });
  }

  Future<void> _loadStories() async {
    if (!mounted) return;
    final walletProvider = context.read<WalletProvider>();
    final reportsProvider = context.read<ReportsProvider>();
    if (walletProvider.currentWallet?.id != null) {
      await reportsProvider.fetchStories(walletId: walletProvider.currentWallet!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsProvider = context.watch<ReportsProvider>();
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadStories,
        child: Builder(
          builder: (context) {
            if (reportsProvider.isLoading) {
              return _buildShimmerLoading();
            }
            
            if (reportsProvider.stories.isEmpty) {
              return _buildEmptyState();
            }

            final stories = reportsProvider.stories;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: stories.length,
              itemBuilder: (context, index) {
                final story = stories[index];
                switch (story.type) {
                  case StoryType.topExpenses:
                    return TopExpenseStoryCard(story: story as TopExpensesStory);
                  case StoryType.comparison:
                    return ComparisonStoryCard(story: story as ComparisonStory);
                  case StoryType.mostExpensiveDay:
                    return MostExpensiveDayStoryCard(
                        story: story as MostExpensiveDayStory);
                  case StoryType.aiTip:
                    return AiTipStoryCard(story: story as AiTipStory);
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off,
                size: 80, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 24),
            Text('Історій поки що немає',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'Додайте більше транзакцій, і ми почнемо знаходити для вас цікаві інсайти та закономірності.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainer,
      highlightColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: List.generate(
          3,
          (_) => Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}