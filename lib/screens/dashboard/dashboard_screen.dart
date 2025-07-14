import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/app_colors.dart';
import '../add_transaction/add_transaction_sheet.dart';
import 'widgets/financial_pulse_sphere.dart';
import 'widgets/pulse_details_view.dart';
import '../../providers/wallet_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       final walletProvider = context.read<WalletProvider>();
       if(walletProvider.currentWallet != null) {
          context.read<DashboardProvider>().fetchFinancialHealth(walletProvider.currentWallet!.id!);
       }
       walletProvider.addListener(_onWalletChanged);
    });
  }

  @override
  void dispose() {
    context.read<WalletProvider>().removeListener(_onWalletChanged);
    super.dispose();
  }

  void _onWalletChanged() {
    final walletProvider = context.read<WalletProvider>();
    if(walletProvider.currentWallet != null) {
      context.read<DashboardProvider>().fetchFinancialHealth(walletProvider.currentWallet!.id!);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Consumer<DashboardProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const CircularProgressIndicator(color: AppColors.accent);
            }
            return GestureDetector(
              onLongPressStart: (_) => provider.toggleDetailsVisibility(true),
              onLongPressEnd: (_) => provider.toggleDetailsVisibility(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: provider.isDetailsVisible ? 300 : 250,
                height: provider.isDetailsVisible ? 300 : 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    FinancialPulseSphere(
                      color: provider.sphereColor,
                      pulseRate: provider.pulseRate,
                    ),
                    PulseDetailsView(
                      health: provider.health,
                      isVisible: provider.isDetailsVisible,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AddTransactionSheet(),
          ).then((transactionAdded) {
            if(transactionAdded == true) {
               _onWalletChanged();
            }
          });
        },
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}