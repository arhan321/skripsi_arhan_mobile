import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class TokenStorage {
  TokenStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'tourhub_auth_token';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> readToken() async {
    return _storage.read(key: _tokenKey);
  }

  static Future<bool> hasToken() async {
    final token = await readToken();
    return token != null && token.trim().isNotEmpty;
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
