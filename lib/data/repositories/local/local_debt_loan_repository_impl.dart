import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import '../../../core/error/failures.dart';
import '../../../models/debt_loan_model.dart';
import '../../../services/error_monitoring_service.dart';
import '../../../utils/database_helper.dart';
import '../debt_loan_repository.dart';

class LocalDebtLoanRepositoryImpl implements DebtLoanRepository {
  final DatabaseHelper _dbHelper;

  LocalDebtLoanRepositoryImpl(this._dbHelper);

  @override
  Stream<List<DebtLoan>> watchAllDebtLoans(int walletId) {
    return Stream.fromFuture(getAllDebtLoans(walletId))
        .map((either) => either.getOrElse((_) => []));
  }

  @override
  Future<Either<AppFailure, int>> createDebtLoan(DebtLoan debtLoan, int walletId) async {
    try {
      final db = await _dbHelper.database;
      int newId = -1;
      await db.transaction((txn) async {
        final map = debtLoan.toMap();
        map[DatabaseHelper.colDebtLoanWalletId] = walletId;
        newId = await txn.insert(DatabaseHelper.tableDebtsLoans, map);

        await txn.insert(DatabaseHelper.tableSyncQueue, {
          DatabaseHelper.colSyncEntityType: 'debt_loan',
          DatabaseHelper.colSyncEntityId: newId.toString(),
          DatabaseHelper.colSyncActionType: 'create',
          DatabaseHelper.colSyncPayload: jsonEncode(map..['id'] = newId),
          DatabaseHelper.colSyncTimestamp: DateTime.now().toIso8601String(),
          DatabaseHelper.colSyncStatus: 'pending'
        });
      });
      return Right(newId);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, DebtLoan?>> getDebtLoan(int id) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableDebtsLoans,
        where: '${DatabaseHelper.colDebtLoanId} = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return Right(DebtLoan.fromMap(maps.first));
      }
      return const Right(null);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<DebtLoan>>> getAllDebtLoans(int walletId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableDebtsLoans,
        where: '${DatabaseHelper.colDebtLoanWalletId} = ? AND ${DatabaseHelper.colDebtLoanIsDeleted} = 0',
        whereArgs: [walletId],
        orderBy: '${DatabaseHelper.colDebtLoanCreationDate} DESC',
      );
      return Right(maps.map((map) => DebtLoan.fromMap(map)).toList());
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateDebtLoan(DebtLoan debtLoan) async {
    try {
      final db = await _dbHelper.database;
      int updatedRows = 0;
      await db.transaction((txn) async {
        final map = debtLoan.toMap();
        updatedRows = await txn.update(
          DatabaseHelper.tableDebtsLoans,
          map,
          where: '${DatabaseHelper.colDebtLoanId} = ?',
          whereArgs: [debtLoan.id],
        );

        await txn.insert(DatabaseHelper.tableSyncQueue, {
          DatabaseHelper.colSyncEntityType: 'debt_loan',
          DatabaseHelper.colSyncEntityId: debtLoan.id.toString(),
          DatabaseHelper.colSyncActionType: 'update',
          DatabaseHelper.colSyncPayload: jsonEncode(map),
          DatabaseHelper.colSyncTimestamp: DateTime.now().toIso8601String(),
          DatabaseHelper.colSyncStatus: 'pending'
        });
      });
      return Right(updatedRows);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteDebtLoan(int id) async {
    try {
      final db = await _dbHelper.database;
      int deletedRows = 0;
       await db.transaction((txn) async {
          final now = DateTime.now().toIso8601String();
          deletedRows = await txn.update(
            DatabaseHelper.tableDebtsLoans,
            { 'is_deleted': 1, 'updated_at': now },
            where: '${DatabaseHelper.colDebtLoanId} = ?',
            whereArgs: [id],
          );

          await txn.insert(DatabaseHelper.tableSyncQueue, {
            DatabaseHelper.colSyncEntityType: 'debt_loan',
            DatabaseHelper.colSyncEntityId: id.toString(),
            DatabaseHelper.colSyncActionType: 'delete',
            DatabaseHelper.colSyncPayload: jsonEncode({'id': id}),
            DatabaseHelper.colSyncTimestamp: now,
            DatabaseHelper.colSyncStatus: 'pending'
          });
       });
      return Right(deletedRows);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> markAsSettled(int id, bool isSettled) async {
     try {
      final db = await _dbHelper.database;
      final result = await db.update(
        DatabaseHelper.tableDebtsLoans,
        {DatabaseHelper.colDebtLoanIsSettled: isSettled ? 1 : 0},
        where: '${DatabaseHelper.colDebtLoanId} = ?',
        whereArgs: [id],
      );
      return Right(result);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }
}