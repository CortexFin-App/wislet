import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/wallet.dart';
import '../data/repositories/wallet_repository.dart';
import '../data/repositories/user_repository.dart';
import '../services/auth_service.dart';
import 'app_mode_provider.dart';

class WalletProvider with ChangeNotifier {
  final WalletRepository _walletRepository;
  final UserRepository _userRepository;
  final AppModeProvider _appModeProvider;
  final AuthService _authService;

  List<Wallet> _wallets = [];
  Wallet? _currentWallet;
  bool _isLoading = true;

  List<Wallet> get wallets => _wallets;
  Wallet? get currentWallet => _currentWallet;
  bool get isLoading => _isLoading;

  bool get canEditCurrentWallet {
    if (_currentWallet == null || !_appModeProvider.isOnline) {
      return true;
    }
    final role = _currentWallet?.currentUserRole;
    return role == 'owner' || role == 'editor';
  }

  WalletProvider(this._walletRepository, this._userRepository,
      this._appModeProvider, this._authService) {
    _appModeProvider.addListener(onAppModeChanged);
  }

  @override
  void dispose() {
    _appModeProvider.removeListener(onAppModeChanged);
    super.dispose();
  }

  void onAppModeChanged() {
    loadWallets();
  }

  Future<void> initialLoad() async {
    await loadWallets();
  }

  Future<void> loadWallets() async {
    _isLoading = true;
    notifyListeners();
    try {
      _wallets = await _walletRepository.getAllWallets();
      if (_wallets.isEmpty && !_appModeProvider.isOnline) {
        await _walletRepository.createInitialWallet();
        _wallets = await _walletRepository.getAllWallets();
      }
      final prefs = await SharedPreferences.getInstance();
      final lastWalletId = prefs.getInt(AppConstants.prefsKeySelectedWalletId);

      if (_wallets.isNotEmpty) {
        int walletToLoadId;
        if (lastWalletId != null && _wallets.any((w) => w.id == lastWalletId)) {
          walletToLoadId = lastWalletId;
        } else {
          final defaultWallet =
              _wallets.firstWhere((w) => w.isDefault, orElse: () => _wallets.first);
          walletToLoadId = defaultWallet.id!;
        }
        await switchWallet(walletToLoadId, shouldNotify: false);
      } else {
        _currentWallet = null;
      }
    } catch (e) {
      debugPrint('Error loading wallets: $e');
      _wallets = [];
      _currentWallet = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> switchWallet(int walletId, {bool shouldNotify = true}) async {
    final walletObject = await _walletRepository.getWallet(walletId);
    if (walletObject == null) return;

    final currentUserId = _authService.currentUser?.id;
    if (currentUserId != null) {
      final myMembership = walletObject.members.firstWhereOrNull(
        (member) => member.user.id == currentUserId,
      );
      walletObject.currentUserRole = myMembership?.role;
    } else {
      walletObject.currentUserRole = 'owner';
    }

    _currentWallet = walletObject;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefsKeySelectedWalletId, walletId);

    if (shouldNotify) {
      notifyListeners();
    }
  }

  Future<void> createWallet(String name) async {
    try {
      final userId = _authService.currentUser?.id ?? '1';
      await _walletRepository.createWallet(
          name: name, ownerUserId: userId, isDefault: _wallets.isEmpty);
      await loadWallets();
    } catch (e) {
      throw Exception('Не вдалося створити гаманець: $e');
    }
  }

  Future<void> updateWallet(Wallet wallet) async {
    try {
      await _walletRepository.updateWallet(wallet);
      await loadWallets();
    } catch (e) {
      throw Exception('Не вдалося оновити гаманець: $e');
    }
  }

  Future<void> deleteWallet(int walletId) async {
    if (_wallets.length <= 1) {
      throw Exception("Неможливо видалити єдиний гаманець.");
    }
    try {
      await _walletRepository.deleteWallet(walletId);
      await loadWallets();
    } catch (e) {
      throw Exception('Не вдалося видалити гаманець: $e');
    }
  }

  Future<void> addUserToWallet(int walletId, String userId, String role) async {
    try {
      await _userRepository.addUserToWallet(walletId, userId, role);
      notifyListeners();
    } catch (e) {
      throw Exception('Не вдалося додати користувача: $e');
    }
  }
}