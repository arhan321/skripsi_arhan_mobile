class RecommendationHistoryItem {
  const RecommendationHistoryItem({
    required this.id,
    required this.status,
    required this.weatherSource,
    required this.weatherUsed,
    required this.totalCandidates,
    required this.responseTimeMs,
    required this.createdAt,
    required this.requestPayload,
    required this.responsePayload,
    required this.errorMessage,
  });

  final int id;
  final String status;
  final String? weatherSource;
  final String? weatherUsed;
  final int? totalCandidates;
  final int? responseTimeMs;
  final DateTime? createdAt;
  final Map<String, dynamic> requestPayload;
  final Map<String, dynamic> responsePayload;
  final String? errorMessage;

  factory RecommendationHistoryItem.fromJson(Map<String, dynamic> json) {
    return RecommendationHistoryItem(
      id: int.tryParse((json['id'] ?? '0').toString()) ?? 0,
      status: (json['status'] ?? '-').toString(),
      weatherSource: json['weather_source']?.toString(),
      weatherUsed: json['weather_used']?.toString(),
      totalCandidates: int.tryParse(
        (json['total_candidates'] ?? '').toString(),
      ),
      responseTimeMs: int.tryParse((json['response_time_ms'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      requestPayload: _mapFromDynamic(json['request_payload']),
      responsePayload: _mapFromDynamic(json['response_payload']),
      errorMessage: json['error_message']?.toString(),
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';

  List<Map<String, dynamic>> get recommendations {
    final raw = responsePayload['recommendations'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList()
      ..sort((a, b) {
        final scoreA =
            double.tryParse((a['final_score'] ?? '0').toString()) ?? 0;
        final scoreB =
            double.tryParse((b['final_score'] ?? '0').toString()) ?? 0;
        return scoreB.compareTo(scoreA);
      });
  }

  Map<String, dynamic>? get topRecommendation {
    final items = recommendations;
    if (items.isEmpty) return null;
    return items.first;
  }

  String get topDestinationName {
    final top = topRecommendation;
    if (top == null) return '-';
    return (top['nama_tempat_wisata'] ?? '-').toString();
  }

  String get locationLabel {
    final kabupaten = requestPayload['kabupaten_kota']?.toString() ?? '-';
    final kecamatan = requestPayload['kecamatan']?.toString() ?? '-';
    return '$kabupaten — $kecamatan';
  }

  String get categoriesLabel {
    final categories = requestPayload['kategori_preferensi'];
    if (categories is List && categories.isNotEmpty) {
      return categories.map((item) => item.toString()).join(', ');
    }
    return '-';
  }

  String get displayDate {
    final value = createdAt;
    if (value == null) return '-';

    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}

Map<String, dynamic> _mapFromDynamic(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}
