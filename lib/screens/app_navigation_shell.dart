import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Оболонка з вкладеною навігацією на базі go_router StatefulNavigationShell.
/// ВАЖЛИВО: floatingActionButtonLocation існує лише у Scaffold.
class AppNavigationShell extends StatelessWidget {

  const AppNavigationShell({
    required this.shell, super.key,
    this.floatingActionButton,
    this.destinations = const <NavigationDestination>[
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: Icon(Icons.account_balance_wallet),
        label: 'Wallet',
      ),
      NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ],
  });
  final StatefulNavigationShell shell;
  final Widget? floatingActionButton;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) => shell.goBranch(
          index,
          initialLocation: index != shell.currentIndex,
        ),
        destinations: destinations,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      floatingActionButton: floatingActionButton ??
          FloatingActionButton(
            onPressed: () => context.go('/add'),
            child: const Icon(Icons.add),
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
