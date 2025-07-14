import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_palette.dart';
import 'onboarding_page_widget.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _onboardingData = [
    {
      'icon': Icons.account_balance_wallet_outlined,
      'title': 'Ласкаво просимо до Sage Wallet!',
      'description': 'Ваш персональний помічник для легкого та ефективного управління фінансами.',
    },
    {
      'icon': Icons.track_changes_outlined,
      'title': 'Відстежуйте Кожну Копійку',
      'description': 'Легко додавайте доходи та витрати, щоб завжди знати, куди йдуть ваші гроші.',
    },
    {
      'icon': Icons.auto_graph_outlined,
      'title': 'Плануйте Своє Майбутнє',
      'description': 'Створюйте бюджети, ставте фінансові цілі та спостерігайте за їх досягненням.',
    },
    {
      'icon': Icons.insights_outlined,
      'title': 'Аналізуйте та Оптимізуйте',
      'description': 'Зрозумілі звіти та графіки допоможуть вам приймати мудрі фінансові рішення.',
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return OnboardingPage(
                    icon: _onboardingData[index]['icon'] as IconData,
                    title: _onboardingData[index]['title'] as String,
                    description: _onboardingData[index]['description'] as String,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        _onboardingData.length,
                            (index) => buildDot(index, context),
                    ),
                  ),
                  _currentPage == _onboardingData.length - 1
                      ? ElevatedButton(
                          onPressed: () {
                             HapticFeedback.heavyImpact();
                             widget.onFinished();
                          },
                          child: const Text('Почати'),
                        )
                      : TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('Далі'),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDot(int index, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? AppPalette.darkPrimary : AppPalette.darkSurface,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}