import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_it/get_it.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_auth/local_auth.dart';
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
import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';
import '../../services/billing_service.dart';
import '../../services/cashflow_forecast_service.dart';
import '../../services/exchange_rate_service.dart';
import '../../services/navigation_service.dart';
import '../../services/notification_service.dart';
import '../../services/ocr_service.dart';
import '../../services/receipt_parser.dart';
import '../../services/report_generation_service.dart';
import '../../services/repeating_transaction_service.dart';
import '../../services/subscription_service.dart';
import '../../services/token_storage_service.dart';
import '../../utils/database_helper.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt.registerSingleton<SupabaseClient>(Supabase.instance.client);
  getIt.registerLazySingleton(() => LocalAuthentication());
  getIt.registerLazySingleton(() => TokenStorageService());
  getIt.registerLazySingleton(() => AuthService(getIt(), getIt()));

  getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);
  getIt.registerLazySingleton(() => FlutterLocalNotificationsPlugin());
  
  getIt.registerLazySingleton(() => OcrService(getIt()));
  getIt.registerLazySingleton(() => ReceiptParser());
  getIt.registerLazySingleton(() => ReportGenerationService());
  getIt.registerLazySingleton(() => ExchangeRateService());
  getIt.registerLazySingleton(() => NavigationService());
  
  getIt.registerLazySingleton(() => AppModeProvider());
  getIt.registerLazySingleton<ThemeRepository>(() => LocalThemeRepositoryImpl(getIt()));
  
  final appModeProvider = getIt<AppModeProvider>();
  
  if (appModeProvider.isOnline) {
    getIt.registerLazySingleton<BudgetRepository>(() => SupabaseBudgetRepositoryImpl(getIt()));
    getIt.registerLazySingleton<CategoryRepository>(() => SupabaseCategoryRepositoryImpl(getIt()));
    getIt.registerLazySingleton<DebtLoanRepository>(() => SupabaseDebtLoanRepositoryImpl(getIt()));
    getIt.registerLazySingleton<GoalRepository>(() => SupabaseGoalRepositoryImpl(getIt()));
    getIt.registerLazySingleton<InvitationRepository>(() => SupabaseInvitationRepositoryImpl(getIt()));
    getIt.registerLazySingleton<NotificationRepository>(() => SupabaseNotificationRepositoryImpl());
    getIt.registerLazySingleton<PlanRepository>(() => SupabasePlanRepositoryImpl(getIt()));
    getIt.registerLazySingleton<RepeatingTransactionRepository>(() => SupabaseRepeatingTransactionRepositoryImpl(getIt()));
    getIt.registerLazySingleton<SubscriptionRepository>(() => SupabaseSubscriptionRepositoryImpl(getIt()));
    getIt.registerLazySingleton<TransactionRepository>(() => SupabaseTransactionRepositoryImpl(getIt()));
    getIt.registerLazySingleton<UserRepository>(() => SupabaseUserRepositoryImpl(getIt()));
    getIt.registerLazySingleton<WalletRepository>(() => SupabaseWalletRepositoryImpl(getIt()));
  } else {
    getIt.registerLazySingleton<BudgetRepository>(() => LocalBudgetRepositoryImpl(getIt(), getIt(), getIt()));
    getIt.registerLazySingleton<CategoryRepository>(() => LocalCategoryRepositoryImpl(getIt()));
    getIt.registerLazySingleton<DebtLoanRepository>(() => LocalDebtLoanRepositoryImpl(getIt()));
    getIt.registerLazySingleton<GoalRepository>(() => LocalGoalRepositoryImpl(getIt(), getIt(), getIt()));
    getIt.registerLazySingleton<InvitationRepository>(() => LocalInvitationRepositoryImpl());
    getIt.registerLazySingleton<NotificationRepository>(() => LocalNotificationRepositoryImpl(getIt()));
    getIt.registerLazySingleton<PlanRepository>(() => LocalPlanRepositoryImpl(getIt()));
    getIt.registerLazySingleton<RepeatingTransactionRepository>(() => LocalRepeatingTransactionRepositoryImpl(getIt()));
    getIt.registerLazySingleton<SubscriptionRepository>(() => LocalSubscriptionRepositoryImpl(getIt()));
    getIt.registerLazySingleton<TransactionRepository>(() => LocalTransactionRepositoryImpl(getIt(), getIt()));
    getIt.registerLazySingleton<UserRepository>(() => LocalUserRepositoryImpl(getIt()));
    getIt.registerLazySingleton<WalletRepository>(() => LocalWalletRepositoryImpl(getIt()));
  }

  getIt.registerLazySingleton(() => NotificationService(getIt(), getIt()));
  getIt.registerLazySingleton(() => BillingService());
  getIt.registerLazySingleton(() => AICategorizationService(getIt()));
  getIt.registerLazySingleton(() => CashflowForecastService(getIt(), getIt(), getIt()));
  getIt.registerLazySingleton(() => RepeatingTransactionService(getIt(), getIt(), getIt()));
  getIt.registerLazySingleton(() => SubscriptionService(getIt(), getIt(), getIt(), getIt()));
  getIt.registerLazySingleton(() => AnalyticsService(getIt(), getIt(), getIt()));
  getIt.registerLazySingleton(() => ThemeProvider(getIt()));
  getIt.registerLazySingleton(() => CurrencyProvider());
  getIt.registerLazySingleton(() => ProStatusProvider());
}