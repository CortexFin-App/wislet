import 'package:flutter/material.dart';
import '../../models/transaction.dart' as fin_transaction;
import '../transactions/add_edit_transaction_screen.dart';
import '../budgets/add_edit_budget_screen.dart';
import '../settings/add_edit_wallet_screen.dart';

enum OnboardingStep { createWallet, addTransaction, createBudget, finished }

class InteractiveOnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const InteractiveOnboardingScreen({super.key, required this.onFinished});

  @override
  State<InteractiveOnboardingScreen> createState() => _InteractiveOnboardingScreenState();
}

class _InteractiveOnboardingScreenState extends State<InteractiveOnboardingScreen> {
  OnboardingStep _currentStep = OnboardingStep.createWallet;
  fin_transaction.Transaction? _createdTransaction;
  bool _isIncomeTransaction = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _executeStep());
  }

  void _updateStep(OnboardingStep nextStep) {
    if (mounted) {
      setState(() {
        _currentStep = nextStep;
      });
      _executeStep();
    }
  }

  Future<void> _executeStep() async {
    switch (_currentStep) {
      case OnboardingStep.createWallet:
        final walletCreated = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AddEditWalletScreen(isFirstWallet: true),
        );
        if (walletCreated == true && mounted) {
          _updateStep(OnboardingStep.addTransaction);
        }
        break;
      case OnboardingStep.addTransaction:
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(builder: (_) => const AddEditTransactionScreen(isFirstTransaction: true, isTransferAllowed: false)),
        );
        if (result != null && result['transaction'] is fin_transaction.Transaction && mounted) {
          _createdTransaction = result['transaction'];
          _isIncomeTransaction = result['isIncome'] ?? false;
          _updateStep(OnboardingStep.createBudget);
        }
        break;
      case OnboardingStep.createBudget:
        final categoryId = _createdTransaction?.categoryId;
        if (categoryId != null && !_isIncomeTransaction) {
          final budgetCreated = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => AddEditBudgetScreen(isFirstBudgetForCategory: categoryId),
          );
          if (budgetCreated == true && mounted) {
            _updateStep(OnboardingStep.finished);
          }
        } else {
           _updateStep(OnboardingStep.finished);
        }
        break;
      case OnboardingStep.finished:
        widget.onFinished();
        break;
    }
  }

  Widget _buildStepOverlay(String title, String description) {
    return Container(
      color: Colors.black.withAlpha(178),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text(description, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            Container(color: Theme.of(context).scaffoldBackgroundColor), 
            if (_currentStep == OnboardingStep.createWallet)
              _buildStepOverlay('Крок 1: Гаманець', 'Давайте створимо ваш перший гаманець для обліку фінансів.'),
            if (_currentStep == OnboardingStep.addTransaction)
              _buildStepOverlay('Крок 2: Перша транзакція', 'Тепер додайте вашу першу транзакцію – дохід або витрату.'),
            if (_currentStep == OnboardingStep.createBudget)
              _buildStepOverlay('Крок 3: Бюджет', 'Чудово! На основі вашої витрати, давайте створимо перший бюджет, щоб контролювати ліміти.'),
          ],
        ),
      ),
    );
  }
}