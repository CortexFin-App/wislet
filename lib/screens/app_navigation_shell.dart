import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'transactions_list_screen.dart';
import 'budgets/budgets_list_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'transactions/add_edit_transaction_screen.dart';
import 'budgets/add_edit_budget_screen.dart';
import 'financial_goals/financial_goals_list_screen.dart';
import 'financial_goals/add_edit_financial_goal_screen.dart';
import 'transactions/create_transfer_screen.dart';
import '../utils/fade_page_route.dart';
import '../providers/wallet_provider.dart';
import '../models/wallet.dart';

class AppNavigationShell extends StatefulWidget {
  const AppNavigationShell({super.key});

  @override
  State<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends State<AppNavigationShell> {
  int _selectedIndex = 0;
  int? _previousWalletId;

  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>();
  final GlobalKey<TransactionsListScreenState> _transactionsListKey = GlobalKey<TransactionsListScreenState>();
  final GlobalKey<BudgetsListScreenState> _budgetsListKey = GlobalKey<BudgetsListScreenState>();
  final GlobalKey<FinancialGoalsListScreenState> _goalsListKey = GlobalKey<FinancialGoalsListScreenState>();
  
  late final List<Widget> _widgetOptions;

  bool _isTransactionSearchActive = false;
  final TextEditingController _transactionSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      HomeScreen(key: _homeScreenKey),
      TransactionsListScreen(key: _transactionsListKey),
      BudgetsListScreen(key: _budgetsListKey),
      const ReportsScreen(),
      FinancialGoalsListScreen(key: _goalsListKey),
    ];

    _transactionSearchController.addListener(() {
      if (_transactionsListKey.currentState != null && _transactionsListKey.currentState!.mounted) {
        _transactionsListKey.currentState!.performSearchQuery(_transactionSearchController.text);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
        _previousWalletId = context.read<WalletProvider>().currentWallet?.id;
    });
  }

  @override
  void dispose() {
    _transactionSearchController.dispose();
    super.dispose();
  }

