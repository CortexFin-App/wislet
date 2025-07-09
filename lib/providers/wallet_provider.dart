import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/di/injector.dart';
import '../core/error/failures.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/goal_repository.dart';
import '../data/repositories/invitation_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../models/wallet.dart';
import '../data/repositories/wallet_repository.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import 'app_mode_provider.dart';

class WalletProvider with ChangeNotifier {
  final AppModeProvider _appModeProvider;
  final AuthService _authService;

  final WalletRepository _localWalletRepo;
  final WalletRepository _supabaseWalletRepo;

  List<Wallet> _wallets = [];
  Wallet? _currentWallet;
  bool _isLoading = true;
  String? _errorMessage;

  List<Wallet> get wallets => _wallets;
  Wallet? get currentWallet => _currentWallet;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  WalletRepository get _activeWalletRepo => _appModeProvider.isOnline ? _supabaseWalletRepo : _localWalletRepo;

  WalletProvider({
    required AppModeProvider appModeProvider,
    required AuthService authService,
    required WalletRepository localWalletRepo,
    required TransactionRepository localTransactionRepo,
    required BudgetRepository localBudgetRepo,
    required GoalRepository localGoalRepo,
    required WalletRepository supabaseWalletRepo,
    required TransactionRepository supabaseTransactionRepo,
    required BudgetRepository supabaseBudgetRepo,
    required GoalRepository supabaseGoalRepo,
    required InvitationRepository supabaseInvitationRepo,
  })  : _appModeProvider = appModeProvider,
        _authService = authService,
        _localWalletRepo = localWalletRepo,
        _supabaseWalletRepo = supabaseWalletRepo {
    _appModeProvider.addListener(onAppModeChanged);
    loadWallets();
  }

  @override
  void dispose() {
    _appModeProvider.removeListener(onAppModeChanged);
    super.dispose();
  }

  void onAppModeChanged() {
    loadWallets();
    if (_appModeProvider.isOnline) {
      getIt<SyncService>().synchronize();
    }
  }

  bool get canEditCurrentWallet {
    if (_currentWallet == null) return false;
    if (!_appModeProvider.isOnline) return true;
    final role = _currentWallet?.currentUserRole;
    return role == 'owner' || role == 'editor';
  }

  Future<void> loadWallets() async {
    if (!_isLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    final result = await _activeWalletRepo.getAllWallets();

    result.fold(
      (failure) {
        _errorMessage = failure.userMessage;
        _wallets = [];
        _currentWallet = null;
      },
      (wallets) async {
        _wallets = wallets;
        if (_wallets.isEmpty && !_appModeProvider.isOnline) {
          final initialResult = await _localWalletRepo.createInitialWallet();
          initialResult.fold(
            (fail) => _errorMessage = fail.userMessage,
            (_) async {
              final reloadedResult = await _localWalletRepo.getAllWallets();
              reloadedResult.fold(
                (f) => _errorMessage = f.userMessage,
                (reloadedWallets) {
                  _wallets = reloadedWallets;
                }
              );
            }
          );
        }
        await _selectInitialWallet();
        _errorMessage = null;
      },
    );

    _isLoading = false;
    if (hasListeners) {
      notifyListeners();
    }
  }

  Future<void> _selectInitialWallet() async {
    if (_wallets.isEmpty) {
      _currentWallet = null;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final lastWalletId = prefs.getInt(AppConstants.prefsKeySelectedWalletId);
    Wallet? walletToSelect =
        _wallets.firstWhereOrNull((w) => w.id == lastWalletId);
    walletToSelect ??=
        _wallets.firstWhereOrNull((w) => w.isDefault) ?? _wallets.first;
    await switchWallet(walletToSelect.id!, shouldNotify: false);
  }

  Future<void> switchWallet(int walletId, {bool shouldNotify = true}) async {
    final result = await _activeWalletRepo.getWallet(walletId);
    result.fold(
      (failure) {
        _errorMessage = failure.userMessage;
      },
      (walletObject) {
        if (walletObject != null) {
          final currentUserId = _authService.currentUser?.id;
          if (currentUserId != null && _appModeProvider.isOnline) {
            final myMembership = walletObject.members
                .firstWhereOrNull((member) => member.user.id == currentUserId);
            walletObject.currentUserRole = myMembership?.role;
          } else {
            walletObject.currentUserRole = 'owner';
          }
          _currentWallet = walletObject;
          SharedPreferences.getInstance().then((prefs) => prefs.setInt(AppConstants.prefsKeySelectedWalletId, walletId));
        }
      }
    );
    if (shouldNotify) {
      notifyListeners();
    }
  }

  Future<Either<AppFailure, int>> createWallet({required String name, bool isDefault = false}) async {
    final userId = _authService.currentUser?.id ?? '1';
    final result = await _activeWalletRepo.createWallet(name: name, ownerUserId: userId, isDefault: isDefault);
    await loadWallets();
    return result;
  }

  Future<Either<AppFailure, int>> updateWallet(Wallet wallet) async {
    final result = await _activeWalletRepo.updateWallet(wallet);
    await loadWallets();
    return result;
  }

  Future<Either<AppFailure, int>> deleteWallet(int walletId) async {
    if (_wallets.length <= 1 && !_appModeProvider.isOnline) {
      return Left(UnexpectedFailure(message: "Неможливо видалити єдиний локальний гаманець."));
    }
    final result = await _activeWalletRepo.deleteWallet(walletId);
    await loadWallets();
    return result;
  }

  Future<Either<AppFailure, void>> changeUserRole(int walletId, String userId, String newRole) async {
    if (!_appModeProvider.isOnline) return Left(UnexpectedFailure(message: "Ця дія доступна лише в онлайн-режимі."));
    final result = await _activeWalletRepo.changeUserRole(walletId, userId, newRole);
    await loadWallets();
    return result;
  }

  Future<Either<AppFailure, void>> removeUserFromWallet(int walletId, String userId) async {
    if (!_appModeProvider.isOnline) return Left(UnexpectedFailure(message: "Ця дія доступна лише в онлайн-режимі."));
    final result = await _activeWalletRepo.removeUserFromWallet(walletId, userId);
    await loadWallets();
    return result;
  }
}