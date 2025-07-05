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
  getIt.registerLazySingleton<ThemeRepository>(() => LocalThemeRepositoryImpl(getIt()));

  _registerRepositories();

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

void _registerRepositories() {
  _registerFactory<BudgetRepository>(
    local: () => LocalBudgetRepositoryImpl(getIt(), getIt(), getIt()),
    supabase: () => SupabaseBudgetRepositoryImpl(getIt()),
  );
  _registerFactory<CategoryRepository>(
    local: () => LocalCategoryRepositoryImpl(getIt()),
    supabase: () => SupabaseCategoryRepositoryImpl(getIt()),
  );
  _registerFactory<DebtLoanRepository>(
    local: () => LocalDebtLoanRepositoryImpl(getIt()),
    supabase: () => SupabaseDebtLoanRepositoryImpl(getIt()),
  );
  _registerFactory<GoalRepository>(
    local: () => LocalGoalRepositoryImpl(getIt(), getIt(), getIt()),
    supabase: () => SupabaseGoalRepositoryImpl(getIt()),
  );
  _registerFactory<InvitationRepository>(
    local: () => LocalInvitationRepositoryImpl(),
    supabase: () => SupabaseInvitationRepositoryImpl(getIt()),
  );
  _registerFactory<NotificationRepository>(
    local: () => LocalNotificationRepositoryImpl(getIt()),
    supabase: () => SupabaseNotificationRepositoryImpl(),
  );
  _registerFactory<PlanRepository>(
    local: () => LocalPlanRepositoryImpl(getIt()),
    supabase: () => SupabasePlanRepositoryImpl(getIt()),
  );
  _registerFactory<RepeatingTransactionRepository>(
    local: () => LocalRepeatingTransactionRepositoryImpl(getIt()),
    supabase: () => SupabaseRepeatingTransactionRepositoryImpl(getIt()),
  );
  _registerFactory<SubscriptionRepository>(
    local: () => LocalSubscriptionRepositoryImpl(getIt()),
    supabase: () => SupabaseSubscriptionRepositoryImpl(getIt()),
  );
  _registerFactory<TransactionRepository>(
    local: () => LocalTransactionRepositoryImpl(getIt(), getIt()),
    supabase: () => SupabaseTransactionRepositoryImpl(getIt()),
  );
  _registerFactory<UserRepository>(
    local: () => LocalUserRepositoryImpl(getIt()),
    supabase: () => SupabaseUserRepositoryImpl(getIt()),
  );
  _registerFactory<WalletRepository>(
    local: () => LocalWalletRepositoryImpl(getIt()),
    supabase: () => SupabaseWalletRepositoryImpl(getIt()),
  );
}

void _registerFactory<T extends Object>({
  required T Function() local,
  required T Function() supabase,
}) {
  getIt.registerFactory<T>(() {
    final appMode = getIt<AppModeProvider>();
    if (appMode.isOnline) {
      return supabase();
    } else {
      return local();
    }
  });
}