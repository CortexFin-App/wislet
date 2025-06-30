import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_it/get_it.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sage_wallet_reborn/data/repositories/api/api_budget_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/api/api_category_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/api/api_debt_loan_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/api/api_goal_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/api/api_notification_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/api/api_plan_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/api/api_repeating_transaction_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/api/api_subscription_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/api/api_transaction_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/api/api_user_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/api/api_wallet_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/local/local_budget_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/local/local_category_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/local/local_debt_loan_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/local/local_goal_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/local/local_notification_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/local/local_plan_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/local/local_repeating_transaction_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/local/local_subscription_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/local/local_transaction_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/local/local_user_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/local/local_wallet_repository_impl.dart';
import 'package:sage_wallet_reborn/providers/app_mode_provider.dart';
import 'package:sage_wallet_reborn/providers/currency_provider.dart';
import 'package:sage_wallet_reborn/providers/pro_status_provider.dart';
import 'package:sage_wallet_reborn/providers/theme_provider.dart';
import 'package:sage_wallet_reborn/services/ai_categorization_service.dart';
import 'package:sage_wallet_reborn/services/analytics_service.dart';
import 'package:sage_wallet_reborn/services/cashflow_forecast_service.dart';
import 'package:sage_wallet_reborn/services/exchange_rate_service.dart';
import 'package:sage_wallet_reborn/services/navigation_service.dart';
import 'package:sage_wallet_reborn/services/repeating_transaction_service.dart';
import 'package:sage_wallet_reborn/services/subscription_service.dart';
import 'package:sage_wallet_reborn/utils/database_helper.dart';
import 'package:sage_wallet_reborn/services/api_client.dart';
import 'package:sage_wallet_reborn/services/token_storage_service.dart';
import 'package:sage_wallet_reborn/services/auth_service.dart';
import 'package:sage_wallet_reborn/services/notification_service.dart';
import 'package:sage_wallet_reborn/services/ocr_service.dart';
import 'package:sage_wallet_reborn/services/receipt_parser.dart';
import 'package:sage_wallet_reborn/services/report_generation_service.dart';
import 'package:sage_wallet_reborn/data/repositories/budget_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/category_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/debt_loan_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/goal_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/invitation_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/local/local_invitation_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/api/api_invitation_repository_impl.dart';
import 'package:sage_wallet_reborn/data/repositories/notification_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/plan_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/repeating_transaction_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/subscription_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/transaction_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/user_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/wallet_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/theme_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/local/local_theme_repository_impl.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt.registerLazySingleton(() => FlutterLocalNotificationsPlugin());
  getIt.registerLazySingleton(() => LocalAuthentication());
  getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);
  getIt.registerLazySingleton(() => ApiClient());
  getIt.registerLazySingleton(() => TokenStorageService());
  getIt.registerLazySingleton(() => OcrService(getIt()));
  getIt.registerLazySingleton(() => ReceiptParser());
  getIt.registerLazySingleton(() => ReportGenerationService());
  getIt.registerLazySingleton(() => ExchangeRateService());
  getIt.registerLazySingleton(() => NavigationService());
  getIt.registerLazySingleton<InvitationRepository>(
    () => ApiInvitationRepositoryImpl(getIt()));
  getIt.registerLazySingleton(() => AppModeProvider());
  getIt.registerLazySingleton<ThemeRepository>(() => LocalThemeRepositoryImpl(getIt()));

  if (kIsWeb) {
    getIt.registerLazySingleton<BudgetRepository>(
        () => ApiBudgetRepositoryImpl(getIt()));
    getIt.registerLazySingleton<CategoryRepository>(
        () => ApiCategoryRepositoryImpl(getIt()));
    getIt.registerLazySingleton<DebtLoanRepository>(
        () => ApiDebtLoanRepositoryImpl(getIt()));
    getIt.registerLazySingleton<GoalRepository>(
        () => ApiGoalRepositoryImpl(getIt()));
    getIt.registerLazySingleton<NotificationRepository>(
        () => ApiNotificationRepositoryImpl());
    getIt.registerLazySingleton<PlanRepository>(
        () => ApiPlanRepositoryImpl(getIt()));
    getIt.registerLazySingleton<RepeatingTransactionRepository>(
        () => ApiRepeatingTransactionRepositoryImpl(getIt()));
    getIt.registerLazySingleton<SubscriptionRepository>(
        () => ApiSubscriptionRepositoryImpl(getIt()));
    getIt.registerLazySingleton<TransactionRepository>(
        () => ApiTransactionRepositoryImpl(getIt()));
    getIt.registerLazySingleton<UserRepository>(
        () => ApiUserRepositoryImpl(getIt()));
    getIt.registerLazySingleton<WalletRepository>(
        () => ApiWalletRepositoryImpl(getIt()));
  } else {
    getIt.registerLazySingleton<BudgetRepository>(
        () => LocalBudgetRepositoryImpl(getIt(), getIt(), getIt()));
    getIt.registerLazySingleton<CategoryRepository>(
        () => LocalCategoryRepositoryImpl(getIt()));
    getIt.registerLazySingleton<DebtLoanRepository>(
        () => LocalDebtLoanRepositoryImpl(getIt()));
    getIt.registerLazySingleton<GoalRepository>(
        () => LocalGoalRepositoryImpl(getIt(), getIt(), getIt()));
    getIt.registerLazySingleton<NotificationRepository>(
        () => LocalNotificationRepositoryImpl(getIt()));
    getIt.registerLazySingleton<PlanRepository>(
        () => LocalPlanRepositoryImpl(getIt()));
    getIt.registerLazySingleton<RepeatingTransactionRepository>(
        () => LocalRepeatingTransactionRepositoryImpl(getIt()));
    getIt.registerLazySingleton<SubscriptionRepository>(
        () => LocalSubscriptionRepositoryImpl(getIt()));
    getIt.registerLazySingleton<TransactionRepository>(
        () => LocalTransactionRepositoryImpl(getIt(), getIt()));
    getIt.registerLazySingleton<UserRepository>(
        () => LocalUserRepositoryImpl(getIt()));
    getIt.registerLazySingleton<WalletRepository>(
        () => LocalWalletRepositoryImpl(getIt()));
  }

  getIt.registerLazySingleton(() => AuthService(getIt(), getIt(), getIt()));
  getIt.registerLazySingleton(() => NotificationService(getIt(), getIt()));
  getIt
      .registerLazySingleton(() => AICategorizationService(getIt()));
  getIt.registerLazySingleton(
      () => CashflowForecastService(getIt(), getIt(), getIt()));
  getIt.registerLazySingleton(
      () => RepeatingTransactionService(getIt(), getIt(), getIt()));
  getIt.registerLazySingleton(
      () => SubscriptionService(getIt(), getIt(), getIt(), getIt()));
  getIt.registerLazySingleton(() => AnalyticsService(getIt(), getIt(), getIt()));
  getIt.registerLazySingleton(() => ThemeProvider(getIt()));
  getIt.registerLazySingleton(() => CurrencyProvider());
  getIt.registerLazySingleton(() => ProStatusProvider());
}