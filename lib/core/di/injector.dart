import 'package:get_it/get_it.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sage_wallet_reborn/services/billing_service.dart';
import 'package:sage_wallet_reborn/services/financial_report_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/debt_loan_repository.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/repositories/invitation_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/repeating_transaction_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../data/repositories/theme_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../data/repositories/local/local_budget_repository_impl.dart';
import '../../data/repositories/local/local_category_repository_impl.dart';
import '../../data/repositories/local/local_debt_loan_repository_impl.dart';
import '../../data/repositories/local/local_goal_repository_impl.dart';
import '../../data/repositories/local/local_invitation_repository_impl.dart';
import '../../data/repositories/local/local_notification_repository_impl.dart';
import '../../data/repositories/local/local_plan_repository_impl.dart';
import '../../data/repositories/local/local_repeating_transaction_repository_impl.dart';
import '../../data/repositories/local/local_subscription_repository_impl.dart';
import '../../data/repositories/local/local_theme_repository_impl.dart';
import '../../data/repositories/local/local_transaction_repository_impl.dart';
import '../../data/repositories/local/local_user_repository_impl.dart';
import '../../data/repositories/local/local_wallet_repository_impl.dart';
import '../../data/repositories/supabase/supabase_budget_repository_impl.dart';
import '../../data/repositories/supabase/supabase_category_repository_impl.dart';
import '../../data/repositories/supabase/supabase_debt_loan_repository_impl.dart';
import '../../data/repositories/supabase/supabase_goal_repository_impl.dart';
import '../../data/repositories/supabase/supabase_invitation_repository_impl.dart';
import '../../data/repositories/supabase/supabase_notification_repository_impl.dart';
import '../../data/repositories/supabase/supabase_plan_repository_impl.dart';
import '../../data/repositories/supabase/supabase_repeating_transaction_repository_impl.dart';
import '../../data/repositories/supabase/supabase_subscription_repository_impl.dart';
import '../../data/repositories/supabase/supabase_transaction_repository_impl.dart';
import '../../data/repositories/supabase/supabase_user_repository_impl.dart';
import '../../data/repositories/supabase/supabase_wallet_repository_impl.dart';
import '../../providers/app_mode_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/pro_status_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/ai_categorization_service.dart';
import '../../services/ai_insight_service.dart';
import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';
import '../../services/cashflow_forecast_service.dart';
import '../../services/exchange_rate_service.dart';
import '../../services/navigation_service.dart';
import '../../services/notification_service.dart';
import '../../services/ocr_service.dart';
import '../../services/receipt_parser.dart';
import '../../services/report_generation_service.dart';
import '../../services/repeating_transaction_service.dart';
import '../../services/subscription_service.dart';
import '../../services/sync_service.dart';
import '../../services/token_storage_service.dart';
import '../../utils/database_helper.dart';
import '../../services/api_client.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // 1. Core Components
  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);
  getIt.registerLazySingleton<FlutterLocalNotificationsPlugin>(() => FlutterLocalNotificationsPlugin());
  getIt.registerLazySingleton<LocalAuthentication>(() => LocalAuthentication());
  getIt.registerLazySingleton<TokenStorageService>(() => TokenStorageService());
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());
  getIt.registerLazySingleton<NavigationService>(() => NavigationService());

  // 2. Repositories
  _registerLocalRepositories();
  _registerSupabaseRepositories();
  _registerActiveRepositoryFactories();
  
  // 3. Services
  getIt.registerLazySingleton<AuthService>(() => AuthService(getIt(), getIt()));
  getIt.registerLazySingleton<ExchangeRateService>(() => ExchangeRateService());
  getIt.registerLazySingleton<ReceiptParser>(() => ReceiptParser());
  getIt.registerLazySingleton<ReportGenerationService>(() => ReportGenerationService());
  getIt.registerLazySingleton<OcrService>(() => OcrService(getIt()));
  getIt.registerLazySingleton<FinancialReportService>(() => FinancialReportService());
  
  // Для тестування використовуємо FakeBillingService.
  // Для релізу закоментуй наступний рядок і розкоментуй AppStoreBillingService.
  getIt.registerLazySingleton<BillingService>(() => FakeBillingService());
  // getIt.registerLazySingleton<BillingService>(() => AppStoreBillingService());

  getIt.registerLazySingleton<NotificationService>(() => NotificationService(getIt(), getIt(instanceName: 'local')));
  getIt.registerLazySingleton<AiInsightService>(() => AiInsightService());
  getIt.registerLazySingleton<AICategorizationService>(() => AICategorizationService(getIt()));
  getIt.registerLazySingleton<AnalyticsService>(() => AnalyticsService(getIt(), getIt(), getIt()));
  getIt.registerLazySingleton<CashflowForecastService>(() => CashflowForecastService(getIt(), getIt(), getIt()));
  getIt.registerLazySingleton<RepeatingTransactionService>(() => RepeatingTransactionService(getIt(), getIt(), getIt()));
  getIt.registerLazySingleton<SubscriptionService>(() => SubscriptionService(getIt(), getIt(), getIt(), getIt()));
  getIt.registerLazySingleton<SyncService>(() => SyncService(
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
      getIt(instanceName: 'supabase')));

  // 4. Providers (as singletons for GetIt, they will be provided to the widget tree in main.dart)
  getIt.registerLazySingleton<AppModeProvider>(() => AppModeProvider(getIt()));
  getIt.registerLazySingleton<ThemeProvider>(() => ThemeProvider(getIt<ThemeRepository>()));
  getIt.registerLazySingleton<CurrencyProvider>(() => CurrencyProvider());
  getIt.registerLazySingleton<ProStatusProvider>(() => ProStatusProvider());
}

