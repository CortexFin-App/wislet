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
        final createdTransaction = await Navigator.push<fin_transaction.Transaction>(
          context,
          MaterialPageRoute(builder: (_) => const AddEditTransactionScreen(isFirstTransaction: true)),
        );
        if (createdTransaction != null && mounted) {
          _createdTransaction = createdTransaction;
          _updateStep(OnboardingStep.createBudget);
        }
        break;
      case OnboardingStep.createBudget:
        final categoryId = _createdTransaction?.categoryId;
        if (categoryId != null) {
          final budgetCreated = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => AddEditBudgetScreen(isFirstBudgetForCategory: categoryId),
          );
          if (budgetCreated == true && mounted) {
            _updateStep(OnboardingStep.finished);
          }
        }
        break;
      case OnboardingStep.finished:
        widget.onFinished();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}