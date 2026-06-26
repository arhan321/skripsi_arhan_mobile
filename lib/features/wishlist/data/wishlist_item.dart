final class WishlistItem {
  const WishlistItem({
    required this.id,
    required this.destinationName,
    this.destinationId,
    this.destinationKey,
    this.category,
    this.tourismType,
    this.subdistrict,
    this.city,
    this.rating,
    this.reviewCount,
    this.latitude,
    this.longitude,
    this.googleMapsUrl,
    this.imageUrl,
    this.reason,
    this.snapshot = const {},
    this.createdAt,
  });

  final int id;
  final String destinationName;
  final String? destinationId;
  final String? destinationKey;
  final String? category;
  final String? tourismType;
  final String? subdistrict;
  final String? city;
  final double? rating;
  final int? reviewCount;
  final double? latitude;
  final double? longitude;
  final String? googleMapsUrl;
  final String? imageUrl;
  final String? reason;
  final Map<String, dynamic> snapshot;
  final DateTime? createdAt;

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: _intOrZero(json['id']),
      destinationName: _stringOrDefault(
        json['destination_name'] ??
            json['nama_tempat_wisata'] ??
            json['name'],
        'Destinasi Wisata',
      ),
      destinationId: _stringOrNull(json['destination_id'] ?? json['id_tempat']),
      destinationKey: _stringOrNull(json['destination_key']),
      category: _stringOrNull(json['category'] ?? json['kategori']),
      tourismType: _stringOrNull(json['tourism_type'] ?? json['tipe_wisata']),
      subdistrict: _stringOrNull(json['subdistrict'] ?? json['kecamatan']),
      city: _stringOrNull(json['city'] ?? json['kabupaten_kota']),
      rating: _doubleOrNull(json['rating']),
      reviewCount: _intOrNull(json['review_count'] ?? json['jumlah_rating']),
      latitude: _doubleOrNull(json['latitude']),
      longitude: _doubleOrNull(json['longitude']),
      googleMapsUrl: _stringOrNull(
        json['google_maps_url'] ??
            json['link_google_maps'] ??
            json['maps_url'],
      ),
      imageUrl: _stringOrNull(json['image_url'] ?? json['link_gambar']),
      reason: _stringOrNull(json['reason'] ?? json['alasan']),
      snapshot: _mapFromDynamic(json['snapshot']),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }

  String get locationLabel {
    if ((subdistrict ?? '').isNotEmpty && (city ?? '').isNotEmpty) {
      return '$subdistrict - $city';
    }

    if ((subdistrict ?? '').isNotEmpty) {
      return subdistrict!;
    }

    if ((city ?? '').isNotEmpty) {
      return city!;
    }

    return 'Lokasi belum tersedia';
  }

  String get ratingLabel {
    final value = rating;
    if (value == null) return '-';

    final text = value.toStringAsFixed(1);
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }

  String get reviewLabel {
    final value = reviewCount;
    if (value == null) return '-';
    return value.toString();
  }

  String get createdAtLabel {
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

  String compareKey() {
    final name = _normalize(destinationName);
    final sub = _normalize(subdistrict);
    final cty = _normalize(city);
    final lat = _normalize(latitude);
    final lng = _normalize(longitude);

    return '$name|$sub|$cty|$lat|$lng';
  }

  static String compareKeyFromDestination(Map<String, dynamic> destination) {
    final name = _normalize(
      destination['nama_tempat_wisata'] ??
          destination['destination_name'] ??
          destination['name'],
    );

    final sub = _normalize(destination['kecamatan'] ?? destination['subdistrict']);
    final cty = _normalize(destination['kabupaten_kota'] ?? destination['city']);
    final lat = _normalize(destination['latitude']);
    final lng = _normalize(destination['longitude']);

    return '$name|$sub|$cty|$lat|$lng';
  }

  static String _normalize(Object? value) {
    return (value ?? '').toString().trim().toLowerCase();
  }
}

String? _stringOrNull(Object? value) {
  if (value == null) return null;

  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String _stringOrDefault(Object? value, String fallback) {
  final text = _stringOrNull(value);
  return text ?? fallback;
}

int _intOrZero(Object? value) {
  return _intOrNull(value) ?? 0;
}

int? _intOrNull(Object? value) {
  if (value == null) return null;
  return int.tryParse(value.toString());
}

double? _doubleOrNull(Object? value) {
  if (value == null) return null;
  return double.tryParse(value.toString());
}

Map<String, dynamic> _mapFromDynamic(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}
