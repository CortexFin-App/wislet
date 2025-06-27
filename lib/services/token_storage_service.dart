import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _authTokenKey = 'auth_token';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _authTokenKey, value: token);
  }

  Future<String?> readToken() async {
    return await _storage.read(key: _authTokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _authTokenKey);
  }

  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }
}