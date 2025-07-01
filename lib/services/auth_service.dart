import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sage_wallet_reborn/models/user.dart' as fin_user;
import '../core/constants/app_constants.dart';
import 'api_client.dart';
import 'token_storage_service.dart';

class AuthService {
  final LocalAuthentication _localAuth;
  final ApiClient _apiClient;
  final TokenStorageService _tokenStorage;
  static const _pinKey = 'user_pin_code_hashed';
  static const _pinSaltKey = 'user_pin_salt';

  fin_user.User? currentUser;

  AuthService(this._apiClient, this._tokenStorage, this._localAuth);

  Future<bool> tryToRestoreSession() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    _apiClient.setAuthToken(token);
    try {
      final userData = await _apiClient.get('/auth/me');
      if (userData != null) {
        currentUser = fin_user.User.fromMap(userData);
        return true;
      }
      return false;
    } catch (e) {
      await logout();
      return false;
    }
  }

  Future<void> login(String email, String password) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    final accessToken = response['access_token'] as String;
    final refreshToken = response['refresh_token'] as String;
    final userId = response['user_id'] as String;
    final userName = response['user_name'] as String? ?? 'User';

    await _tokenStorage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    _apiClient.setAuthToken(accessToken);
    currentUser = fin_user.User(id: userId, name: userName);
  }

  Future<void> register(String email, String password) async {
    final response = await _apiClient.post(
      '/auth/register',
      body: {'email': email, 'password': password},
    );
    final accessToken = response['access_token'] as String;
    final refreshToken = response['refresh_token'] as String;
    final userId = response['user_id'] as String;
    final userName = response['user_name'] as String? ?? 'User';

    await _tokenStorage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    _apiClient.setAuthToken(accessToken);
    currentUser = fin_user.User(id: userId, name: userName);
  }

  Future<void> logout() async {
    await _tokenStorage.deleteTokens();
    _apiClient.setAuthToken(null);
    currentUser = null;
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
    final salt = _generateSalt();
    final hashedPin = _hashPin(newPin, salt);
    await _tokenStorage.write(key: _pinKey, value: hashedPin);
    await _tokenStorage.write(key: _pinSaltKey, value: salt);
  }

  Future<bool> verifyPin(String pin) async {
    final storedHash = await _tokenStorage.read(key: _pinKey);
    final storedSalt = await _tokenStorage.read(key: _pinSaltKey);
    if (storedHash == null || storedSalt == null) {
      return false;
    }
    final hashedPinToCheck = _hashPin(pin, storedSalt);
    return storedHash == hashedPinToCheck;
  }

  Future<bool> hasPin() async {
    final storedPin = await _tokenStorage.read(key: _pinKey);
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