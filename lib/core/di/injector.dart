import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:local_auth/local_auth.dart';
import 'package:wislet/data/repositories/asset_repository.dart';
import 'package:wislet/data/repositories/budget_repository.dart';
import 'package:wislet/data/repositories/category_repository.dart';
import 'package:wislet/data/repositories/debt_loan_repository.dart';
import 'package:wislet/data/repositories/goal_repository.dart';
import 'package:wislet/data/repositories/invitation_repository.dart';
import 'package:wislet/data/repositories/liability_repository.dart';
import 'package:wislet/data/repositories/local/local_asset_repository_impl.dart';
import 'package:wislet/data/repositories/local/local_budget_repository_impl.dart';
import 'package:wislet/data/repositories/local/local_category_repository_impl.dart';
import 'package:wislet/data/repositories/local/local_debt_loan_repository_impl.dart';
import 'package:wislet/data/repositories/local/local_goal_repository_impl.dart';
import 'package:wislet/data/repositories/local/local_invitation_repository_impl.dart';
import 'package:wislet/data/repositories/local/local_liability_repository_impl.dart';
import 'package:wislet/data/repositories/local/local_notification_repository_impl.dart';
import 'package:wislet/data/repositories/local/local_plan_repository_impl.dart';
import 'package:wislet/data/repositories/local/local_repeating_transaction_repository_impl.dart';
import 'package:wislet/data/repositories/local/local_subscription_repository_impl.dart';
import 'package:wislet/data/repositories/local/local_theme_repository_impl.dart';
import 'package:wislet/data/repositories/local/local_transaction_repository_impl.dart';
import 'package:wislet/data/repositories/local/local_user_repository_impl.dart';
import 'package:wislet/data/repositories/local/local_wallet_repository_impl.dart';
import 'package:wislet/data/repositories/notification_repository.dart';
import 'package:wislet/data/repositories/plan_repository.dart';
import 'package:wislet/data/repositories/repeating_transaction_repository.dart';
import 'package:wislet/data/repositories/subscription_repository.dart';
import 'package:wislet/data/repositories/supabase/supabase_asset_repository_impl.dart';
import 'package:wislet/data/repositories/supabase/supabase_budget_repository_impl.dart';
import 'package:wislet/data/repositories/supabase/supabase_category_repository_impl.dart';
import 'package:wislet/data/repositories/supabase/supabase_debt_loan_repository_impl.dart';
import 'package:wislet/data/repositories/supabase/supabase_goal_repository_impl.dart';
import 'package:wislet/data/repositories/supabase/supabase_invitation_repository_impl.dart';
import 'package:wislet/data/repositories/supabase/supabase_liability_repository_impl.dart';
import 'package:wislet/data/repositories/supabase/supabase_notification_repository_impl.dart';
import 'package:wislet/data/repositories/supabase/supabase_plan_repository_impl.dart';
import 'package:wislet/data/repositories/supabase/supabase_repeating_transaction_repository_impl.dart';
import 'package:wislet/data/repositories/supabase/supabase_subscription_repository_impl.dart';
import 'package:wislet/data/repositories/supabase/supabase_transaction_repository_impl.dart';
import 'package:wislet/data/repositories/supabase/supabase_user_repository_impl.dart';
import 'package:wislet/data/repositories/supabase/supabase_wallet_repository_impl.dart';
import 'package:wislet/data/repositories/theme_repository.dart';
import 'package:wislet/data/repositories/transaction_repository.dart';
import 'package:wislet/data/repositories/user_repository.dart';
import 'package:wislet/data/repositories/wallet_repository.dart';
import 'package:wislet/providers/app_mode_provider.dart';
import 'package:wislet/providers/currency_provider.dart';
import 'package:wislet/providers/pro_status_provider.dart';
import 'package:wislet/providers/theme_provider.dart';
import 'package:wislet/services/ai_categorization_service.dart';
import 'package:wislet/services/ai_insight_service.dart';
import 'package:wislet/services/analytics_service.dart';
import 'package:wislet/services/api_client.dart';
import 'package:wislet/services/auth_service.dart';
import 'package:wislet/services/billing_service.dart';
import 'package:wislet/services/cashflow_forecast_service.dart';
import 'package:wislet/services/exchange_rate_service.dart';
import 'package:wislet/services/financial_report_service.dart';
import 'package:wislet/services/navigation_service.dart';
import 'package:wislet/services/net_worth_service.dart';
import 'package:wislet/services/notification_service.dart';
import 'package:wislet/services/ocr_service.dart';
import 'package:wislet/services/receipt_parser.dart';
import 'package:wislet/services/repeating_transaction_service.dart';
import 'package:wislet/services/report_generation_service.dart';
import 'package:wislet/services/subscription_service.dart';
import 'package:wislet/services/sync_service.dart';
import 'package:wislet/services/token_storage_service.dart';
import 'package:wislet/utils/database_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // базові сервіси/утиліти
  getIt
    ..registerLazySingleton<SupabaseClient>(() => Supabase.instance.client)
    ..registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance)
    ..registerLazySingleton(FlutterLocalNotificationsPlugin.new)
    ..registerLazySingleton(LocalAuthentication.new)
    ..registerLazySingleton(TokenStorageService.new)
    ..registerLazySingleton(ApiClient.new)
    ..registerLazySingleton(NavigationService.new);

  _registerLocalRepositories();
  _registerSupabaseRepositories();
  _registerActiveRepositoryFactories();

  // доменні сервіси
  getIt
    ..registerLazySingleton(() => AuthService(getIt(), getIt()))
    ..registerLazySingleton(ExchangeRateService.new)
    ..registerLazySingleton(ReceiptParser.new)
    ..registerLazySingleton(ReportGenerationService.new)
    ..registerLazySingleton(() => OcrService(getIt()))
    ..registerLazySingleton(FinancialReportService.new)
    ..registerLazySingleton<BillingService>(FakeBillingService.new)
    ..registerLazySingleton<NotificationService>(() => NotificationService())
    ..registerLazySingleton(AiInsightService.new)
    ..registerLazySingleton(() => AICategorizationService(getIt()))
    ..registerLazySingleton(() => AnalyticsService(getIt(), getIt(), getIt()))
    ..registerLazySingleton(
        () => CashflowForecastService(getIt(), getIt(), getIt()))
    ..registerLazySingleton(
        () => RepeatingTransactionService(getIt(), getIt(), getIt()))
    ..registerLazySingleton(
        () => SubscriptionService(getIt(), getIt(), getIt(), getIt()))
    ..registerLazySingleton(() => SyncService(
          getIt(),
          getIt(instanceName: 'local'),
          getIt(instanceName: 'supabase'),
          getIt(instanceName: 'supabase'),
          getIt(instanceName: 'supabase'),
          getIt(instanceName: 'supabase'),
          getIt(instanceName: 'supabase'),
          getIt(instanceName: 'supabase'),
          getIt(instanceName: 'supabase'),
          getIt(instanceName: 'supabase'),
          getIt(instanceName: 'supabase'),
        ))
    ..registerLazySingleton(NetWorthService.new)
    ..registerLazySingleton(() => AppModeProvider(getIt()))
    ..registerLazySingleton(() => ThemeProvider(getIt<ThemeRepository>()))
    ..registerLazySingleton(CurrencyProvider.new)
    ..registerLazySingleton(ProStatusProvider.new);

  // ініціалізація тих, кому це потрібно
  await getIt<NotificationService>().init();
}

