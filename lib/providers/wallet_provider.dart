import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../data/repositories/invitation_repository.dart';
import '../models/wallet.dart';
import '../data/repositories/wallet_repository.dart';
import '../services/auth_service.dart';
import 'app_mode_provider.dart';

class WalletProvider with ChangeNotifier {
  final WalletRepository _localWalletRepo;
  final WalletRepository _supabaseWalletRepo;
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
    this._localWalletRepo,
    this._supabaseWalletRepo,
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
    print("[PROVIDER_DEBUG] loadWallets START. _isLoading=true");
    _isLoading = true;
    notifyListeners();

    try {
      final repo = _appModeProvider.isOnline ? _supabaseWalletRepo : _localWalletRepo;
      print("[PROVIDER_DEBUG] Mode: ${_appModeProvider.isOnline ? 'ONLINE' : 'OFFLINE'}. Using ${repo.runtimeType}");
      
      print("[PROVIDER_DEBUG] Getting wallets from repo...");
      _wallets = await repo.getAllWallets();
      print("[PROVIDER_DEBUG] Got ${_wallets.length} wallets.");

      if (_wallets.isEmpty && !_appModeProvider.isOnline) {
        print("[PROVIDER_DEBUG] No local wallets found, creating initial one...");
        await _localWalletRepo.createInitialWallet();
        _wallets = await _localWalletRepo.getAllWallets();
        print("[PROVIDER_DEBUG] Initial wallet created, got ${_wallets.length} wallet(s).");
      }
      
      print("[PROVIDER_DEBUG] Selecting initial wallet...");
      await _selectInitialWallet();
      print("[PROVIDER_DEBUG] Initial wallet selected.");

    } catch (e, stackTrace) {
      print("[PROVIDER_DEBUG] CATCH_ERROR in loadWallets: $e");
      print("[PROVIDER_DEBUG] StackTrace: $stackTrace");
      _wallets = [];
      _currentWallet = null;
    } finally {
      _isLoading = false;
      print("[PROVIDER_DEBUG] FINALLY block. _isLoading set to false. Notifying listeners.");
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
    final repo = _appModeProvider.isOnline ? _supabaseWalletRepo : _localWalletRepo;
    final walletObject = await repo.getWallet(walletId);

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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(AppConstants.prefsKeySelectedWalletId, walletId);
    }
    
    if (shouldNotify) {
      notifyListeners();
    }
  }

  Future<void> createWallet({required String name, bool isDefault = false}) async {
    final repo = _appModeProvider.isOnline ? _supabaseWalletRepo : _localWalletRepo;
    final userId = _authService.currentUser?.id ?? '1';
    await repo.createWallet(name: name, ownerUserId: userId, isDefault: isDefault);
    await loadWallets();
  }

  Future<void> updateWallet(Wallet wallet) async {
    final repo = _appModeProvider.isOnline ? _supabaseWalletRepo : _localWalletRepo;
    await repo.updateWallet(wallet);
    await loadWallets();
  }

  Future<void> deleteWallet(int walletId) async {
    final repo = _appModeProvider.isOnline ? _supabaseWalletRepo : _localWalletRepo;
    if (_wallets.length <= 1 && !_appModeProvider.isOnline) {
       throw Exception("Неможливо видалити єдиний локальний гаманець.");
    }
    await repo.deleteWallet(walletId);
    await loadWallets();
  }

  Future<void> changeUserRole(int walletId, String userId, String newRole) async {
     if (!_appModeProvider.isOnline) return;
     await _supabaseWalletRepo.changeUserRole(walletId, userId, newRole);
     await loadWallets();
  }

  Future<void> removeUserFromWallet(int walletId, String userId) async {
     if (!_appModeProvider.isOnline) return;
     await _supabaseWalletRepo.removeUserFromWallet(walletId, userId);
     await loadWallets();
  }
}