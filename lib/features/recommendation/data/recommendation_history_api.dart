import 'dart:convert';
import 'dart:io';

import '../../../core/config/app_config.dart';
import '../../../core/storage/token_storage.dart';
import 'recommendation_history_model.dart';

class RecommendationHistoryApi {
  const RecommendationHistoryApi._();

  /*
   * Fetch semua riwayat rekomendasi.
   *
   * Sebelumnya data terlihat hanya 10 karena endpoint Laravel biasanya
   * mengembalikan response pagination per halaman.
   *
   * Sekarang method ini akan:
   * 1. request halaman pertama dengan per_page besar,
   * 2. membaca informasi pagination,
   * 3. lanjut mengambil page berikutnya sampai semua data ter-load.
   */
  static Future<List<RecommendationHistoryItem>> fetchHistories({
    bool loadAllPages = true,
    int perPage = 100,
  }) async {
    final token = await _requiredToken();

    final baseUri = Uri.parse('${AppConfig.apiBaseUrl}/tourhub/history');

    if (!loadAllPages) {
      final page = await _fetchHistoryPage(
        _withPaginationQuery(baseUri, page: 1, perPage: perPage),
        token: token,
      );

      return page.items;
    }

    final allItems = <RecommendationHistoryItem>[];
    final usedIds = <int>{};
    final visitedUrls = <String>{};

    Uri? nextUri = _withPaginationQuery(baseUri, page: 1, perPage: perPage);

    /*
     * Safety limit supaya tidak infinite loop kalau response pagination
     * backend bermasalah.
     */
    for (var safety = 0; nextUri != null && safety < 100; safety++) {
      final normalizedUrl = nextUri.toString();

      if (visitedUrls.contains(normalizedUrl)) {
        break;
      }

      visitedUrls.add(normalizedUrl);

      final page = await _fetchHistoryPage(nextUri, token: token);

      for (final item in page.items) {
        if (usedIds.add(item.id)) {
          allItems.add(item);
        }
      }

      nextUri = _resolveNextPageUri(
        baseUri: baseUri,
        page: page,
        fallbackPerPage: perPage,
      );
    }

    allItems.sort((a, b) {
      final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return dateB.compareTo(dateA);
    });

    return allItems;
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

  static Future<_HistoryPageResult> _fetchHistoryPage(
    Uri uri, {
    required String token,
  }) async {
    final response = await _getJson(uri, token: token);

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

    final rows = _extractRows(decoded);

    final items = rows.whereType<Map>().map((item) {
      return RecommendationHistoryItem.fromJson(
        Map<String, dynamic>.from(item),
      );
    }).toList();

    return _HistoryPageResult(
      items: items,
      currentPage: _intFromDynamic(
        _valueFromPaths(decoded, const [
          ['data', 'current_page'],
          ['meta', 'current_page'],
          ['current_page'],
        ]),
      ),
      lastPage: _intFromDynamic(
        _valueFromPaths(decoded, const [
          ['data', 'last_page'],
          ['meta', 'last_page'],
          ['last_page'],
        ]),
      ),
      perPage: _intFromDynamic(
        _valueFromPaths(decoded, const [
          ['data', 'per_page'],
          ['meta', 'per_page'],
          ['per_page'],
        ]),
      ),
      nextPageUrl: _stringFromDynamic(
        _valueFromPaths(decoded, const [
          ['data', 'next_page_url'],
          ['links', 'next'],
          ['next_page_url'],
        ]),
      ),
    );
  }

  static List<dynamic> _extractRows(Map<String, dynamic> decoded) {
    final data = decoded['data'];

    /*
     * Format Laravel paginator:
     * {
     *   "data": {
     *     "current_page": 1,
     *     "data": [...]
     *   }
     * }
     */
    if (data is Map && data['data'] is List) {
      return List<dynamic>.from(data['data'] as List);
    }

    /*
     * Format non-paginated:
     * {
     *   "data": [...]
     * }
     */
    if (data is List) {
      return List<dynamic>.from(data);
    }

    /*
     * Format fallback:
     * {
     *   "histories": [...]
     * }
     */
    final histories = decoded['histories'];
    if (histories is List) {
      return List<dynamic>.from(histories);
    }

    return const [];
  }

  static Uri? _resolveNextPageUri({
    required Uri baseUri,
    required _HistoryPageResult page,
    required int fallbackPerPage,
  }) {
    final nextPageUrl = page.nextPageUrl;

    if (nextPageUrl != null && nextPageUrl.trim().isNotEmpty) {
      return _normalizeNextUri(baseUri, nextPageUrl);
    }

    final currentPage = page.currentPage;
    final lastPage = page.lastPage;

    if (currentPage != null && lastPage != null && currentPage < lastPage) {
      return _withPaginationQuery(
        baseUri,
        page: currentPage + 1,
        perPage: page.perPage ?? fallbackPerPage,
      );
    }

    return null;
  }

  static Uri _normalizeNextUri(Uri baseUri, String nextPageUrl) {
    final parsed = Uri.parse(nextPageUrl);

    if (parsed.hasScheme) {
      return parsed;
    }

    return baseUri.resolveUri(parsed);
  }

  static Uri _withPaginationQuery(
    Uri uri, {
    required int page,
    required int perPage,
  }) {
    final existing = Map<String, String>.from(uri.queryParameters);

    existing['page'] = page.toString();
    existing['per_page'] = perPage.toString();

    return uri.replace(queryParameters: existing);
  }

  static Object? _valueFromPaths(
    Map<String, dynamic> source,
    List<List<String>> paths,
  ) {
    for (final path in paths) {
      Object? current = source;

      for (final key in path) {
        if (current is Map) {
          current = current[key];
        } else {
          current = null;
          break;
        }
      }

      if (current != null) {
        return current;
      }
    }

    return null;
  }

  static int? _intFromDynamic(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  static String? _stringFromDynamic(Object? value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    return text.isEmpty || text.toLowerCase() == 'null' ? null : text;
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

    return 'Gagal mengambil data riwayat rekomendasi.';
  }
}

class _HistoryPageResult {
  const _HistoryPageResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.nextPageUrl,
  });

  final List<RecommendationHistoryItem> items;
  final int? currentPage;
  final int? lastPage;
  final int? perPage;
  final String? nextPageUrl;
}

class _SimpleResponse {
  const _SimpleResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}