void _registerLocalRepositories() {
  getIt
    ..registerLazySingleton<ThemeRepository>(
        () => LocalThemeRepositoryImpl(getIt()))
    ..registerLazySingleton<WalletRepository>(
        () => LocalWalletRepositoryImpl(getIt()),
        instanceName: 'local')
    ..registerLazySingleton<TransactionRepository>(
        () => LocalTransactionRepositoryImpl(getIt(), getIt()),
        instanceName: 'local')
    ..registerLazySingleton<CategoryRepository>(
        () => LocalCategoryRepositoryImpl(getIt()),
        instanceName: 'local')
    ..registerLazySingleton<BudgetRepository>(
        () => LocalBudgetRepositoryImpl(
            getIt(), getIt(instanceName: 'local'), getIt()),
        instanceName: 'local')
    ..registerLazySingleton<DebtLoanRepository>(
        () => LocalDebtLoanRepositoryImpl(getIt()),
        instanceName: 'local')
    ..registerLazySingleton<GoalRepository>(
        () => LocalGoalRepositoryImpl(
            getIt(), getIt(instanceName: 'local'), getIt()),
        instanceName: 'local')
    ..registerLazySingleton<InvitationRepository>(
        LocalInvitationRepositoryImpl.new,
        instanceName: 'local')
    ..registerLazySingleton<NotificationRepository>(
        () => LocalNotificationRepositoryImpl(getIt()),
        instanceName: 'local')
    ..registerLazySingleton<PlanRepository>(
        () => LocalPlanRepositoryImpl(getIt()),
        instanceName: 'local')
    ..registerLazySingleton<RepeatingTransactionRepository>(
        () => LocalRepeatingTransactionRepositoryImpl(getIt()),
        instanceName: 'local')
    ..registerLazySingleton<SubscriptionRepository>(
        () => LocalSubscriptionRepositoryImpl(getIt()),
        instanceName: 'local')
    ..registerLazySingleton<UserRepository>(
        () => LocalUserRepositoryImpl(getIt()),
        instanceName: 'local')
    ..registerLazySingleton<AssetRepository>(
        () => LocalAssetRepositoryImpl(getIt()),
        instanceName: 'local')
    ..registerLazySingleton<LiabilityRepository>(
        () => LocalLiabilityRepositoryImpl(getIt()),
        instanceName: 'local');
}

