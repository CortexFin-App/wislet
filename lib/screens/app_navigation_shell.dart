import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/wallet.dart';
import '../providers/wallet_provider.dart';
import '../widgets/scaffold/patterned_scaffold.dart';
import 'home_screen.dart';
import 'transactions_list_screen.dart';
import 'budgets/budgets_list_screen.dart';
import 'reports/reports_screen.dart';
import 'settings_screen.dart';
import 'financial_goals/financial_goals_list_screen.dart';
import 'net_worth/net_worth_screen.dart';

class AppNavigationShell extends StatefulWidget {
  const AppNavigationShell({super.key});

  @override
  State<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends State<AppNavigationShell> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    TransactionsListScreen(),
    BudgetsListScreen(),
    NetWorthScreen(),
    ReportsScreen(),
    FinancialGoalsListScreen(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      HapticFeedback.lightImpact();
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool showFab = _selectedIndex == 0;

    return PatternedScaffold(
      appBar: AppBar(
        title: const WalletSwitcherAppBarTitle(),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Дім'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              activeIcon: Icon(Icons.list_alt_rounded),
              label: 'Транзакції'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2_rounded),
              label: 'Бюджети'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_outlined),
              activeIcon: Icon(Icons.account_balance),
              label: 'Капітал'),
          BottomNavigationBarItem(
              icon: Icon(Icons.assessment_outlined),
              activeIcon: Icon(Icons.assessment_rounded),
              label: 'Звіти'),
          BottomNavigationBarItem(
              icon: Icon(Icons.flag_outlined),
              activeIcon: Icon(Icons.flag_rounded),
              label: 'Цілі'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: showFab ? const QuantumFab() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class WalletSwitcherAppBarTitle extends StatelessWidget {
  const WalletSwitcherAppBarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final currentWallet = walletProvider.currentWallet;
    final wallets = walletProvider.wallets;

    if (currentWallet == null) {
      return const Text('Гаманець Мудреця');
    }

    if (wallets.length <= 1) {
      return Text(currentWallet.name);
    }

    return PopupMenuButton<int>(
      onSelected: (walletId) {
        walletProvider.switchWallet(walletId);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              currentWallet.name,
              style: Theme.of(context).appBarTheme.titleTextStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.unfold_more_rounded,
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
          ),
        ],
      ),
      itemBuilder: (context) {
        return wallets.map((Wallet wallet) {
          return PopupMenuItem<int>(
            value: wallet.id,
            child: Text(wallet.name),
          );
        }).toList();
      },
    );
  }
}