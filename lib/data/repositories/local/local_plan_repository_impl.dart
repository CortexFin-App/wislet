import 'package:intl/intl.dart';
import 'package:sage_wallet_reborn/models/plan.dart';
import 'package:sage_wallet_reborn/models/plan_view_data.dart';
import 'package:sage_wallet_reborn/utils/database_helper.dart';
import 'package:sage_wallet_reborn/data/repositories/plan_repository.dart';

class LocalPlanRepositoryImpl implements PlanRepository {
  final DatabaseHelper _dbHelper;

  LocalPlanRepositoryImpl(this._dbHelper);

  @override
  Future<int> createPlan(Plan plan, int walletId) async {
    final db = await _dbHelper.database;
    final map = plan.toMap();
    map[DatabaseHelper.colPlanWalletId] = walletId;
    return await db.insert(DatabaseHelper.tablePlans, map);
  }

  @override
  Future<int> updatePlan(Plan plan) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tablePlans,
      plan.toMap(),
      where: '${DatabaseHelper.colPlanId} = ?',
      whereArgs: [plan.id],
    );
  }

  @override
  Future<int> deletePlan(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tablePlans,
      where: '${DatabaseHelper.colPlanId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<Plan>> getPlansForPeriod(int walletId, DateTime startDate, DateTime endDate) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tablePlans,
      where: '${DatabaseHelper.colPlanWalletId} = ? AND date(${DatabaseHelper.colPlanStartDate}) <= date(?) AND date(${DatabaseHelper.colPlanEndDate}) >= date(?)',
      whereArgs: [walletId, endDate.toIso8601String(), startDate.toIso8601String()],
    );
    return maps.map((map) => Plan.fromMap(map)).toList();
  }

  @override
  Future<List<PlanViewData>> getPlansWithCategoryDetails(int walletId, {String? orderBy}) async {
    final db = await _dbHelper.database;
    const String defaultOrderBy = "p.${DatabaseHelper.colPlanStartDate} DESC, c.${DatabaseHelper.colCategoryName} ASC, p.${DatabaseHelper.colPlanId} DESC";
    final String sql = '''
      SELECT 
        p.${DatabaseHelper.colPlanId}, p.${DatabaseHelper.colPlanCategoryId}, p.${DatabaseHelper.colPlanOriginalAmount},
        p.${DatabaseHelper.colPlanOriginalCurrencyCode}, p.${DatabaseHelper.colPlanAmountInBaseCurrency},
        p.${DatabaseHelper.colPlanExchangeRateUsed}, p.${DatabaseHelper.colPlanStartDate}, p.${DatabaseHelper.colPlanEndDate}, 
        c.${DatabaseHelper.colCategoryName} AS categoryName, c.${DatabaseHelper.colCategoryType} AS categoryType 
      FROM ${DatabaseHelper.tablePlans} p
      INNER JOIN ${DatabaseHelper.tableCategories} c ON p.${DatabaseHelper.colPlanCategoryId} = c.${DatabaseHelper.colCategoryId}
      WHERE p.${DatabaseHelper.colPlanWalletId} = ?
      ORDER BY ${orderBy ?? defaultOrderBy}
    ''';
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, [walletId]);
    return maps.map((map) => PlanViewData.fromMap(map)).toList();
  }
  
  @override
  Future<List<PlanViewData>> getActivePlansForCategoryAndDate(int walletId, int categoryId, DateTime date) async {
    final db = await _dbHelper.database;
    final String dateOnlyString = DateFormat('yyyy-MM-dd').format(date);
    const String sql = '''
      SELECT 
        p.${DatabaseHelper.colPlanId}, 
        p.${DatabaseHelper.colPlanCategoryId}, 
        p.${DatabaseHelper.colPlanOriginalAmount},
        p.${DatabaseHelper.colPlanOriginalCurrencyCode},
        p.${DatabaseHelper.colPlanAmountInBaseCurrency},
        p.${DatabaseHelper.colPlanExchangeRateUsed},
        p.${DatabaseHelper.colPlanStartDate}, 
        p.${DatabaseHelper.colPlanEndDate}, 
        c.${DatabaseHelper.colCategoryName} AS categoryName, 
        c.${DatabaseHelper.colCategoryType} AS categoryType 
      FROM ${DatabaseHelper.tablePlans} p
      INNER JOIN ${DatabaseHelper.tableCategories} c ON p.${DatabaseHelper.colPlanCategoryId} = c.${DatabaseHelper.colCategoryId}
      WHERE p.${DatabaseHelper.colPlanWalletId} = ?
        AND p.${DatabaseHelper.colPlanCategoryId} = ? 
        AND date(p.${DatabaseHelper.colPlanStartDate}) <= ? 
        AND date(p.${DatabaseHelper.colPlanEndDate}) >= ?
    ''';
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, [walletId, categoryId, dateOnlyString, dateOnlyString]);
    return List.generate(maps.length, (i) {
      return PlanViewData.fromMap(maps[i]);
    });
  }
}