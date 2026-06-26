import 'dart:convert';
import 'dart:io';

import '../../../core/config/app_config.dart';
import '../../../core/storage/token_storage.dart';
import 'wishlist_item.dart';

final class WishlistApi {
  const WishlistApi._();

  static List<WishlistItem>? _cachedWishlists;

  static Future<List<WishlistItem>> fetchWishlists({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedWishlists != null) {
      return _cachedWishlists!;
    }

    final token = await _requiredToken();

    final response = await _getJson(
      Uri.parse('${AppConfig.apiBaseUrl}/tourhub/wishlist'),
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
    if (decoded is! Map) {
      throw Exception('Format response wishlist tidak valid.');
    }

    final dynamic data = decoded['data'];
    final dynamic rows = data is Map ? data['data'] : data;

    if (rows is! List) {
      _cachedWishlists = const [];
      return _cachedWishlists!;
    }

    _cachedWishlists = rows
        .whereType<Map>()
        .map((item) => WishlistItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return _cachedWishlists!;
  }

  static Future<bool> isDestinationWished(
    Map<String, dynamic> destination,
  ) async {
    final wishlists = await fetchWishlists();
    final key = WishlistItem.compareKeyFromDestination(destination);

    return wishlists.any((item) => item.compareKey() == key);
  }

  static Future<bool> toggleWishlist({
    required Map<String, dynamic> destination,
    int? recommendationLogId,
  }) async {
    final token = await _requiredToken();

    final body = <String, dynamic>{
      'destination': _normalizeDestinationPayload(destination),
      if (recommendationLogId != null)
        'recommendation_log_id': recommendationLogId,
    };

    final response = await _postJson(
      Uri.parse('${AppConfig.apiBaseUrl}/tourhub/wishlist/toggle'),
      body,
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
    if (decoded is! Map) {
      throw Exception('Format response wishlist tidak valid.');
    }

    _cachedWishlists = null;

    return decoded['wished'] == true;
  }

  static Future<void> deleteWishlist(int wishlistId) async {
    final token = await _requiredToken();

    final response = await _deleteJson(
      Uri.parse('${AppConfig.apiBaseUrl}/tourhub/wishlist/$wishlistId'),
      token: token,
    );

    if (response.statusCode == 401) {
      await TokenStorage.clearToken();
      throw Exception('Sesi login habis. Silakan login ulang.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response.body));
    }

    _cachedWishlists = null;
  }

  static void clearCache() {
    _cachedWishlists = null;
  }

  static Map<String, dynamic> _normalizeDestinationPayload(
    Map<String, dynamic> item,
  ) {
    final result = <String, dynamic>{
      'id_tempat': item['id_tempat'] ?? item['id'] ?? item['destination_id'],
      'nama_tempat_wisata':
          item['nama_tempat_wisata'] ?? item['destination_name'] ?? item['name'],
      'kategori': item['kategori'] ?? item['category'],
      'tipe_wisata': item['tipe_wisata'] ?? item['tourism_type'],
      'kecamatan': item['kecamatan'] ?? item['subdistrict'],
      'kabupaten_kota': item['kabupaten_kota'] ?? item['city'],
      'rating': item['rating'],
      'jumlah_rating': item['jumlah_rating'] ?? item['review_count'],
      'latitude': item['latitude'],
      'longitude': item['longitude'],
      'link_google_maps':
          item['link_google_maps'] ?? item['google_maps_url'] ?? item['maps_url'],
      'link_gambar': item['link_gambar'] ?? item['image_url'],
      'alasan': item['alasan'] ?? item['reason'],
      'final_score': item['final_score'],
      'cbf_score': item['cbf_score'],
      'rating_score': item['rating_score'],
      'popularity_score': item['popularity_score'],
      'context_multiplier': item['context_multiplier'],
    };

    result.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      return false;
    });

    return result;
  }

  static Future<String> _requiredToken() async {
    final token = await TokenStorage.readToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Token login tidak ditemukan. Silakan login ulang.');
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

  static Future<_SimpleResponse> _deleteJson(
    Uri uri, {
    required String token,
  }) async {
    final client = HttpClient();

    try {
      final request = await client.deleteUrl(uri);
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

      if (decoded is Map) {
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

    return 'Gagal memproses wishlist.';
  }
}

final class _SimpleResponse {
  const _SimpleResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;
}
