import 'package:flutter/widgets.dart';
import 'package:wislet/l10n/app_localizations.dart';
import 'package:wislet/models/budget_models.dart';
import 'package:wislet/models/subscription_model.dart';

extension AppLocalizationsT on AppLocalizations {
  /// Повертає локалізований рядок за ключем.
  /// Якщо ключ відсутній у словнику — повертає сам ключ.
  String t(String key) {
    final isUk = localeName.toLowerCase().startsWith('uk');
    final map = isUk ? _ukStrings : _enStrings;
    return map[key] ?? key;
  }
}

/// Мінімальні словники для ключів, які згадуються у твоєму коді/логах.
/// За потреби просто додай нові пари 'key': 'value'.
const Map<String, String> _enStrings = {
  // Common / navigation
  'app_title': 'Wislet',
  'home': 'Home',
  'wallets': 'Wallets',
  'settings': 'Settings',
  'add': 'Add',

  // Settings sections/items (взято з твоїх логів/імен)
  'restore_done': 'Restore completed',
  'sync_done': 'Sync completed',
  'interface': 'Interface',
  'language': 'Language',
  'money_and_currencies': 'Money & currencies',
  'default_currency': 'Default currency',
  'currency_converter': 'Currency converter',
  'data_and_sync': 'Data & sync',
  'sync_now': 'Sync now',
  'backup': 'Backup',
  'restore': 'Restore',
  'management': 'Management',
  'categories': 'Categories',
  'invitations': 'Invitations',
  'security': 'Security',
  'change_pin': 'Change PIN',
  'enable_pin': 'Enable PIN',
  'biometrics': 'Biometrics',
  'biometrics_configured': 'Biometrics configured',
  'biometrics_not_supported': 'Biometrics not supported',
  'logout': 'Log out',

  // Budget strategies
  'budget_strategy_category_based': 'Category-based',
  'budget_strategy_envelope': 'Envelope',
  'budget_strategy_rule_50_30_20': '50/30/20 rule',
  'budget_strategy_zero_based': 'Zero-based',

  // Billing cycles
  'billing_cycle_daily': 'Daily',
  'billing_cycle_weekly': 'Weekly',
  'billing_cycle_monthly': 'Monthly',
  'billing_cycle_quarterly': 'Quarterly',
  'billing_cycle_yearly': 'Yearly',
  'billing_cycle_custom': 'Custom',
};

const Map<String, String> _ukStrings = {
  // Common / navigation
  'app_title': 'Wislet',
  'home': 'Головна',
  'wallets': 'Гаманці',
  'settings': 'Налаштування',
  'add': 'Додати',

  // Settings sections/items
  'restore_done': 'Відновлення завершено',
  'sync_done': 'Синхронізацію завершено',
  'interface': 'Інтерфейс',
  'language': 'Мова',
  'money_and_currencies': 'Гроші та валюти',
  'default_currency': 'Валюта за замовчуванням',
  'currency_converter': 'Конвертер валют',
  'data_and_sync': 'Дані та синхронізація',
  'sync_now': 'Синхронізувати зараз',
  'backup': 'Резервна копія',
  'restore': 'Відновлення',
  'management': 'Керування',
  'categories': 'Категорії',
  'invitations': 'Запрошення',
  'security': 'Безпека',
  'change_pin': 'Змінити PIN',
  'enable_pin': 'Увімкнути PIN',
  'biometrics': 'Біометрія',
  'biometrics_configured': 'Біометрію налаштовано',
  'biometrics_not_supported': 'Біометрія не підтримується',
  'logout': 'Вийти',

  // Budget strategies
  'budget_strategy_category_based': 'За категоріями',
  'budget_strategy_envelope': 'Конверти',
  'budget_strategy_rule_50_30_20': 'Правило 50/30/20',
  'budget_strategy_zero_based': 'Нульовий бюджет',

  // Billing cycles
  'billing_cycle_daily': 'Щодня',
  'billing_cycle_weekly': 'Щотижня',
  'billing_cycle_monthly': 'Щомісяця',
  'billing_cycle_quarterly': 'Щокварталу',
  'billing_cycle_yearly': 'Щороку',
  'billing_cycle_custom': 'Користувацький',
};

String budgetStrategyTypeToString(
    BudgetStrategyType type, BuildContext context,) {
  final l = AppLocalizations.of(context)!;
  switch (type) {
    case BudgetStrategyType.categoryBased:
      return l.t('budget_strategy_category_based');
    case BudgetStrategyType.envelope:
      return l.t('budget_strategy_envelope');
    case BudgetStrategyType.rule50_30_20:
      return l.t('budget_strategy_rule_50_30_20');
    case BudgetStrategyType.zeroBased:
      return l.t('budget_strategy_zero_based');
  }
}

String billingCycleToString(BillingCycle c, BuildContext context) {
  final l = AppLocalizations.of(context)!;
  switch (c) {
    case BillingCycle.daily:
      return l.t('billing_cycle_daily');
    case BillingCycle.weekly:
      return l.t('billing_cycle_weekly');
    case BillingCycle.monthly:
      return l.t('billing_cycle_monthly');
    case BillingCycle.quarterly:
      return l.t('billing_cycle_quarterly');
    case BillingCycle.yearly:
      return l.t('billing_cycle_yearly');
    case BillingCycle.custom:
      return l.t('billing_cycle_custom');
  }
}