void _registerSupabaseRepositories() {
  getIt
    ..registerLazySingleton<WalletRepository>(
        () => SupabaseWalletRepositoryImpl(getIt()),
        instanceName: 'supabase')
    ..registerLazySingleton<TransactionRepository>(
        () => SupabaseTransactionRepositoryImpl(getIt()),
        instanceName: 'supabase')
    ..registerLazySingleton<CategoryRepository>(
        () => SupabaseCategoryRepositoryImpl(getIt()),
        instanceName: 'supabase')
    ..registerLazySingleton<BudgetRepository>(
        () => SupabaseBudgetRepositoryImpl(getIt()),
        instanceName: 'supabase')
    ..registerLazySingleton<DebtLoanRepository>(
        () => SupabaseDebtLoanRepositoryImpl(getIt()),
        instanceName: 'supabase')
    ..registerLazySingleton<GoalRepository>(
        () => SupabaseGoalRepositoryImpl(getIt()),
        instanceName: 'supabase')
    ..registerLazySingleton<InvitationRepository>(
        () => SupabaseInvitationRepositoryImpl(getIt()),
        instanceName: 'supabase')
    ..registerLazySingleton<NotificationRepository>(
        SupabaseNotificationRepositoryImpl.new,
        instanceName: 'supabase')
    ..registerLazySingleton<PlanRepository>(
        () => SupabasePlanRepositoryImpl(getIt()),
        instanceName: 'supabase')
    ..registerLazySingleton<RepeatingTransactionRepository>(
        () => SupabaseRepeatingTransactionRepositoryImpl(getIt()),
        instanceName: 'supabase')
    ..registerLazySingleton<SubscriptionRepository>(
        () => SupabaseSubscriptionRepositoryImpl(getIt()),
        instanceName: 'supabase')
    ..registerLazySingleton<UserRepository>(
        () => SupabaseUserRepositoryImpl(getIt()),
        instanceName: 'supabase')
    ..registerLazySingleton<AssetRepository>(
        () => SupabaseAssetRepositoryImpl(getIt()),
        instanceName: 'supabase')
    ..registerLazySingleton<LiabilityRepository>(
        () => SupabaseLiabilityRepositoryImpl(getIt()),
        instanceName: 'supabase');
}

void _registerActiveRepositoryFactories() {
  getIt
    ..registerFactory<WalletRepository>(() => getIt<AppModeProvider>().isOnline
        ? getIt(instanceName: 'supabase')
        : getIt(instanceName: 'local'))
    ..registerFactory<CategoryRepository>(() =>
        getIt<AppModeProvider>().isOnline
            ? getIt(instanceName: 'supabase')
            : getIt(instanceName: 'local'))
    ..registerFactory<TransactionRepository>(() =>
        getIt<AppModeProvider>().isOnline
            ? getIt(instanceName: 'supabase')
            : getIt(instanceName: 'local'))
    ..registerFactory<BudgetRepository>(() => getIt<AppModeProvider>().isOnline
        ? getIt(instanceName: 'supabase')
        : getIt(instanceName: 'local'))
    ..registerFactory<DebtLoanRepository>(() =>
        getIt<AppModeProvider>().isOnline
            ? getIt(instanceName: 'supabase')
            : getIt(instanceName: 'local'))
    ..registerFactory<GoalRepository>(() => getIt<AppModeProvider>().isOnline
        ? getIt(instanceName: 'supabase')
        : getIt(instanceName: 'local'))
    ..registerFactory<InvitationRepository>(() =>
        getIt<AppModeProvider>().isOnline
            ? getIt(instanceName: 'supabase')
            : getIt(instanceName: 'local'))
    ..registerFactory<NotificationRepository>(() =>
        getIt<AppModeProvider>().isOnline
            ? getIt(instanceName: 'supabase')
            : getIt(instanceName: 'local'))
    ..registerFactory<PlanRepository>(() => getIt<AppModeProvider>().isOnline
        ? getIt(instanceName: 'supabase')
        : getIt(instanceName: 'local'))
    ..registerFactory<RepeatingTransactionRepository>(() =>
        getIt<AppModeProvider>().isOnline
            ? getIt(instanceName: 'supabase')
            : getIt(instanceName: 'local'))
    ..registerFactory<SubscriptionRepository>(() =>
        getIt<AppModeProvider>().isOnline
            ? getIt(instanceName: 'supabase')
            : getIt(instanceName: 'local'))
    ..registerFactory<UserRepository>(() => getIt<AppModeProvider>().isOnline
        ? getIt(instanceName: 'supabase')
        : getIt(instanceName: 'local'))
    ..registerFactory<AssetRepository>(() => getIt<AppModeProvider>().isOnline
        ? getIt(instanceName: 'supabase')
        : getIt(instanceName: 'local'))
    ..registerFactory<LiabilityRepository>(() =>
        getIt<AppModeProvider>().isOnline
            ? getIt(instanceName: 'supabase')
            : getIt(instanceName: 'local'));
}
