import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/providers/pro_status_provider.dart';
import 'package:wislet/services/billing_service.dart';
import 'package:wislet/widgets/scaffold/patterned_scaffold.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final proStatusProvider = Provider.of<ProStatusProvider>(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return PatternedScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 80, 20, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    size: 80,
                    color: theme.colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Р РѕР·Р±Р»РѕРєСѓР№С‚Рµ РџРѕРІРЅРёР№ РџРѕС‚РµРЅС†С–Р°Р»',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'РћС‚СЂРёРјР°Р№С‚Рµ РґРѕСЃС‚СѓРї РґРѕ РµРєСЃРєР»СЋР·РёРІРЅРёС… С„СѓРЅРєС†С–Р№, С‰РѕР± РґРѕСЃСЏРіС‚Рё С„С–РЅР°РЅСЃРѕРІРѕС— РјР°Р№СЃС‚РµСЂРЅРѕСЃС‚С–.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onPrimary.withAlpha(204),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureTile(
                    context,
                    icon: Icons.auto_awesome,
                    title: 'AI-РђСЃРёСЃС‚РµРЅС‚ РґР»СЏ РєР°С‚РµРіРѕСЂС–Р№',
                    subtitle:
                        'Р”РѕР·РІРѕР»СЊС‚Рµ С€С‚СѓС‡РЅРѕРјСѓ С–РЅС‚РµР»РµРєС‚Сѓ Р°РІС‚РѕРјР°С‚РёС‡РЅРѕ РІРёР·РЅР°С‡Р°С‚Рё РєР°С‚РµРіРѕСЂС–С— РІР°С€РёС… С‚СЂР°РЅР·Р°РєС†С–Р№.',
                  ),
                  _buildFeatureTile(
                    context,
                    icon: Icons.document_scanner_outlined,
                    title: 'РЎРєР°РЅСѓРІР°РЅРЅСЏ С‡РµРєС–РІ (OCR)',
                    subtitle:
                        'Р¤РѕС‚РѕРіСЂР°С„СѓР№С‚Рµ С‡РµРєРё, Р° РґРѕРґР°С‚РѕРє СЃР°Рј Р·Р°РїРѕРІРЅРёС‚СЊ РґР°РЅС– РїСЂРѕ С‚СЂР°РЅР·Р°РєС†С–СЋ.',
                  ),
                  _buildFeatureTile(
                    context,
                    icon: Icons.insights_outlined,
                    title:
                        'Р РѕР·С€РёСЂРµРЅР° Р°РЅР°Р»С–С‚РёРєР° С‚Р° Р·РІС–С‚Рё',
                    subtitle:
                        'РћС‚СЂРёРјСѓР№С‚Рµ РіР»РёР±РѕРєС– Р·РІС–С‚Рё, РµРєСЃРїРѕСЂС‚СѓР№С‚Рµ РґР°РЅС– РІ PDF/CSV РґР»СЏ РґРµС‚Р°Р»СЊРЅРѕРіРѕ Р°РЅР°Р»С–Р·Сѓ.',
                  ),
                  _buildFeatureTile(
                    context,
                    icon: Icons.cloud_sync_outlined,
                    title: 'РҐРјР°СЂРЅР° СЃРёРЅС…СЂРѕРЅС–Р·Р°С†С–СЏ',
                    subtitle:
                        'Р‘РµР·РїРµС‡РЅРѕ СЃРёРЅС…СЂРѕРЅС–Р·СѓР№С‚Рµ РІР°С€С– РґР°РЅС– РјС–Р¶ СѓСЃС–РјР° РїСЂРёСЃС‚СЂРѕСЏРјРё, РІРєР»СЋС‡Р°СЋС‡Рё РІРµР±-РІРµСЂСЃС–СЋ.',
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: proStatusProvider.isPro
                          ? null
                          : () async {
                              final billingService = getIt<BillingService>();
                              await billingService.buyProSubscription();
                            },
                      child: Center(
                        child: Text(
                          proStatusProvider.isPro
                              ? 'Pro-РІРµСЂСЃС–СЏ РІР¶Рµ Р°РєС‚РёРІРЅР°'
                              : 'РђРєС‚РёРІСѓРІР°С‚Рё Pro',
                        ),
                      ),
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

  Widget _buildFeatureTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: theme.colorScheme.tertiary),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
