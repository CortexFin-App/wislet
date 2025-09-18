import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:wislet/core/constants/app_constants.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/data/repositories/category_repository.dart';
import 'package:wislet/data/repositories/transaction_repository.dart';
import 'package:wislet/data/repositories/wallet_repository.dart';
import 'package:wislet/models/wallet.dart';
import 'package:wislet/providers/app_mode_provider.dart';
import 'package:wislet/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletProvider with ChangeNotifier {
  WalletProvider({
    required AuthService authService,
    required AppModeProvider appModeProvider,
  })  : _authService = authService,
        _appModeProvider = appModeProvider {
    _authService.addListener(loadWallets);
    loadWallets();
  }

  AuthService _authService;
  final AppModeProvider _appModeProvider;

  WalletRepository get walletRepository => getIt<WalletRepository>();
  TransactionRepository get transactionRepository =>
      getIt<TransactionRepository>();
  CategoryRepository get categoryRepository => getIt<CategoryRepository>();

  List<Wallet> _wallets = [];
  Wallet? _currentWallet;
  bool _isLoading = true;
  String? _errorMessage;

  List<Wallet> get wallets => _wallets;
  Wallet? get currentWallet => _currentWallet;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get canEditCurrentWallet {
    if (!_appModeProvider.isOnline || _currentWallet == null) {
      return true;
    }
    final currentUserId = _authService.currentUser?.id;
    if (currentUserId == null) return false;

    final myMembership = _currentWallet!.members.firstWhereOrNull(
      (member) => member.user.id == currentUserId,
    );

    if (myMembership == null) return false;
    return myMembership.role == 'owner' || myMembership.role == 'editor';
  }

  void updateAuthService(AuthService newAuthService) {
    if (_authService != newAuthService) {
      _authService.removeListener(loadWallets);
      _authService = newAuthService;
      _authService.addListener(loadWallets);
    }
  }

  @override
  void dispose() {
    _authService.removeListener(loadWallets);
    super.dispose();
  }

  Future<void> loadWallets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await walletRepository.getAllWallets();

    result.fold(
      (failure) {
        _errorMessage = failure.userMessage;
        _wallets = [];
        _currentWallet = null;
      },
      (wallets) async {
        var loadedWallets = wallets;
        if (loadedWallets.isEmpty && !_appModeProvider.isOnline) {
          final localRepo = getIt<WalletRepository>(instanceName: 'local');
          final creationResult = await localRepo.createInitialWallet();

          await creationResult.fold(
            (creationFailure) async {
              _errorMessage = creationFailure.userMessage;
            },
            (_) async {
              final reloadedResult = await localRepo.getAllWallets();
              loadedWallets = reloadedResult.getOrElse((_) => []);
            },
          );
        }
        _wallets = loadedWallets;
        await _selectInitialWallet();
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _selectInitialWallet() async {
    if (_wallets.isEmpty) {
      _currentWallet = null;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastWalletId = prefs.getInt(AppConstants.prefsKeySelectedWalletId);

    Wallet? walletToSelect;
    if (lastWalletId != null) {
      walletToSelect = _wallets.firstWhereOrNull((w) => w.id == lastWalletId);
    }

    walletToSelect ??=
        _wallets.firstWhereOrNull((w) => w.isDefault) ?? _wallets.first;

    if (walletToSelect.id != null) {
      await switchWallet(walletToSelect.id!, shouldNotify: false);
    }
  }

  Future<void> switchWallet(int walletId, {bool shouldNotify = true}) async {
    final result = await walletRepository.getWallet(walletId);
    result.fold(
      (failure) => _errorMessage = failure.userMessage,
      (walletObject) {
        if (walletObject != null) {
          _currentWallet = walletObject;
          SharedPreferences.getInstance().then(
            (prefs) =>
                prefs.setInt(AppConstants.prefsKeySelectedWalletId, walletId),
          );
        }
      },
    );
    if (shouldNotify) {
      notifyListeners();
    }
  }

  Future<void> createWallet({required String name}) async {
    final ownerId =
        _appModeProvider.isOnline ? _authService.currentUser?.id : '1';
    if (ownerId == null) {
      _errorMessage =
          'РќРµ РІРґР°Р»РѕСЃСЏ РІРёР·РЅР°С‡РёС‚Рё РІР»Р°СЃРЅРёРєР° РіР°РјР°РЅС†СЏ.';
      notifyListeners();
      return;
    }
    await walletRepository.createWallet(name: name, ownerUserId: ownerId);
    await loadWallets();
  }

  Future<void> updateWallet(Wallet wallet) async {
    await walletRepository.updateWallet(wallet);
    await loadWallets();
  }

  Future<void> deleteWallet(int walletId) async {
    await walletRepository.deleteWallet(walletId);
    if (_currentWallet?.id == walletId) {
      _currentWallet = null;
    }
    await loadWallets();
  }

  Future<void> changeUserRole(
    int walletId,
    String userId,
    String newRole,
  ) async {
    await walletRepository.changeUserRole(walletId, userId, newRole);
    await loadWallets();
  }

  Future<void> removeUserFromWallet(int walletId, String userId) async {
    await walletRepository.removeUserFromWallet(walletId, userId);
    await loadWallets();
  }
}
