import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:http/http.dart' as http;
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/services/token_storage_service.dart';
import 'package:sage_wallet_reborn/services/auth_service.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status Code: $statusCode)';
}

class ApiClient {
  final String _baseUrl;
  String? _token;
  bool _isRefreshing = false;

  ApiClient() : _baseUrl = _getBaseUrl();

  static String _getBaseUrl() {
    const bool isDebugMode = !kReleaseMode;
    if (isDebugMode) {
      if (kIsWeb) {
        return 'http://localhost:8080';
      }
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8080';
      }
      return 'http://localhost:8080';
    } else {
      return 'https://api.cortexfinapp.com';
    }
  }

  void setAuthToken(String? token) {
    _token = token;
  }

  Future<dynamic> _refreshToken() async {
    final tokenStorage = getIt<TokenStorageService>();
    final refreshToken = await tokenStorage.readRefreshToken();

    if (refreshToken == null) {
      await getIt<AuthService>().logout();
      throw ApiException(message: 'Session expired. Please log in again.', statusCode: 401);
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final newTokens = jsonDecode(response.body);
        final newAccessToken = newTokens['access_token'] as String;
        final newRefreshToken = newTokens['refresh_token'] as String;

        await tokenStorage.saveTokens(accessToken: newAccessToken, refreshToken: newRefreshToken);
        setAuthToken(newAccessToken);
        return newAccessToken;
      } else {
        await getIt<AuthService>().logout();
        throw ApiException(message: 'Failed to refresh session. Please log in again.', statusCode: response.statusCode);
      }
    } catch (e) {
      await getIt<AuthService>().logout();
      throw ApiException(message: 'Network error during token refresh.', statusCode: 500);
    }
  }

  Map<String, String> _getHeaders(String path) {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (_token != null) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $_token';
    }
    return headers;
  }
  
  Future<dynamic> _request(String path, Future<http.Response> Function(Map<String, String> headers) requestFunc) async {
    final isPublicRoute = path.startsWith('/auth/');
    
    final headers = isPublicRoute ? {'Content-Type': 'application/json; charset=UTF-8'} : _getHeaders(path);

    var response = await requestFunc(headers);

    if (response.statusCode == 401 && !isPublicRoute) {
      if (!_isRefreshing) {
        _isRefreshing = true;
        try {
          await _refreshToken();
          final newHeaders = _getHeaders(path);
          response = await requestFunc(newHeaders);
        } finally {
          _isRefreshing = false;
        }
      }
    }

    return _processResponse(response);
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    return _request(path, (headers) {
      final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: queryParams);
      return http.get(uri, headers: headers);
    });
  }

  Future<dynamic> post(String path, {required Map<String, dynamic> body, Map<String, String>? queryParams}) async {
    return _request(path, (headers) {
      final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: queryParams);
      return http.post(uri, headers: headers, body: jsonEncode(body));
    });
  }

  Future<dynamic> put(String path, {required Map<String, dynamic> body}) async {
    return _request(path, (headers) {
      final uri = Uri.parse('$_baseUrl$path');
      return http.put(uri, headers: headers, body: jsonEncode(body));
    });
  }

  Future<void> delete(String path, {Map<String, dynamic>? body}) async {
    await _request(path, (headers) {
      final uri = Uri.parse('$_baseUrl$path');
      return http.delete(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
    });
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      dynamic errorBody;
      try {
        errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (e) {
        errorBody = {'message': response.body};
      }
      throw ApiException(
        message: errorBody is Map
            ? errorBody['message'] ?? 'An unknown error occurred'
            : errorBody.toString(),
        statusCode: response.statusCode,
      );
    }
  }
}