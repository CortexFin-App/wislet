import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sage_wallet_reborn/core/constants/app_constants.dart';
import 'package:sage_wallet_reborn/models/user.dart' as fin_user;
import 'package:sage_wallet_reborn/services/token_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum RegistrationResult { success, needsConfirmation, failure }

class AuthService with ChangeNotifier {
  AuthService(this._localAuth, this._tokenStorage) {
    _initialize();
  }

  final SupabaseClient _supabase = Supabase.instance.client;
  final LocalAuthentication _localAuth;
  final TokenStorageService _tokenStorage;

  fin_user.User? currentUser;
  StreamSubscription<AuthState>? _authStateSubscription;

  void _initialize() {
    _authStateSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      _onAuthStateChanged(data.session);
    });
    _onAuthStateChanged(_supabase.auth.currentSession);
  }

  Future<void> _onAuthStateChanged(Session? session) async {
    if (session?.user != null) {
      final user = session!.user;

      await _supabase.rpc<void>('ensure_user_has_wallet');

      currentUser = fin_user.User(
        id: user.id,
        name: user.userMetadata?['user_name'] as String? ??
            'РљРѕСЂРёСЃС‚СѓРІР°С‡',
        email: user.email,
      );
    } else {
      currentUser = null;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<RegistrationResult> register(String email, String password) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    if (response.user != null && response.session == null) {
      return RegistrationResult.needsConfirmation;
    }
    if (response.user != null && response.session != null) {
      return RegistrationResult.success;
    }
    throw Exception('Registration failed');
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<bool> canUseBiometrics() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics || isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      if (!await canUseBiometrics()) {
        return false;
      }
      return _localAuth.authenticate(
        localizedReason:
            'РџС–РґС‚РІРµСЂРґС–С‚СЊ СЃРІРѕСЋ РѕСЃРѕР±Сѓ РґР»СЏ РІС…РѕРґСѓ РІ РґРѕРґР°С‚РѕРє',
        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> setPin(String newPin) async {
    const pinKey = 'user_pin_code_hashed';
    const pinSaltKey = 'user_pin_salt';
    final salt = _generateSalt();
    final hashedPin = _hashPin(newPin, salt);
    await _tokenStorage.write(key: pinKey, value: hashedPin);
    await _tokenStorage.write(key: pinSaltKey, value: salt);
  }

  Future<bool> verifyPin(String pin) async {
    const pinKey = 'user_pin_code_hashed';
    const pinSaltKey = 'user_pin_salt';
    final storedHash = await _tokenStorage.read(key: pinKey);
    final storedSalt = await _tokenStorage.read(key: pinSaltKey);
    if (storedHash == null || storedSalt == null) {
      return false;
    }
    final hashedPinToCheck = _hashPin(pin, storedSalt);
    return storedHash == hashedPinToCheck;
  }

  Future<bool> hasPin() async {
    const pinKey = 'user_pin_code_hashed';
    final storedPin = await _tokenStorage.read(key: pinKey);
    return storedPin != null && storedPin.isNotEmpty;
  }

  Future<void> setBiometricsEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefsKeyBiometricAuth, isEnabled);
  }

  Future<bool> isBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefsKeyBiometricAuth) ?? false;
  }
}
