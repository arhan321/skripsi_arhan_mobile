import 'dart:convert';
import 'dart:io';

import '../../../core/config/app_config.dart';
import '../../../core/storage/token_storage.dart';
import 'recommendation_history_model.dart';

class RecommendationHistoryApi {
  const RecommendationHistoryApi._();

  static Future<List<RecommendationHistoryItem>> fetchHistories() async {
    final token = await _requiredToken();
    final response = await _getJson(
      Uri.parse('${AppConfig.apiBaseUrl}/tourhub/history'),
      token: token,
    );

    if (response.statusCode == 401) {
      await TokenStorage.clearToken();
      throw Exception('Sesi login habis. Silakan login ulang.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response.body));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format response riwayat tidak valid.');
    }

    final data = decoded['data'];
    final rows = data is Map<String, dynamic> ? data['data'] : data;

    if (rows is! List) return const [];

    return rows
        .whereType<Map>()
        .map(
          (item) => RecommendationHistoryItem.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  static Future<RecommendationHistoryItem> fetchDetail(int id) async {
    final token = await _requiredToken();
    final response = await _getJson(
      Uri.parse('${AppConfig.apiBaseUrl}/tourhub/history/$id'),
      token: token,
    );

    if (response.statusCode == 401) {
      await TokenStorage.clearToken();
      throw Exception('Sesi login habis. Silakan login ulang.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response.body));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format response detail riwayat tidak valid.');
    }

    final data = decoded['data'];
    if (data is! Map) {
      throw Exception('Data detail riwayat tidak ditemukan.');
    }

    return RecommendationHistoryItem.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<String> _requiredToken() async {
    final token = await TokenStorage.readToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }
    return token;
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

  static String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message != null && message.toString().trim().isNotEmpty)
          return message.toString();

        final errors = decoded['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
          return first.toString();
        }
      }
    } catch (_) {
      // Abaikan.
    }

    return 'Gagal mengambil data riwayat rekomendasi.';
  }
}

class _SimpleResponse {
  const _SimpleResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}