void _registerLocalRepositories() {
  getIt.registerLazySingleton<ThemeRepository>(
      () => LocalThemeRepositoryImpl(getIt()));
  getIt.registerLazySingleton<WalletRepository>(
      () => LocalWalletRepositoryImpl(getIt()),
      instanceName: 'local');
  getIt.registerLazySingleton<TransactionRepository>(
      () => LocalTransactionRepositoryImpl(getIt(), getIt()),
      instanceName: 'local');
  getIt.registerLazySingleton<CategoryRepository>(
      () => LocalCategoryRepositoryImpl(getIt()),
      instanceName: 'local');
  getIt.registerLazySingleton<BudgetRepository>(
      () =>
          LocalBudgetRepositoryImpl(getIt(), getIt(instanceName: 'local'), getIt()),
      instanceName: 'local');
  getIt.registerLazySingleton<DebtLoanRepository>(
      () => LocalDebtLoanRepositoryImpl(getIt()),
      instanceName: 'local');
  getIt.registerLazySingleton<GoalRepository>(
      () =>
          LocalGoalRepositoryImpl(getIt(), getIt(instanceName: 'local'), getIt()),
      instanceName: 'local');
  getIt.registerLazySingleton<InvitationRepository>(
      () => LocalInvitationRepositoryImpl(),
      instanceName: 'local');
  getIt.registerLazySingleton<NotificationRepository>(
      () => LocalNotificationRepositoryImpl(getIt()),
      instanceName: 'local');
  getIt.registerLazySingleton<PlanRepository>(
      () => LocalPlanRepositoryImpl(getIt()),
      instanceName: 'local');
  getIt.registerLazySingleton<RepeatingTransactionRepository>(
      () => LocalRepeatingTransactionRepositoryImpl(getIt()),
      instanceName: 'local');
  getIt.registerLazySingleton<SubscriptionRepository>(
      () => LocalSubscriptionRepositoryImpl(getIt()),
      instanceName: 'local');
  getIt.registerLazySingleton<UserRepository>(
      () => LocalUserRepositoryImpl(getIt()),
      instanceName: 'local');
}

