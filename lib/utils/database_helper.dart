import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  DatabaseHelper._internal();

  static const String _dbName = "finance_app.db";
  static const int _dbVersion = 17;

  static const String tableWallets = "wallets";
  static const String colWalletId = "id";
  static const String colWalletName = "name";
  static const String colWalletIsDefault = "isDefault";
  static const String colWalletOwnerUserId = "ownerUserId";
  static const String colWalletUpdatedAt = "updated_at";
  static const String colWalletIsDeleted = "is_deleted";

  static const String tableUsers = "users";
  static const String colUserId = "id";
  static const String colUserName = "name";
  static const String colUserUpdatedAt = "updated_at";

  static const String tableWalletUsers = "wallet_users";
  static const String colWalletUsersWalletId = "walletId";
  static const String colWalletUsersUserId = "userId";
  static const String colWalletUsersRole = "role";

  static const String tableCategories = "categories";
  static const String colCategoryId = "id";
  static const String colCategoryName = "name";
  static const String colCategoryType = "type";
  static const String colCategoryBucket = "bucket";
  static const String colCategoryWalletId = "walletId";
  static const String colCategoryUpdatedAt = "updated_at";
  static const String colCategoryIsDeleted = "is_deleted";

  static const String tableTransactions = "transactions";
  static const String colTransactionId = "id";
  static const String colTransactionType = "type";
  static const String colTransactionOriginalAmount = "originalAmount";
  static const String colTransactionOriginalCurrencyCode = "originalCurrencyCode";
  static const String colTransactionAmountInBaseCurrency = "amountInBaseCurrency";
  static const String colTransactionExchangeRateUsed = "exchangeRateUsed";
  static const String colTransactionCategoryId = "categoryId";
  static const String colTransactionDate = "date";
  static const String colTransactionDescription = "description";
  static const String colTransactionLinkedGoalId = "linkedGoalId";
  static const String colTransactionSubscriptionId = "subscriptionId";
  static const String colTransactionLinkedTransferId = "linkedTransferId";
  static const String colTransactionWalletId = "walletId";
  static const String colTransactionUpdatedAt = "updated_at";
  static const String colTransactionIsDeleted = "is_deleted";

  static const String tablePlans = "plans";
  static const String colPlanId = "id";
  static const String colPlanCategoryId = "categoryId";
  static const String colPlanOriginalAmount = "originalPlannedAmount";
  static const String colPlanOriginalCurrencyCode = "originalCurrencyCode";
  static const String colPlanAmountInBaseCurrency = "plannedAmountInBaseCurrency";
  static const String colPlanExchangeRateUsed = "exchangeRateUsed";
  static const String colPlanStartDate = "startDate";
  static const String colPlanEndDate = "endDate";
  static const String colPlanWalletId = "walletId";
  static const String colPlanUpdatedAt = "updated_at";
  static const String colPlanIsDeleted = "is_deleted";

  static const String tableRepeatingTransactions = "repeating_transactions";
  static const String colRtId = "id";
  static const String colRtDescription = "description";
  static const String colRtOriginalAmount = "originalAmount";
  static const String colRtOriginalCurrencyCode = "originalCurrencyCode";
  static const String colRtCategoryId = "categoryId";
  static const String colRtType = "type";
  static const String colRtFrequency = "frequency";
  static const String colRtInterval = "interval";
  static const String colRtStartDate = "startDate";
  static const String colRtEndDate = "endDate";
  static const String colRtOccurrences = "occurrences";
  static const String colRtGeneratedOccurrencesCount = "generatedOccurrencesCount";
  static const String colRtNextDueDate = "nextDueDate";
  static const String colRtIsActive = "isActive";
  static const String colRtWeekDays = "weekDays";
  static const String colRtMonthDay = "monthDay";
  static const String colRtYearMonth = "yearMonth";
  static const String colRtYearDay = "yearDay";
  static const String colRtWalletId = "walletId";
  static const String colRtUpdatedAt = "updated_at";
  static const String colRtIsDeleted = "is_deleted";

  static const String tableFinancialGoals = "financial_goals";
  static const String colGoalId = "id";
  static const String colGoalName = "name";
  static const String colGoalOriginalTargetAmount = "originalTargetAmount";
  static const String colGoalOriginalCurrentAmount = "originalCurrentAmount";
  static const String colGoalCurrencyCode = "currencyCode";
  static const String colGoalExchangeRateUsed = "exchangeRateUsed";
  static const String colGoalTargetAmountInBaseCurrency = "targetAmountInBaseCurrency";
  static const String colGoalCurrentAmountInBaseCurrency = "currentAmountInBaseCurrency";
  static const String colGoalTargetDate = "targetDate";
  static const String colGoalCreationDate = "creationDate";
  static const String colGoalIconName = "iconName";
  static const String colGoalNotes = "notes";
  static const String colGoalIsAchieved = "isAchieved";
  static const String colGoalWalletId = "walletId";
  static const String colGoalUpdatedAt = "updated_at";
  static const String colGoalIsDeleted = "is_deleted";

  static const String tableSubscriptions = "subscriptions";
  static const String colSubId = "id";
  static const String colSubName = "name";
  static const String colSubAmount = "amount";
  static const String colSubCurrencyCode = "currencyCode";
  static const String colSubBillingCycle = "billingCycle";
  static const String colSubNextPaymentDate = "nextPaymentDate";
  static const String colSubStartDate = "startDate";
  static const String colSubCategoryId = "categoryId";
  static const String colSubPaymentMethod = "paymentMethod";
  static const String colSubNotes = "notes";
  static const String colSubIsActive = "isActive";
  static const String colSubWebsite = "website";
  static const String colSubReminderDaysBefore = "reminderDaysBefore";
  static const String colSubWalletId = "walletId";
  static const String colSubUpdatedAt = "updated_at";
  static const String colSubIsDeleted = "is_deleted";

  static const String tableBudgets = "budgets";
  static const String colBudgetId = "id";
  static const String colBudgetName = "name";
  static const String colBudgetStartDate = "startDate";
  static const String colBudgetEndDate = "endDate";
  static const String colBudgetStrategyType = "strategyType";
  static const String colBudgetPlannedIncome = "plannedIncomeInBaseCurrency";
  static const String colBudgetIsActive = "isActive";
  static const String colBudgetWalletId = "walletId";
  static const String colBudgetUpdatedAt = "updated_at";
  static const String colBudgetIsDeleted = "is_deleted";

  static const String tableBudgetEnvelopes = "budget_envelopes";
  static const String colEnvelopeId = "id";
  static const String colEnvelopeBudgetId = "budgetId";
  static const String colEnvelopeName = "name";
  static const String colEnvelopeCategoryId = "categoryId";
  static const String colEnvelopeOriginalAmount = "originalPlannedAmount";
  static const String colEnvelopeCurrencyCode = "originalCurrencyCode";
  static const String colEnvelopeAmountInBase = "plannedAmountInBaseCurrency";
  static const String colEnvelopeExchangeRate = "exchangeRateUsed";
  static const String colEnvelopeUpdatedAt = "updated_at";
  static const String colEnvelopeIsDeleted = "is_deleted";

  static const String tableDebtsLoans = "debts_loans";
  static const String colDebtLoanId = "id";
  static const String colDebtLoanWalletId = "walletId";
  static const String colDebtLoanType = "type";
  static const String colDebtLoanPersonName = "personName";
  static const String colDebtLoanDescription = "description";
  static const String colDebtLoanOriginalAmount = "originalAmount";
  static const String colDebtLoanCurrencyCode = "currencyCode";
  static const String colDebtLoanAmountInBase = "amountInBaseCurrency";
  static const String colDebtLoanCreationDate = "creationDate";
  static const String colDebtLoanDueDate = "dueDate";
  static const String colDebtLoanIsSettled = "isSettled";
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
      onUpgrade: _onUpgrade,
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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    var batch = db.batch();
    if (oldVersion < 17) {
      batch.execute('ALTER TABLE $tableWallets ADD COLUMN $colWalletUpdatedAt TEXT;');
      batch.execute('ALTER TABLE $tableWallets ADD COLUMN $colWalletIsDeleted INTEGER NOT NULL DEFAULT 0;');
      batch.execute('ALTER TABLE $tableCategories ADD COLUMN $colCategoryUpdatedAt TEXT;');
      batch.execute('ALTER TABLE $tableCategories ADD COLUMN $colCategoryIsDeleted INTEGER NOT NULL DEFAULT 0;');
      batch.execute('ALTER TABLE $tableTransactions ADD COLUMN $colTransactionUpdatedAt TEXT;');
      batch.execute('ALTER TABLE $tableTransactions ADD COLUMN $colTransactionIsDeleted INTEGER NOT NULL DEFAULT 0;');
      
      await _createSyncQueueTable(db);
    }
    await batch.commit();
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
        $colUserName TEXT NOT NULL,
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
        $colTransactionLinkedGoalId INTEGER,
        $colTransactionSubscriptionId INTEGER,
        $colTransactionLinkedTransferId INTEGER,
        $colTransactionWalletId INTEGER,
        $colTransactionUpdatedAt TEXT,
        $colTransactionIsDeleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }
    
  Future<void> _createPlansTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tablePlans (
        $colPlanId INTEGER PRIMARY KEY AUTOINCREMENT,
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
        $colRtId INTEGER PRIMARY KEY AUTOINCREMENT,
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
        $colGoalId INTEGER PRIMARY KEY AUTOINCREMENT,
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
        $colSubId INTEGER PRIMARY KEY AUTOINCREMENT,
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
        $colSubReminderDaysBefore INTEGER DEFAULT 1,
        $colSubWalletId INTEGER,
        $colSubUpdatedAt TEXT,
        $colSubIsDeleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createBudgetsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableBudgets (
        $colBudgetId INTEGER PRIMARY KEY AUTOINCREMENT,
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
        $colEnvelopeId INTEGER PRIMARY KEY AUTOINCREMENT,
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
        $colDebtLoanId INTEGER PRIMARY KEY AUTOINCREMENT,
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
        $colNotificationId INTEGER PRIMARY KEY AUTOINCREMENT,
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
      tableBudgets, tableBudgetEnvelopes, tableDebtsLoans, tableNotificationHistory, tableThemeProfiles
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
      final tablesInOrder = [
        tableBudgetEnvelopes, tableBudgets, tableSubscriptions, tableTransactions,
        tableRepeatingTransactions, tablePlans, tableFinancialGoals, tableDebtsLoans,
        tableCategories, tableWalletUsers, tableWallets, tableUsers, tableNotificationHistory,
        tableThemeProfiles
      ];
      for (String tableName in tablesInOrder) {
        batch.delete(tableName);
      }
      final List<dynamic> themeProfiles = jsonData[tableThemeProfiles] ?? [];
      for (var itemMap in themeProfiles) {
        batch.insert(tableThemeProfiles, Map<String, dynamic>.from(itemMap), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final List<dynamic> users = jsonData[tableUsers] ?? [];
      for (var itemMap in users) {
        batch.insert(tableUsers, Map<String, dynamic>.from(itemMap), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final List<dynamic> wallets = jsonData[tableWallets] ?? [];
      for (var itemMap in wallets) {
        batch.insert(tableWallets, Map<String, dynamic>.from(itemMap), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final List<dynamic> walletUsers = jsonData[tableWalletUsers] ?? [];
      for (var itemMap in walletUsers) {
        batch.insert(tableWalletUsers, Map<String, dynamic>.from(itemMap), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final List<dynamic> categories = jsonData[tableCategories] ?? [];
      for (var itemMap in categories) {
        batch.insert(tableCategories, Map<String, dynamic>.from(itemMap), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final List<dynamic> financialGoals = jsonData[tableFinancialGoals] ?? [];
      for (var itemMap in financialGoals) {
        batch.insert(tableFinancialGoals, Map<String, dynamic>.from(itemMap), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final List<dynamic> budgets = jsonData[tableBudgets] ?? [];
      for (var itemMap in budgets) {
        batch.insert(tableBudgets, Map<String, dynamic>.from(itemMap), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final List<dynamic> budgetEnvelopes = jsonData[tableBudgetEnvelopes] ?? [];
      for (var itemMap in budgetEnvelopes) {
        batch.insert(tableBudgetEnvelopes, Map<String, dynamic>.from(itemMap), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final List<dynamic> debtsLoans = jsonData[tableDebtsLoans] ?? [];
      for (var itemMap in debtsLoans) {
        batch.insert(tableDebtsLoans, Map<String, dynamic>.from(itemMap), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final List<dynamic> transactions = jsonData[tableTransactions] ?? [];
      for (var itemMap in transactions) {
        Map<String, dynamic> typedMap = Map<String, dynamic>.from(itemMap);
        batch.insert(tableTransactions, typedMap, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final List<dynamic> plans = jsonData[tablePlans] ?? [];
      for (var itemMap in plans) {
        batch.insert(tablePlans, Map<String, dynamic>.from(itemMap), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final List<dynamic> repeatingTransactions = jsonData[tableRepeatingTransactions] ?? [];
      for (var itemMap in repeatingTransactions) {
        batch.insert(tableRepeatingTransactions, Map<String, dynamic>.from(itemMap), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final List<dynamic> subscriptions = jsonData[tableSubscriptions] ?? [];
      for (var itemMap in subscriptions) {
        batch.insert(tableSubscriptions, Map<String, dynamic>.from(itemMap), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final List<dynamic> notificationHistory = jsonData[tableNotificationHistory] ?? [];
      for (var itemMap in notificationHistory) {
        batch.insert(tableNotificationHistory, Map<String, dynamic>.from(itemMap), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}