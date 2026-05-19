import 'dart:convert';
import 'dart:io';

import '../../../core/config/app_config.dart';

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
  final Map<String, dynamic> user;

  factory AuthLoginResponse.fromJson(Map<String, dynamic> json) {
    return AuthLoginResponse(
      success: json['success'] == true,
      token: (json['token'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      user: Map<String, dynamic>.from((json['user'] ?? {}) as Map),
    );
  }
}

class AuthApi {
  const AuthApi._();

  static Future<AuthLoginResponse> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/auth/login');

    final response = await _postJson(uri, {
      'email': email,
      'password': password,
      'device_name': 'flutter-tourhub',
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _extractErrorMessage(response.body);
      throw Exception(message);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format response login tidak valid.');
    }

    final result = AuthLoginResponse.fromJson(decoded);
    if (!result.success || result.token.isEmpty) {
      throw Exception(result.message.isNotEmpty ? result.message : 'Login gagal. Token tidak ditemukan.');
    }

    return result;
  }

  static Future<_SimpleResponse> _postJson(Uri uri, Map<String, dynamic> body) async {
    final client = HttpClient();

    try {
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
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

  static String _extractErrorMessage(String body) {
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
          if (first is List && first.isNotEmpty) {
            return first.first.toString();
          }
          return first.toString();
        }
      }
    } catch (_) {
      // Abaikan parsing error dan pakai fallback di bawah.
    }

    return 'Login gagal. Periksa email dan password.';
  }
}

class _SimpleResponse {
  const _SimpleResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;
}
