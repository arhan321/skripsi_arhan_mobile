import 'dart:convert';
import 'dart:io';

import '../../../core/config/app_config.dart';
import '../../../core/storage/token_storage.dart';

class AuthUser {
  const AuthUser({required this.id, required this.name, required this.email});

  final int id;
  final String name;
  final String email;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: int.tryParse((json['id'] ?? '0').toString()) ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
    );
  }
}

class AuthLoginResponse {
  const AuthLoginResponse({
    required this.success,
    required this.token,
    required this.message,
    required this.user,
  });

  final bool success;
  final String token;
  final String message;
  final AuthUser? user;

  factory AuthLoginResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];

    return AuthLoginResponse(
      success: json['success'] == true,
      token: (json['token'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      user: userJson is Map<String, dynamic>
          ? AuthUser.fromJson(userJson)
          : null,
    );
  }
}

class AuthApi {
  const AuthApi._();

  static Future<AuthLoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _postJson(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
      {'email': email, 'password': password, 'device_name': 'flutter-tourhub'},
    );

    return _parseAuthResponse(
      response,
      fallbackMessage: 'Login gagal. Periksa email dan password.',
    );
  }

  static Future<AuthLoginResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response =
        await _postJson(Uri.parse('${AppConfig.apiBaseUrl}/auth/register'), {
          'name': name,
          'email': email,
          'password': password,
          'device_name': 'flutter-tourhub',
        });

    return _parseAuthResponse(
      response,
      fallbackMessage: 'Registrasi gagal. Periksa data yang kamu isi.',
    );
  }

  static Future<void> logout() async {
    final token = await TokenStorage.readToken();

    if (token == null || token.trim().isEmpty) {
      await TokenStorage.clearToken();
      return;
    }

    try {
      await _postJson(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/logout'),
        const {},
        token: token,
      );
    } finally {
      await TokenStorage.clearToken();
    }
  }

  static Future<AuthUser?> me() async {
    final token = await TokenStorage.readToken();
    if (token == null || token.trim().isEmpty) return null;

    final response = await _getJson(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/me'),
      token: token,
    );

    if (response.statusCode == 401) {
      await TokenStorage.clearToken();
      return null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractErrorMessage(response.body, 'Gagal membaca data user.'),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;

    final userJson = decoded['user'];
    return userJson is Map<String, dynamic>
        ? AuthUser.fromJson(userJson)
        : null;
  }

  static AuthLoginResponse _parseAuthResponse(
    _SimpleResponse response, {
    required String fallbackMessage,
  }) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response.body, fallbackMessage));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format response auth tidak valid.');
    }

    final result = AuthLoginResponse.fromJson(decoded);
    if (!result.success || result.token.trim().isEmpty) {
      throw Exception(
        result.message.isNotEmpty ? result.message : fallbackMessage,
      );
    }

    return result;
  }

  static Future<_SimpleResponse> _postJson(
    Uri uri,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final client = HttpClient();

    try {
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');

      if (token != null && token.trim().isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }

      request.add(utf8.encode(jsonEncode(body)));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      return _SimpleResponse(
        statusCode: response.statusCode,
        body: responseBody,
      );
    } finally {
      client.close(force: true);
    }
  }

  static Future<_SimpleResponse> _getJson(
    Uri uri, {
    required String token,
  }) async {
    final client = HttpClient();

    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      return _SimpleResponse(
        statusCode: response.statusCode,
        body: responseBody,
      );
    } finally {
      client.close(force: true);
    }
  }

  static String _extractErrorMessage(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }

        final errors = decoded['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
          return first.toString();
        }
      }
    } catch (_) {
      // Pakai fallback.
    }

    return fallback;
  }
}

class _SimpleResponse {
  const _SimpleResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}