  void _refreshCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        _homeScreenKey.currentState?.refreshData();
        break;
      case 1:
        _transactionsListKey.currentState?.refreshData();
        break;
      case 2:
        _budgetsListKey.currentState?.refreshData();
        break;
      case 4:
        _goalsListKey.currentState?.refreshData();
        break;
    }
  }

  void _onItemTapped(int index) {
    if (!mounted) return;
    if (_selectedIndex == 1 && index != 1 && _isTransactionSearchActive) {
      if (mounted) {
        setState(() {
          _isTransactionSearchActive = false;
        });
      }
      if (_transactionsListKey.currentState != null && _transactionsListKey.currentState!.mounted) {
        _transactionsListKey.currentState!.toggleSearchMode(false);
      }
      _transactionSearchController.clear();
    }
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildWalletSwitcher(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final currentWallet = walletProvider.currentWallet;
    final wallets = walletProvider.wallets;

    if (currentWallet == null) {
      return const SizedBox.shrink();
    }
    return DropdownButton<int>(
      value: currentWallet.id,
      underline: const SizedBox.shrink(),
      icon: Icon(Icons.expand_more, color: Theme.of(context).appBarTheme.foregroundColor),
      onChanged: (int? newWalletId) {
        if (newWalletId != null) {
          context.read<WalletProvider>().switchWallet(newWalletId);
        }
      },
      items: wallets.map<DropdownMenuItem<int>>((Wallet wallet) {
        return DropdownMenuItem<int>(
          value: wallet.id,
          child: Text(
            wallet.name,
            style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface
                ),
          ),
        );
      }).toList(),
    );
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    List<Widget> tabSpecificActions = [];
    if (_selectedIndex == 1 && _isTransactionSearchActive) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (mounted) {
              setState(() {
                _isTransactionSearchActive = false;
              });
            }
            if (_transactionsListKey.currentState != null && _transactionsListKey.currentState!.mounted) {
              _transactionsListKey.currentState!.toggleSearchMode(false);
            }
            _transactionSearchController.clear();
          },
        ),
        title: TextField(
          controller: _transactionSearchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Пошук за описом, категорією...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor?.withAlpha(150)),
          ),
          style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor, fontSize: 18),
        ),
        actions: [
          if (_transactionSearchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _transactionSearchController.clear();
                  if (_transactionsListKey.currentState != null && _transactionsListKey.currentState!.mounted) {
                      _transactionsListKey.currentState!.performSearchQuery('');
                  }
              },
            ),
        ],
      );
    }

    switch (_selectedIndex) {
      case 1:
        tabSpecificActions = [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Пошук',
            onPressed: () {
              if (mounted) {
                setState(() {
                  _isTransactionSearchActive = true;
                });
              }
              if (_transactionsListKey.currentState != null && _transactionsListKey.currentState!.mounted) {
                _transactionsListKey.currentState!.toggleSearchMode(true);
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: (_transactionsListKey.currentState?.areFiltersActive() ?? false)
                  ? Theme.of(context).colorScheme.secondary
                  : null,
            ),
            tooltip: 'Фільтри',
            onPressed: () {
              if (_transactionsListKey.currentState != null && _transactionsListKey.currentState!.mounted) {
                _transactionsListKey.currentState!.showFilterDialog();
              }
            },
          ),
        ];
      break;
      default:
        break;
    }

    List<Widget> finalActions = [
      ...tabSpecificActions,
      IconButton(
        icon: const Icon(Icons.settings_outlined),
        tooltip: 'Налаштування',
        onPressed: () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const SettingsScreen())
          );
        },
      ),
    ];

    return AppBar(
      title: _buildWalletSwitcher(context),
      actions: finalActions,
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    final canEdit = context.watch<WalletProvider>().canEditCurrentWallet;
    
    switch (_selectedIndex) {
      case 0:
      case 1:
        return Wrap(
          direction: Axis.horizontal,
          spacing: 16,
          children: [
            FloatingActionButton.small(
              heroTag: 'add_transfer_fab',
              onPressed: canEdit ? () async {
                final result = await Navigator.push(context, FadePageRoute(builder: (context) => const CreateTransferScreen()));
                if (result == true && mounted) {
                  _refreshCurrentScreen();
                }
              } : null,
              backgroundColor: canEdit ? null : Theme.of(context).disabledColor,
              tooltip: 'Новий переказ',
              child: const Icon(Icons.swap_horiz),
            ),
            FloatingActionButton.extended(
              heroTag: 'add_transaction_fab',
              onPressed: canEdit ? () async {
                final result = await Navigator.push(context, FadePageRoute(builder: (context) => const AddEditTransactionScreen()));
                if (result == true && mounted) {
                  _refreshCurrentScreen();
                }
              } : null,
              backgroundColor: canEdit ? null : Theme.of(context).disabledColor,
              tooltip: 'Додати транзакцію',
              icon: const Icon(Icons.add_card_outlined),
              label: const Text("Транзакція"),
            ),
          ],
        );
      case 2:
        return FloatingActionButton.extended(
          heroTag: 'add_budget_fab',
          onPressed: canEdit ? () async {
            final result = await Navigator.push(context, FadePageRoute(builder: (context) => const AddEditBudgetScreen()));
            if (result == true && _budgetsListKey.currentState != null && _budgetsListKey.currentState!.mounted) {
              _budgetsListKey.currentState!.refreshData();
            }
          } : null,
          backgroundColor: canEdit ? null : Theme.of(context).disabledColor,
          tooltip: 'Додати Бюджет',
          icon: const Icon(Icons.add_chart_outlined),
          label: const Text("Новий бюджет"),
        );
      case 4:
         return FloatingActionButton.extended(
          heroTag: 'add_goal_fab',
          onPressed: canEdit ? () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEditFinancialGoalScreen()));
            if (result == true && _goalsListKey.currentState != null && _goalsListKey.currentState!.mounted) {
              _goalsListKey.currentState!.refreshData();
            }
          } : null,
          backgroundColor: canEdit ? null : Theme.of(context).disabledColor,
          tooltip: 'Додати Ціль',
          icon: const Icon(Icons.flag_outlined),
          label: const Text("Нова ціль"),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentWalletId = context.select((WalletProvider p) => p.currentWallet?.id);
    if (currentWalletId != null && currentWalletId != _previousWalletId) {
        _previousWalletId = currentWalletId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _refreshCurrentScreen();
        });
    }

    return Scaffold(
      appBar: _buildAppBar(context),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      floatingActionButton: _buildFloatingActionButton(context),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Дашборд',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Транзакції',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Бюджети',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment_outlined),
            activeIcon: Icon(Icons.assessment),
            label: 'Звіти',
          ),
          BottomNavigationBarItem( 
            icon: Icon(Icons.flag_outlined),
            activeIcon: Icon(Icons.flag),
            label: 'Цілі',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}