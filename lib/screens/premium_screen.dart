import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/di/injector.dart';
import '../../providers/pro_status_provider.dart';
import '../../services/billing_service.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final proStatusProvider = Provider.of<ProStatusProvider>(context);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Гаманець Мудреця Pro'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.workspace_premium,
                      size: 80, color: Colors.white.withAlpha(230)),
                  const SizedBox(height: 16),
                  Text(
                    'Розблокуйте Повний Потенціал',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Отримайте доступ до ексклюзивних функцій, щоб досягти фінансової майстерності.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge
                        ?.copyWith(color: Colors.white.withAlpha(204)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureTile(
                    context,
                    icon: Icons.auto_awesome,
                    title: 'AI-Асистент для категорій',
                    subtitle:
                        'Дозвольте штучному інтелекту автоматично визначати категорії ваших транзакцій.',
                  ),
                  _buildFeatureTile(
                    context,
                    icon: Icons.document_scanner_outlined,
                    title: 'Сканування чеків (OCR)',
                    subtitle:
                        'Фотографуйте чеки, а додаток сам заповнить дані про транзакцію.',
                  ),
                  _buildFeatureTile(
                    context,
                    icon: Icons.insights_outlined,
                    title: 'Розширена аналітика та звіти',
                    subtitle:
                        'Отримуйте глибокі звіти, експортуйте дані в PDF/CSV для детального аналізу.',
                  ),
                  _buildFeatureTile(
                    context,
                    icon: Icons.cloud_sync_outlined,
                    title: 'Хмарна синхронізація',
                    subtitle:
                        'Безпечно синхронізуйте ваші дані між усіма пристроями, включаючи веб-версію.',
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      textStyle: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: proStatusProvider.isPro
                        ? null
                        : () async {
                            final billingService = getIt<BillingService>();
                            await billingService.buyProSubscription();
                          },
                    child: Center(
                        child: Text(proStatusProvider.isPro
                            ? 'Pro-версія вже активна'
                            : 'Активувати Pro')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}