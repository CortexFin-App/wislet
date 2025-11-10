import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wislet/models/financial_story.dart';
import 'package:wislet/providers/reports_provider.dart';
import 'package:wislet/providers/wallet_provider.dart';
import 'package:wislet/screens/reports/widgets/story_cards.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late WalletProvider _wallet;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _wallet = context.read<WalletProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStories();
      _wallet.addListener(_onWalletChanged);
    });
  }

  @override
  void dispose() {
    _wallet.removeListener(_onWalletChanged);
    super.dispose();
  }

  void _onWalletChanged() {
    _loadStories();
  }

  Future<void> _loadStories() async {
    if (!mounted) return;
    final walletProvider = context.read<WalletProvider>();
    final reportsProvider = context.read<ReportsProvider>();
    final id = walletProvider.currentWallet?.id;
    if (id != null) {
      await reportsProvider.fetchStories(walletId: id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsProvider = context.watch<ReportsProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _loadStories,
        child: Builder(
          builder: (context) {
            if (reportsProvider.isLoading) {
              return _buildShimmerLoading(context);
            }
            if (reportsProvider.stories.isEmpty) {
              return _buildEmptyState(context);
            }
            final stories = reportsProvider.stories;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: stories.length,
              itemBuilder: (context, index) {
                final story = stories[index];
                switch (story.type) {
                  case StoryType.topExpenses:
                    return TopExpenseStoryCard(
                        story: story as TopExpensesStory,);
                  case StoryType.comparison:
                    return ComparisonStoryCard(story: story as ComparisonStory);
                  case StoryType.mostExpensiveDay:
                    return MostExpensiveDayStoryCard(
                      story: story as MostExpensiveDayStory,
                    );
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

  Widget _buildShimmerLoading(BuildContext context) {
    final base =
        Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    final highlight = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        3,
        (_) => Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: Container(
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'Історій поки що немає',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Додайте більше транзакцій, щоби отримувати цікаві інсайти та закономірності.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
