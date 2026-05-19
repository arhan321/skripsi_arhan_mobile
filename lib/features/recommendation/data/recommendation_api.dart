import 'dart:convert';
import 'dart:io';

import '../../../core/config/app_config.dart';
import '../../../core/storage/token_storage.dart';
import 'tourhub_location.dart';

class RecommendationApi {
  const RecommendationApi._();

  static Future<Map<String, dynamic>> recommend({
    required List<String> categories,
    required TourHubLocation location,
    required String keywords,
    required double minRating,
    required int topN,
    required String weather,
    required String visitDay,
    required bool isHighSeason,
    required bool useBmkg,
  }) async {
    final token = await TokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan. Silakan login ulang.');
    }

    final keywordList = keywords
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/tourhub/recommend');
    final body = {
      'kategori_preferensi': categories,
      'kabupaten_kota': location.kabupatenKota,
      'kecamatan': location.kecamatan,
      'keywords': keywordList,
      'min_rating': minRating,
      'top_n': topN,
      'weather': weather,
      'visit_day': visitDay,
      'is_high_season': isHighSeason,
      'use_bmkg': useBmkg,
      'bmkg_adm4': useBmkg ? location.bmkgAdm4 : null,
    };

    final response = await _postJson(uri, body, token: token);

    if (response.statusCode == 401) {
      await TokenStorage.clearToken();
      throw Exception('Sesi login habis. Silakan login ulang.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response.body));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format response rekomendasi tidak valid.');
    }

    return decoded;
  }

  static Future<_SimpleResponse> _postJson(
    Uri uri,
    Map<String, dynamic> body, {
    required String token,
  }) async {
    final client = HttpClient();

    try {
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
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
      // Abaikan parsing error.
    }

    return 'Gagal mengambil rekomendasi dari server.';
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
