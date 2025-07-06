import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../data/repositories/invitation_repository.dart';
import '../models/wallet.dart';
import '../data/repositories/wallet_repository.dart';
import '../data/repositories/user_repository.dart';
import '../services/auth_service.dart';
import 'app_mode_provider.dart';

class WalletProvider with ChangeNotifier {
  final WalletRepository _walletRepository;
  final UserRepository _userRepository;
  final InvitationRepository _invitationRepository;
  final AppModeProvider _appModeProvider;
  final AuthService _authService;

  List<Wallet> _wallets = [];
  Wallet? _currentWallet;
  bool _isLoading = true;

  List<Wallet> get wallets => _wallets;
  Wallet? get currentWallet => _currentWallet;
  bool get isLoading => _isLoading;

  WalletProvider(
    this._walletRepository,
    this._userRepository,
    this._invitationRepository,
    this._appModeProvider,
    this._authService,
  ) {
    _appModeProvider.addListener(loadWallets);
    loadWallets();
  }

  @override
  void dispose() {
    _appModeProvider.removeListener(loadWallets);
    super.dispose();
  }

  bool get canEditCurrentWallet {
    if (_currentWallet == null) return false;
    if (!_appModeProvider.isOnline) return true;
    final role = _currentWallet?.currentUserRole;
    return role == 'owner' || role == 'editor';
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
      await _selectInitialWallet();
    } catch (e) {
      debugPrint('Error loading wallets: $e');
      _wallets = [];
      _currentWallet = null;
    } finally {
      _isLoading = false;
      if (hasListeners) {
        notifyListeners();
      }
    }
  }
  
  Future<void> _selectInitialWallet() async {
    if (_wallets.isEmpty) {
      _currentWallet = null;
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final lastWalletId = prefs.getInt(AppConstants.prefsKeySelectedWalletId);

    Wallet? walletToSelect = _wallets.firstWhereOrNull((w) => w.id == lastWalletId);
    walletToSelect ??= _wallets.firstWhereOrNull((w) => w.isDefault) ?? _wallets.first;
    
    await switchWallet(walletToSelect.id!, shouldNotify: false);
  }

  Future<void> switchWallet(int walletId, {bool shouldNotify = true}) async {
    final walletObject = await _walletRepository.getWallet(walletId);

    if (walletObject != null) {
      final currentUserId = _authService.currentUser?.id;
      if (currentUserId != null && _appModeProvider.isOnline) {
        final myMembership = walletObject.members.firstWhereOrNull((member) => member.user.id == currentUserId);
        walletObject.currentUserRole = myMembership?.role;
      } else {
        walletObject.currentUserRole = 'owner';
      }
      _currentWallet = walletObject;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(AppConstants.prefsKeySelectedWalletId, walletId);
    }
    
    if (shouldNotify) {
      notifyListeners();
    }
  }

  Future<void> createWallet({required String name, bool isDefault = false}) async {
    final userId = _authService.currentUser?.id ?? '1';
    await _walletRepository.createWallet(name: name, ownerUserId: userId, isDefault: isDefault);
    await loadWallets();
  }

  Future<void> updateWallet(Wallet wallet) async {
    await _walletRepository.updateWallet(wallet);
    await loadWallets();
  }

  Future<void> deleteWallet(int walletId) async {
    if (_wallets.length <= 1 && !_appModeProvider.isOnline) {
       throw Exception("Неможливо видалити єдиний локальний гаманець.");
    }
    await _walletRepository.deleteWallet(walletId);
    await loadWallets();
  }

  Future<void> changeUserRole(int walletId, String userId, String newRole) async {
     if (!_appModeProvider.isOnline) return;
     await (_walletRepository as dynamic).changeUserRole(walletId, userId, newRole);
     await loadWallets();
  }

  Future<void> removeUserFromWallet(int walletId, String userId) async {
     if (!_appModeProvider.isOnline) return;
     await (_walletRepository as dynamic).removeUserFromWallet(walletId, userId);
     await loadWallets();
  }
}