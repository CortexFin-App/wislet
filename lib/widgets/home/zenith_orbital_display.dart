import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wislet/providers/dashboard_provider.dart';
import 'package:wislet/widgets/home/orbital_painter.dart';

class ZenithOrbitalDisplay extends StatefulWidget {
  const ZenithOrbitalDisplay({super.key});

  @override
  State<ZenithOrbitalDisplay> createState() => _ZenithOrbitalDisplayState();
}

class _ZenithOrbitalDisplayState extends State<ZenithOrbitalDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int? _activeIndex;
  String _displayText = '';
  Color _displayTextColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onCategoryTap(int index) {
    setState(() {
      _activeIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final currencyFormat =
        NumberFormat.currency(locale: 'uk_UA', symbol: 'в‚ґ', decimalDigits: 0);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final goalProgress = (provider.mainGoal?.originalCurrentAmount ?? 0) /
        (provider.mainGoal?.originalTargetAmount ?? 1);

    if (_activeIndex == null ||
        _activeIndex == -1 ||
        _activeIndex! >= provider.topCategories.length) {
      _displayText = currencyFormat.format(provider.health.balance);
      _displayTextColor = Theme.of(context).colorScheme.onSurface;
    } else {
      final category = provider.topCategories[_activeIndex!];
      _displayText = category.name;
      _displayTextColor = category.color;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: OrbitalPainter(
            repaint: _controller,
            balance: provider.health.balance,
            categories: provider.topCategories,
            goalProgress: goalProgress.isNaN || goalProgress.isInfinite
                ? 0
                : goalProgress,
            activeCategoryIndex: _activeIndex,
            onCategoryTap: _onCategoryTap,
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: Text(
                _displayText,
                key: ValueKey<String>(_displayText),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _displayTextColor,
                  fontSize:
                      _activeIndex == null || _activeIndex == -1 ? 48 : 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 20,
                      color: _displayTextColor.withAlpha(128),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
