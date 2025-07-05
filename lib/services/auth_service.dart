import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sage_wallet_reborn/models/user.dart' as fin_user;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import 'token_storage_service.dart';

enum RegistrationResult { success, needsConfirmation, failure }

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final LocalAuthentication _localAuth;
  final TokenStorageService _tokenStorage;

  fin_user.User? currentUser;
  StreamSubscription<AuthState>? _authStateSubscription;

  AuthService(this._localAuth, this._tokenStorage);

  void listenToAuthChanges() {
    _authStateSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      if (session != null && session.user != null) {
        currentUser = fin_user.User(
          id: session.user.id,
          name: session.user.userMetadata?['user_name'] ?? 'User',
        );
      } else {
        currentUser = null;
      }
    });

    final initialSession = _supabase.auth.currentSession;
    if (initialSession != null) {
      currentUser = fin_user.User(
          id: initialSession.user.id,
          name: initialSession.user.userMetadata?['user_name'] ?? 'User');
    }
  }

  Future<void> login(String email, String password) async {
    final response = await _supabase.functions.invoke(
      'login',
      body: {'email': email, 'password': password},
    );

    if (response.status != 200) {
      throw Exception(response.data?['error'] ?? 'Login failed');
    }
  }

  Future<RegistrationResult> register(String email, String password) async {
    final response = await _supabase.functions.invoke(
      'register',
      body: {'email': email, 'password': password},
    );

    if (response.status != 200) {
      throw Exception(response.data?['error'] ?? 'Registration failed');
    }

    return RegistrationResult.needsConfirmation;
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    currentUser = null;
  }

  void dispose() {
    _authStateSubscription?.cancel();
  }

  Future<bool> canUseBiometrics() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics || isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      if (!await canUseBiometrics()) {
        debugPrint('Biometrics are not supported or not enabled.');
        return false;
      }
      return await _localAuth.authenticate(
        localizedReason: 'Підтвердіть свою особу для входу в додаток',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: ${e.code} - ${e.message}');
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