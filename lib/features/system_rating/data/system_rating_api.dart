import 'dart:convert';
import 'dart:io';

import '../../../core/config/app_config.dart';
import '../../../core/storage/token_storage.dart';

/// API khusus rating sistem TourHub.
///
/// Konsep final:
/// - Rating ini menilai kualitas sistem rekomendasi TourHub.
/// - Bukan rating destinasi wisata.
/// - Satu user cukup memberi rating satu kali.
/// - recommendation_log_id hanya dipakai sebagai konteks saat user pertama kali rating.
final class SystemRatingApi {
  const SystemRatingApi._();

  static Uri get _statusUri =>
      Uri.parse('${AppConfig.apiBaseUrl}/tourhub/system-ratings/status');

  static Uri get _storeUri =>
      Uri.parse('${AppConfig.apiBaseUrl}/tourhub/system-ratings');

  static Future<SystemRatingStatus> fetchStatus() async {
    final token = await TokenStorage.readToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Token login tidak ditemukan. Silakan login ulang.');
    }

    final response = await _requestJson(
      method: 'GET',
      uri: _statusUri,
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
      throw Exception('Format status rating sistem tidak valid.');
    }

    return SystemRatingStatus.fromJson(Map<String, dynamic>.from(decoded));
  }

  static Future<SystemRatingSubmitResult> submitRating({
    required int rating,
    String? comment,
    int? recommendationLogId,
    String source = 'mobile_recommendation_page',
    String platform = 'mobile',
  }) async {
    if (rating < 1 || rating > 5) {
      throw Exception('Rating sistem harus bernilai 1 sampai 5.');
    }

    final token = await TokenStorage.readToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Token login tidak ditemukan. Silakan login ulang.');
    }

    final body = <String, dynamic>{
      'rating': rating,
      'comment': comment?.trim().isEmpty == true ? null : comment?.trim(),
      'source': source,
      'platform': platform,
    };

    if (recommendationLogId != null && recommendationLogId > 0) {
      body['recommendation_log_id'] = recommendationLogId;
    }

    final response = await _requestJson(
      method: 'POST',
      uri: _storeUri,
      token: token,
      body: body,
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
      throw Exception('Format response rating sistem tidak valid.');
    }

    return SystemRatingSubmitResult.fromJson(Map<String, dynamic>.from(decoded));
  }

  static Future<_SimpleResponse> _requestJson({
    required String method,
    required Uri uri,
    required String token,
    Map<String, dynamic>? body,
  }) async {
    final client = HttpClient();

    try {
      final request = switch (method.toUpperCase()) {
        'POST' => await client.postUrl(uri),
        'GET' => await client.getUrl(uri),
        _ => throw UnsupportedError('HTTP method tidak didukung: $method'),
      };

      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');

      if (body != null) {
        request.add(utf8.encode(jsonEncode(body)));
      }

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
      // Abaikan parsing error agar pesan fallback tetap aman.
    }

    return 'Gagal memproses rating sistem TourHub.';
  }
}

final class SystemRatingStatus {
  const SystemRatingStatus({
    required this.hasRating,
    this.id,
    this.rating,
    this.comment,
    this.source,
    this.platform,
    this.ratedAt,
  });

  final bool hasRating;
  final int? id;
  final int? rating;
  final String? comment;
  final String? source;
  final String? platform;
  final String? ratedAt;

  factory SystemRatingStatus.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']) ?? json;

    final ratingMap = _asMap(data['rating']) ??
        _asMap(data['system_rating']) ??
        _asMap(data['systemRating']) ??
        _asMap(data['user_rating']);

    final ratingSource = ratingMap ?? data;

    final ratingValue = _toInt(
      ratingSource['rating'] ??
          ratingSource['nilai'] ??
          data['rating_value'] ??
          data['value'],
    );

    final hasRating = _toBool(
          data['has_rating'] ??
              data['hasRating'] ??
              data['already_rated'] ??
              data['alreadyRated'] ??
              data['exists'],
        ) ||
        ratingMap != null ||
        ratingValue != null;

    return SystemRatingStatus(
      hasRating: hasRating,
      id: _toInt(ratingSource['id']),
      rating: ratingValue,
      comment: _toNullableString(
        ratingSource['comment'] ?? ratingSource['komentar'],
      ),
      source: _toNullableString(ratingSource['source']),
      platform: _toNullableString(ratingSource['platform']),
      ratedAt: _toNullableString(
        ratingSource['rated_at'] ??
            ratingSource['created_at'] ??
            ratingSource['updated_at'],
      ),
    );
  }
}

final class SystemRatingSubmitResult {
  const SystemRatingSubmitResult({
    required this.success,
    required this.message,
    this.rating,
  });

  final bool success;
  final String message;
  final SystemRatingStatus? rating;

  factory SystemRatingSubmitResult.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final ratingData = _asMap(data?['rating']) ??
        _asMap(data?['system_rating']) ??
        _asMap(json['rating']) ??
        _asMap(json['system_rating']) ??
        data;

    return SystemRatingSubmitResult(
      success: _toBool(json['success'] ?? true),
      message: _toNullableString(json['message']) ??
          'Terima kasih, rating sistem berhasil dikirim.',
      rating: ratingData == null
          ? null
          : SystemRatingStatus.fromJson(<String, dynamic>{'data': ratingData}),
    );
  }
}

final class _SimpleResponse {
  const _SimpleResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return null;
}

int? _toInt(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

bool _toBool(Object? value) {
  if (value == null) {
    return false;
  }

  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final normalized = value.toString().trim().toLowerCase();

  return normalized == 'true' ||
      normalized == '1' ||
      normalized == 'yes' ||
      normalized == 'ya';
}

String? _toNullableString(Object? value) {
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();

  return text.isEmpty ? null : text;
}
