import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  DatabaseHelper._internal();

  static const String _dbName = "finance_app.db";
  static const int _dbVersion = 1;

  static const String tableWallets = "wallets";
  static const String colWalletId = "id";
  static const String colWalletName = "name";
  static const String colWalletIsDefault = "is_default";
  static const String colWalletOwnerUserId = "owner_user_id";
  static const String colWalletUpdatedAt = "updated_at";
  static const String colWalletIsDeleted = "is_deleted";

  static const String tableUsers = "users";
  static const String colUserId = "id";
  static const String colUserName = "username";
  static const String colUserEmail = "email";
  static const String colUserUpdatedAt = "updated_at";

  static const String tableWalletUsers = "wallet_users";
  static const String colWalletUsersWalletId = "wallet_id";
  static const String colWalletUsersUserId = "user_id";
  static const String colWalletUsersRole = "role";

  static const String tableCategories = "categories";
  static const String colCategoryId = "id";
  static const String colCategoryName = "name";
  static const String colCategoryType = "type";
  static const String colCategoryBucket = "bucket";
  static const String colCategoryWalletId = "wallet_id";
  static const String colCategoryUserId = "user_id";
  static const String colCategoryUpdatedAt = "updated_at";
  static const String colCategoryIsDeleted = "is_deleted";

  static const String tableTransactions = "transactions";
  static const String colTransactionId = "id";
  static const String colTransactionType = "type";
  static const String colTransactionOriginalAmount = "original_amount";
  static const String colTransactionOriginalCurrencyCode = "original_currency_code";
  static const String colTransactionAmountInBaseCurrency = "amount_in_base_currency";
  static const String colTransactionExchangeRateUsed = "exchange_rate_used";
  static const String colTransactionCategoryId = "category_id";
  static const String colTransactionDate = "date";
  static const String colTransactionDescription = "description";
  static const String colTransactionLinkedGoalId = "linked_goal_id";
  static const String colTransactionSubscriptionId = "subscription_id";
  static const String colTransactionLinkedTransferId = "linked_transfer_id";
  static const String colTransactionWalletId = "wallet_id";
  static const String colTransactionUserId = "user_id";
  static const String colTransactionUpdatedAt = "updated_at";
  static const String colTransactionIsDeleted = "is_deleted";

  static const String tablePlans = "plans";
  static const String colPlanId = "id";
  static const String colPlanCategoryId = "category_id";
  static const String colPlanOriginalAmount = "original_planned_amount";
  static const String colPlanOriginalCurrencyCode = "original_currency_code";
  static const String colPlanAmountInBaseCurrency = "planned_amount_in_base_currency";
  static const String colPlanExchangeRateUsed = "exchange_rate_used";
  static const String colPlanStartDate = "start_date";
  static const String colPlanEndDate = "end_date";
  static const String colPlanWalletId = "wallet_id";
  static const String colPlanUpdatedAt = "updated_at";
  static const String colPlanIsDeleted = "is_deleted";

  static const String tableRepeatingTransactions = "repeating_transactions";
  static const String colRtId = "id";
  static const String colRtDescription = "description";
  static const String colRtOriginalAmount = "original_amount";
  static const String colRtOriginalCurrencyCode = "original_currency_code";
  static const String colRtCategoryId = "category_id";
  static const String colRtType = "type";
  static const String colRtFrequency = "frequency";
  static const String colRtInterval = "interval";
  static const String colRtStartDate = "start_date";
  static const String colRtEndDate = "end_date";
  static const String colRtOccurrences = "occurrences";
  static const String colRtGeneratedOccurrencesCount = "generated_occurrences_count";
  static const String colRtNextDueDate = "next_due_date";
  static const String colRtIsActive = "is_active";
  static const String colRtWeekDays = "week_days";
  static const String colRtMonthDay = "month_day";
  static const String colRtYearMonth = "year_month";
  static const String colRtYearDay = "year_day";
  static const String colRtWalletId = "wallet_id";
  static const String colRtUpdatedAt = "updated_at";
  static const String colRtIsDeleted = "is_deleted";

  static const String tableFinancialGoals = "financial_goals";
  static const String colGoalId = "id";
  static const String colGoalName = "name";
  static const String colGoalOriginalTargetAmount = "original_target_amount";
  static const String colGoalOriginalCurrentAmount = "original_current_amount";
  static const String colGoalCurrencyCode = "currency_code";
  static const String colGoalExchangeRateUsed = "exchange_rate_used";
  static const String colGoalTargetAmountInBaseCurrency = "target_amount_in_base_currency";
  static const String colGoalCurrentAmountInBaseCurrency = "current_amount_in_base_currency";
  static const String colGoalTargetDate = "target_date";
  static const String colGoalCreationDate = "creation_date";
  static const String colGoalIconName = "icon_name";
  static const String colGoalNotes = "notes";
  static const String colGoalIsAchieved = "is_achieved";
  static const String colGoalWalletId = "wallet_id";
  static const String colGoalUpdatedAt = "updated_at";
  static const String colGoalIsDeleted = "is_deleted";

  static const String tableSubscriptions = "subscriptions";
  static const String colSubId = "id";
  static const String colSubName = "name";
  static const String colSubAmount = "amount";
  static const String colSubCurrencyCode = "currency_code";
  static const String colSubBillingCycle = "billing_cycle";
  static const String colSubNextPaymentDate = "next_payment_date";
  static const String colSubStartDate = "start_date";
  static const String colSubCategoryId = "category_id";
  static const String colSubPaymentMethod = "payment_method";
  static const String colSubNotes = "notes";
  static const String colSubIsActive = "is_active";
  static const String colSubWebsite = "website";
  static const String colSubReminderDaysBefore = "reminder_days_before";
  static const String colSubWalletId = "wallet_id";
  static const String colSubUpdatedAt = "updated_at";
  static const String colSubIsDeleted = "is_deleted";

  static const String tableBudgets = "budgets";
  static const String colBudgetId = "id";
  static const String colBudgetName = "name";
  static const String colBudgetStartDate = "start_date";
  static const String colBudgetEndDate = "end_date";
  static const String colBudgetStrategyType = "strategy_type";
  static const String colBudgetPlannedIncome = "planned_income_in_base_currency";
  static const String colBudgetIsActive = "is_active";
  static const String colBudgetWalletId = "wallet_id";
  static const String colBudgetUpdatedAt = "updated_at";
  static const String colBudgetIsDeleted = "is_deleted";

  static const String tableBudgetEnvelopes = "budget_envelopes";
  static const String colEnvelopeId = "id";
  static const String colEnvelopeBudgetId = "budget_id";
  static const String colEnvelopeName = "name";
  static const String colEnvelopeCategoryId = "category_id";
  static const String colEnvelopeOriginalAmount = "original_planned_amount";
  static const String colEnvelopeCurrencyCode = "original_currency_code";
  static const String colEnvelopeAmountInBase = "planned_amount_in_base_currency";
  static const String colEnvelopeExchangeRate = "exchange_rate_used";
  static const String colEnvelopeUpdatedAt = "updated_at";
  static const String colEnvelopeIsDeleted = "is_deleted";

  static const String tableDebtsLoans = "debts_loans";
  static const String colDebtLoanId = "id";
  static const String colDebtLoanWalletId = "wallet_id";
  static const String colDebtLoanType = "type";
  static const String colDebtLoanPersonName = "person_name";
  static const String colDebtLoanDescription = "description";
  static const String colDebtLoanOriginalAmount = "original_amount";
  static const String colDebtLoanCurrencyCode = "currency_code";
  static const String colDebtLoanAmountInBase = "amount_in_base_currency";
  static const String colDebtLoanCreationDate = "creation_date";
  static const String colDebtLoanDueDate = "due_date";
  static const String colDebtLoanIsSettled = "is_settled";
  static const String colDebtLoanUpdatedAt = "updated_at";
  static const String colDebtLoanIsDeleted = "is_deleted";

  static const String tableNotificationHistory = "notification_history";
  static const String colNotificationId = "id";
  static const String colNotificationTitle = "title";
  static const String colNotificationBody = "body";
  static const String colNotificationPayload = "payload";
  static const String colNotificationTimestamp = "timestamp";
  static const String colNotificationIsRead = "isRead";

  static const String tableThemeProfiles = "theme_profiles";
  static const String colProfileName = "name";
  static const String colProfileSeedColor = "seedColor";
  static const String colProfileFontFamily = "fontFamily";
  static const String colProfileBorderRadius = "borderRadius";

  static const String tableSyncQueue = "sync_queue";
  static const String colSyncId = "id";
  static const String colSyncEntityType = "entity_type";
  static const String colSyncEntityId = "entity_id";
  static const String colSyncActionType = "action_type";
  static const String colSyncPayload = "payload";
  static const String colSyncTimestamp = "timestamp";
  static const String colSyncStatus = "status";

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onDowngrade: onDatabaseDowngradeDelete,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createUsersTable(db);
    await _createWalletsTable(db);
    await _createWalletUsersTable(db);
    await _createCategoriesTable(db);
    await _createTransactionsTable(db);
    await _createPlansTable(db);
    await _createRepeatingTransactionsTable(db);
    await _createFinancialGoalsTable(db);
    await _createSubscriptionsTable(db);
    await _createBudgetsTable(db);
    await _createBudgetEnvelopesTable(db);
    await _createDebtsLoansTable(db);
    await _createNotificationHistoryTable(db);
    await _createThemeProfilesTable(db);
    await _createSyncQueueTable(db);
  }

  Future<void> _createSyncQueueTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableSyncQueue (
        $colSyncId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colSyncEntityType TEXT NOT NULL,
        $colSyncEntityId TEXT NOT NULL,
        $colSyncActionType TEXT NOT NULL,
        $colSyncPayload TEXT,
        $colSyncTimestamp TEXT NOT NULL,
        $colSyncStatus TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableUsers (
        $colUserId TEXT PRIMARY KEY,
        $colUserName TEXT,
        $colUserEmail TEXT,
        $colUserUpdatedAt TEXT
      )
    ''');
  }

  Future<void> _createWalletsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableWallets (
        $colWalletId INTEGER PRIMARY KEY,
        $colWalletName TEXT NOT NULL,
        $colWalletIsDefault INTEGER NOT NULL DEFAULT 0,
        $colWalletOwnerUserId TEXT NOT NULL,
        $colWalletUpdatedAt TEXT,
        $colWalletIsDeleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createWalletUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableWalletUsers (
        $colWalletUsersWalletId INTEGER NOT NULL,
        $colWalletUsersUserId TEXT NOT NULL,
        $colWalletUsersRole TEXT NOT NULL,
        PRIMARY KEY ($colWalletUsersWalletId, $colWalletUsersUserId)
      )
    ''');
  }

  Future<void> _createCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableCategories (
        $colCategoryId INTEGER PRIMARY KEY,
        $colCategoryName TEXT NOT NULL,
        $colCategoryType TEXT NOT NULL,
        $colCategoryBucket TEXT,
        $colCategoryWalletId INTEGER,
        $colCategoryUserId TEXT,
        $colCategoryUpdatedAt TEXT,
        $colCategoryIsDeleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createTransactionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableTransactions (
        $colTransactionId INTEGER PRIMARY KEY,
        $colTransactionType TEXT NOT NULL,
        $colTransactionOriginalAmount REAL NOT NULL,
        $colTransactionOriginalCurrencyCode TEXT NOT NULL,
        $colTransactionAmountInBaseCurrency REAL NOT NULL,
        $colTransactionExchangeRateUsed REAL,
        $colTransactionCategoryId INTEGER NOT NULL,
        $colTransactionDate TEXT NOT NULL,
        $colTransactionDescription TEXT,
        $colTransactionWalletId INTEGER,
        $colTransactionUserId TEXT,
        $colTransactionLinkedGoalId INTEGER,
        $colTransactionSubscriptionId INTEGER,
        $colTransactionLinkedTransferId INTEGER,
        $colTransactionUpdatedAt TEXT,
        $colTransactionIsDeleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }
    
  Future<void> _createPlansTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tablePlans (
        $colPlanId INTEGER PRIMARY KEY,
        $colPlanCategoryId INTEGER NOT NULL,
        $colPlanOriginalAmount REAL NOT NULL,
        $colPlanOriginalCurrencyCode TEXT NOT NULL,
        $colPlanAmountInBaseCurrency REAL NOT NULL,
        $colPlanExchangeRateUsed REAL,
        $colPlanStartDate TEXT NOT NULL,
        $colPlanEndDate TEXT NOT NULL,
        $colPlanWalletId INTEGER,
        $colPlanUpdatedAt TEXT,
        $colPlanIsDeleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createRepeatingTransactionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableRepeatingTransactions (
        $colRtId INTEGER PRIMARY KEY,
        $colRtDescription TEXT NOT NULL,
        $colRtOriginalAmount REAL NOT NULL,
        $colRtOriginalCurrencyCode TEXT NOT NULL,
        $colRtCategoryId INTEGER NOT NULL,
        $colRtType TEXT NOT NULL,
        $colRtFrequency TEXT NOT NULL,
        $colRtInterval INTEGER NOT NULL DEFAULT 1,
        $colRtStartDate TEXT NOT NULL,
        $colRtEndDate TEXT,
        $colRtOccurrences INTEGER,
        $colRtGeneratedOccurrencesCount INTEGER DEFAULT 0,
        $colRtNextDueDate TEXT NOT NULL,
        $colRtIsActive INTEGER NOT NULL DEFAULT 1,
        $colRtWeekDays TEXT,
        $colRtMonthDay TEXT,
        $colRtYearMonth INTEGER,
        $colRtYearDay INTEGER,
        $colRtWalletId INTEGER,
        $colRtUpdatedAt TEXT,
        $colRtIsDeleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createFinancialGoalsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableFinancialGoals (
        $colGoalId INTEGER PRIMARY KEY,
        $colGoalName TEXT NOT NULL,
        $colGoalOriginalTargetAmount REAL NOT NULL,
        $colGoalOriginalCurrentAmount REAL NOT NULL,
        $colGoalCurrencyCode TEXT NOT NULL,
        $colGoalExchangeRateUsed REAL,
        $colGoalTargetAmountInBaseCurrency REAL NOT NULL,
        $colGoalCurrentAmountInBaseCurrency REAL NOT NULL,
        $colGoalTargetDate TEXT,
        $colGoalCreationDate TEXT NOT NULL,
        $colGoalIconName TEXT,
        $colGoalNotes TEXT,
        $colGoalIsAchieved INTEGER NOT NULL DEFAULT 0,
        $colGoalWalletId INTEGER,
        $colGoalUpdatedAt TEXT,
        $colGoalIsDeleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createSubscriptionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableSubscriptions (
        $colSubId INTEGER PRIMARY KEY,
        $colSubName TEXT NOT NULL,
        $colSubAmount REAL NOT NULL,
        $colSubCurrencyCode TEXT NOT NULL,
        $colSubBillingCycle TEXT NOT NULL,
        $colSubNextPaymentDate TEXT NOT NULL,
        $colSubStartDate TEXT NOT NULL,
        $colSubCategoryId INTEGER,
        $colSubPaymentMethod TEXT,
        $colSubNotes TEXT,
        $colSubIsActive INTEGER NOT NULL DEFAULT 1,
        $colSubWebsite TEXT,
        $colSubReminderDaysBefore INTEGER,
        $colSubWalletId INTEGER,
        $colSubUpdatedAt TEXT,
        $colSubIsDeleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createBudgetsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableBudgets (
        $colBudgetId INTEGER PRIMARY KEY,
        $colBudgetName TEXT NOT NULL,
        $colBudgetStartDate TEXT NOT NULL,
        $colBudgetEndDate TEXT NOT NULL,
        $colBudgetStrategyType TEXT NOT NULL,
        $colBudgetPlannedIncome REAL,
        $colBudgetIsActive INTEGER NOT NULL DEFAULT 1,
        $colBudgetWalletId INTEGER,
        $colBudgetUpdatedAt TEXT,
        $colBudgetIsDeleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createBudgetEnvelopesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableBudgetEnvelopes (
        $colEnvelopeId INTEGER PRIMARY KEY,
        $colEnvelopeBudgetId INTEGER NOT NULL,
        $colEnvelopeName TEXT NOT NULL,
        $colEnvelopeCategoryId INTEGER NOT NULL,
        $colEnvelopeOriginalAmount REAL NOT NULL,
        $colEnvelopeCurrencyCode TEXT NOT NULL,
        $colEnvelopeAmountInBase REAL NOT NULL,
        $colEnvelopeExchangeRate REAL,
        $colEnvelopeUpdatedAt TEXT,
        $colEnvelopeIsDeleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createDebtsLoansTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableDebtsLoans (
        $colDebtLoanId INTEGER PRIMARY KEY,
        $colDebtLoanWalletId INTEGER NOT NULL,
        $colDebtLoanType TEXT NOT NULL,
        $colDebtLoanPersonName TEXT NOT NULL,
        $colDebtLoanDescription TEXT,
        $colDebtLoanOriginalAmount REAL NOT NULL,
        $colDebtLoanCurrencyCode TEXT NOT NULL,
        $colDebtLoanAmountInBase REAL NOT NULL,
        $colDebtLoanCreationDate TEXT NOT NULL,
        $colDebtLoanDueDate TEXT,
        $colDebtLoanIsSettled INTEGER NOT NULL DEFAULT 0,
        $colDebtLoanUpdatedAt TEXT,
        $colDebtLoanIsDeleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }
  
  Future<void> _createNotificationHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableNotificationHistory (
        $colNotificationId INTEGER PRIMARY KEY,
        $colNotificationTitle TEXT NOT NULL,
        $colNotificationBody TEXT NOT NULL,
        $colNotificationPayload TEXT,
        $colNotificationTimestamp TEXT NOT NULL,
        $colNotificationIsRead INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createThemeProfilesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableThemeProfiles (
        $colProfileName TEXT PRIMARY KEY,
        $colProfileSeedColor INTEGER NOT NULL,
        $colProfileFontFamily TEXT NOT NULL,
        $colProfileBorderRadius REAL NOT NULL
      )
    ''');
  }

  Future<Map<String, List<Map<String, dynamic>>>> exportDatabaseToJson() async {
    final db = await database;
    final tables = [
      tableUsers, tableWallets, tableWalletUsers, tableCategories, tableTransactions,
      tablePlans, tableRepeatingTransactions, tableFinancialGoals, tableSubscriptions,
      tableBudgets, tableBudgetEnvelopes, tableDebtsLoans, tableNotificationHistory,
      tableThemeProfiles
    ];
    final Map<String, List<Map<String, dynamic>>> jsonData = {};
    for (String tableName in tables) {
      jsonData[tableName] = await db.query(tableName);
    }
    return jsonData;
  }

  Future<void> importDatabaseFromJson(Map<String, dynamic> jsonData) async {
    final db = await database;
    await db.transaction((txn) async {
      Batch batch = txn.batch();
      final tablesInDeletionOrder = [
        tableBudgetEnvelopes, tableBudgets, tableSubscriptions, tableTransactions,
        tableRepeatingTransactions, tablePlans, tableFinancialGoals, tableDebtsLoans,
        tableCategories, tableWalletUsers, tableWallets, tableUsers, tableNotificationHistory,
        tableThemeProfiles
      ];
      final tablesInCreationOrder = tablesInDeletionOrder.reversed.toList();

      for (String tableName in tablesInDeletionOrder) {
        batch.delete(tableName);
      }

      for (String tableName in tablesInCreationOrder) {
        final List<dynamic> tableData = jsonData[tableName] ?? [];
        for (var itemMap in tableData) {
          batch.insert(tableName, Map<String, dynamic>.from(itemMap),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      await batch.commit(noResult: true);
    });
  }
}