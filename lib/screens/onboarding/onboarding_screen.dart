import 'package:flutter/material.dart';
import 'package:wislet/l10n/app_localizations.dart' as sw;
import 'package:wislet/utils/l10n_helpers.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});
  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final _pages = const [
    _ObPage(
      titleKey: 'onb_simple_welcome_title',
      bodyKey: 'onb_simple_welcome_body',
      icon: Icons.wallet_rounded,
    ),
    _ObPage(
      titleKey: 'onb_simple_track_title',
      bodyKey: 'onb_simple_track_body',
      icon: Icons.show_chart_rounded,
    ),
    _ObPage(
      titleKey: 'onb_simple_budget_title',
      bodyKey: 'onb_simple_budget_body',
      icon: Icons.savings_rounded,
    ),
    _ObPage(
      titleKey: 'onb_simple_secure_title',
      bodyKey: 'onb_simple_secure_body',
      icon: Icons.verified_user_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l = sw.AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onFinished,
                child: Text(l?.t('skip') ?? 'Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Row(
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                      (i) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _index
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      if (_index == _pages.length - 1) {
                        widget.onFinished();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: Text(
                      _index == _pages.length - 1
                          ? (l?.t('continue') ?? 'Continue')
                          : (l?.t('next') ?? 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObPage extends StatelessWidget {
  const _ObPage({
    required this.titleKey,
    required this.bodyKey,
    required this.icon,
  });

  final String titleKey;
  final String bodyKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l = sw.AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 96),
          const SizedBox(height: 24),
          Text(
            l?.t(titleKey) ?? titleKey,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            l?.t(bodyKey) ?? bodyKey,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
