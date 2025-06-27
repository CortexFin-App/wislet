import 'package:sage_wallet_reborn/models/debt_loan_model.dart';
import 'package:sage_wallet_reborn/utils/database_helper.dart';
import 'package:sage_wallet_reborn/data/repositories/debt_loan_repository.dart';

class LocalDebtLoanRepositoryImpl implements DebtLoanRepository {
  final DatabaseHelper _dbHelper;

  LocalDebtLoanRepositoryImpl(this._dbHelper);

  @override
  Future<int> createDebtLoan(DebtLoan debtLoan, int walletId) async {
    final db = await _dbHelper.database;
    final map = debtLoan.toMap();
    map[DatabaseHelper.colDebtLoanWalletId] = walletId;
    return await db.insert(DatabaseHelper.tableDebtsLoans, map);
  }

  @override
  Future<DebtLoan?> getDebtLoan(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableDebtsLoans,
      where: '${DatabaseHelper.colDebtLoanId} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return DebtLoan.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<DebtLoan>> getAllDebtLoans(int walletId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableDebtsLoans,
      where: '${DatabaseHelper.colDebtLoanWalletId} = ?',
      whereArgs: [walletId],
      orderBy: '${DatabaseHelper.colDebtLoanCreationDate} DESC',
    );
    return maps.map((map) => DebtLoan.fromMap(map)).toList();
  }

  @override
  Future<int> updateDebtLoan(DebtLoan debtLoan) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableDebtsLoans,
      debtLoan.toMap(),
      where: '${DatabaseHelper.colDebtLoanId} = ?',
      whereArgs: [debtLoan.id],
    );
  }

  @override
  Future<int> deleteDebtLoan(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableDebtsLoans,
      where: '${DatabaseHelper.colDebtLoanId} = ?',
      whereArgs: [id],
    );
  }
  
  @override
  Future<int> markAsSettled(int id, bool isSettled) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableDebtsLoans,
      {DatabaseHelper.colDebtLoanIsSettled: isSettled ? 1 : 0},
      where: '${DatabaseHelper.colDebtLoanId} = ?',
      whereArgs: [id],
    );
  }
}