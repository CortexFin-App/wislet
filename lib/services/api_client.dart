import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

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

  ApiClient() : _baseUrl = _getBaseUrl();

  static String _getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  void setAuthToken(String? token) {
    _token = token;
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders());
    return _processResponse(response);
  }

  Future<dynamic> post(String path,
      {required Map<String, dynamic> body,
      Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: queryParams);
    final response = await http.post(
      uri,
      headers: _getHeaders(),
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  Future<dynamic> put(String path, {required Map<String, dynamic> body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.put(
      uri,
      headers: _getHeaders(),
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  Future<void> delete(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.delete(
      uri,
      headers: _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    _processResponse(response);
  }

  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (_token != null) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $_token';
    }
    return headers;
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