void _registerSupabaseRepositories() {
  getIt.registerLazySingleton<WalletRepository>(
      () => SupabaseWalletRepositoryImpl(getIt()),
      instanceName: 'supabase');
  getIt.registerLazySingleton<TransactionRepository>(
      () => SupabaseTransactionRepositoryImpl(getIt()),
      instanceName: 'supabase');
  getIt.registerLazySingleton<CategoryRepository>(
      () => SupabaseCategoryRepositoryImpl(getIt()),
      instanceName: 'supabase');
  getIt.registerLazySingleton<BudgetRepository>(
      () => SupabaseBudgetRepositoryImpl(getIt()),
      instanceName: 'supabase');
  getIt.registerLazySingleton<DebtLoanRepository>(
      () => SupabaseDebtLoanRepositoryImpl(getIt()),
      instanceName: 'supabase');
  getIt.registerLazySingleton<GoalRepository>(
      () => SupabaseGoalRepositoryImpl(getIt()),
      instanceName: 'supabase');
  getIt.registerLazySingleton<InvitationRepository>(
      () => SupabaseInvitationRepositoryImpl(getIt()),
      instanceName: 'supabase');
  getIt.registerLazySingleton<NotificationRepository>(
      () => SupabaseNotificationRepositoryImpl(),
      instanceName: 'supabase');
  getIt.registerLazySingleton<PlanRepository>(
      () => SupabasePlanRepositoryImpl(getIt()),
      instanceName: 'supabase');
  getIt.registerLazySingleton<RepeatingTransactionRepository>(
      () => SupabaseRepeatingTransactionRepositoryImpl(getIt()),
      instanceName: 'supabase');
  getIt.registerLazySingleton<SubscriptionRepository>(
      () => SupabaseSubscriptionRepositoryImpl(getIt()),
      instanceName: 'supabase');
  getIt.registerLazySingleton<UserRepository>(
      () => SupabaseUserRepositoryImpl(getIt()),
      instanceName: 'supabase');
}

void _registerActiveRepositoryFactories() {
  getIt.registerFactory<WalletRepository>(() =>
      getIt<AppModeProvider>().isOnline
          ? getIt(instanceName: 'supabase')
          : getIt(instanceName: 'local'));
  getIt.registerFactory<CategoryRepository>(() =>
      getIt<AppModeProvider>().isOnline
          ? getIt(instanceName: 'supabase')
          : getIt(instanceName: 'local'));
  getIt.registerFactory<TransactionRepository>(() =>
      getIt<AppModeProvider>().isOnline
          ? getIt(instanceName: 'supabase')
          : getIt(instanceName: 'local'));
  getIt.registerFactory<BudgetRepository>(() =>
      getIt<AppModeProvider>().isOnline
          ? getIt(instanceName: 'supabase')
          : getIt(instanceName: 'local'));
  getIt.registerFactory<DebtLoanRepository>(() =>
      getIt<AppModeProvider>().isOnline
          ? getIt(instanceName: 'supabase')
          : getIt(instanceName: 'local'));
  getIt.registerFactory<GoalRepository>(() =>
      getIt<AppModeProvider>().isOnline
          ? getIt(instanceName: 'supabase')
          : getIt(instanceName: 'local'));
  getIt.registerFactory<InvitationRepository>(() =>
      getIt<AppModeProvider>().isOnline
          ? getIt(instanceName: 'supabase')
          : getIt(instanceName: 'local'));
  getIt.registerFactory<NotificationRepository>(() =>
      getIt<AppModeProvider>().isOnline
          ? getIt(instanceName: 'supabase')
          : getIt(instanceName: 'local'));
  getIt.registerFactory<PlanRepository>(() =>
      getIt<AppModeProvider>().isOnline
          ? getIt(instanceName: 'supabase')
          : getIt(instanceName: 'local'));
  getIt.registerFactory<RepeatingTransactionRepository>(() =>
      getIt<AppModeProvider>().isOnline
          ? getIt(instanceName: 'supabase')
          : getIt(instanceName: 'local'));
  getIt.registerFactory<SubscriptionRepository>(() =>
      getIt<AppModeProvider>().isOnline
          ? getIt(instanceName: 'supabase')
          : getIt(instanceName: 'local'));
  getIt.registerFactory<UserRepository>(() =>
      getIt<AppModeProvider>().isOnline
          ? getIt(instanceName: 'supabase')
          : getIt(instanceName: 'local'));
}