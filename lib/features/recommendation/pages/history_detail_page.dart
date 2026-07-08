import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/utils/maps_launcher.dart';
import '../data/recommendation_history_api.dart';
import '../data/recommendation_history_model.dart';
import '../../../shared/widgets/tourhub_sidebar.dart';
import '../../wishlist/widgets/wishlist_toggle_button.dart';

String _friendlyStatus(bool isSuccess) {
  return isSuccess ? 'Berhasil' : 'Belum Berhasil';
}

String _formatWeather(dynamic weather) {
  final value = (weather ?? '-').toString().trim();

  if (value.isEmpty || value == '-') return '-';

  return '${value[0].toUpperCase()}${value.substring(1)}';
}

String _recommendationStatus(Map? item, int rank) {
  if (rank == 1) return 'Paling Cocok';

  final score = double.tryParse((item?['final_score'] ?? '0').toString()) ?? 0;

  if (score >= 0.75) return 'Sangat Cocok';
  if (score >= 0.45) return 'Cocok';

  return 'Cukup Cocok';
}

String _suitabilityLabel(Map item) {
  final score = double.tryParse((item['cbf_score'] ?? '0').toString()) ?? 0;

  if (score >= 0.70) return 'Sangat Sesuai';
  if (score >= 0.40) return 'Sesuai';
  if (score > 0) return 'Cukup Sesuai';

  return 'Sesuai Pilihan';
}

String _visitConditionLabel(Map? item) {
  final value =
      double.tryParse((item?['context_multiplier'] ?? '1').toString()) ?? 1;

  if (value >= 1.08) return 'Sangat Mendukung';
  if (value >= 1.00) return 'Mendukung';
  if (value >= 0.90) return 'Cukup Mendukung';

  return 'Perlu Dipertimbangkan';
}

String _visitDayLabel(dynamic value) {
  switch ((value ?? '').toString().toLowerCase()) {
    case 'weekday':
      return 'Hari Biasa';
    case 'weekend':
      return 'Akhir Pekan';
    default:
      final text = (value ?? '-').toString().trim();
      return text.isEmpty ? '-' : text;
  }
}

String _yesNoLabel(dynamic value) {
  if (value == true) return 'Ya';

  final text = (value ?? '').toString().toLowerCase();

  if (text == '1' || text == 'true' || text == 'ya') return 'Ya';

  return 'Tidak';
}

String _cleanReadableText(dynamic value) {
  final text = (value ?? '').toString().trim();

  if (text.isEmpty || text == '-') return '-';

  final lower = text.toLowerCase();

  switch (lower) {
    case 'outdoor':
      return 'Luar Ruangan';
    case 'indoor':
      return 'Dalam Ruangan';
    case 'mixed':
      return 'Fleksibel';
    case 'weekday':
      return 'Hari Biasa';
    case 'weekend':
      return 'Akhir Pekan';
    case 'unknown':
      return 'Tidak Diketahui';
    default:
      final words = text
          .replaceAll('_', ' ')
          .replaceAll('-', ' ')
          .split(RegExp(r'\s+'))
          .where((word) => word.trim().isNotEmpty)
          .map((word) {
            final clean = word.trim();
            if (clean.isEmpty) return clean;
            return '${clean[0].toUpperCase()}${clean.substring(1).toLowerCase()}';
          })
          .join(' ');

      return words.isEmpty ? '-' : words;
  }
}

String _formatFriendlyNumber(dynamic value) {
  final number = double.tryParse((value ?? '').toString());

  if (number == null) return '-';

  final rounded = number.round().toString();

  return rounded.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
}

String _formatFriendlyRating(dynamic value) {
  final rating = double.tryParse((value ?? '').toString());

  if (rating == null || rating <= 0) return '-';

  final text = rating.toStringAsFixed(1);

  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

String _friendlyReason(Map item) {
  final category = _cleanReadableText(item['kategori']);
  final type = _cleanReadableText(item['tipe_wisata']);
  final rating = _formatFriendlyRating(item['rating']);
  final reviews = _formatFriendlyNumber(item['jumlah_rating']);
  final suitability = _suitabilityLabel(item).toLowerCase();
  final visitCondition = _visitConditionLabel(item).toLowerCase();

  final sentences = <String>[];

  final categoryText = category == '-'
      ? ''
      : ' untuk wisata ${category.toLowerCase()}';

  sentences.add(
    'Destinasi ini $suitability dengan preferensi pencarianmu$categoryText.',
  );

  if (rating != '-' && reviews != '-') {
    sentences.add(
      'Tempat ini memiliki rating $rating dan didukung $reviews ulasan pengunjung.',
    );
  } else if (rating != '-') {
    sentences.add('Tempat ini memiliki rating $rating dari pengunjung.');
  } else if (reviews != '-') {
    sentences.add('Tempat ini sudah memiliki $reviews ulasan pengunjung.');
  }

  if (type != '-') {
    sentences.add(
      'Jenis kunjungannya $type, sehingga bisa disesuaikan dengan rencana perjalananmu.',
    );
  }

  sentences.add(
    'Kondisi kunjungan saat itu $visitCondition, jadi destinasi ini layak dipertimbangkan untuk perjalananmu.',
  );

  return sentences.join(' ');
}

String _payloadText(Map payload, String key, {String fallback = '-'}) {
  final value = payload[key];
  final text = (value ?? '').toString().trim();

  return text.isEmpty ? fallback : text;
}

String _keywordText(Map payload) {
  final keywords = payload['keywords'];

  if (keywords is List) {
    final text = keywords
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .join(', ');

    return text.isEmpty ? '-' : text;
  }

  final text = (keywords ?? '').toString().trim();

  return text.isEmpty ? '-' : text;
}

class HistoryDetailPage extends StatefulWidget {
  const HistoryDetailPage({super.key});

  @override
  State<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends State<HistoryDetailPage> {
  Future<RecommendationHistoryItem>? _future;
  int? _id;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_future != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    _id = args is int ? args : int.tryParse((args ?? '').toString());

    if (_id == null || _id == 0) {
      _future = Future.error('ID riwayat tidak valid.');
    } else {
      _future = RecommendationHistoryApi.fetchDetail(_id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      drawer: const TourHubSidebar(activeMenu: TourHubSidebarMenu.history),
      drawerEnableOpenDragGesture: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 0,
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu_rounded),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Riwayat',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            Text(
              'Ringkasan rekomendasi wisata',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Wishlist',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.wishlist),
            icon: const Icon(Icons.star_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<RecommendationHistoryItem>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final item = snapshot.data!;
          final recommendations = item.recommendations;
          final top = item.topRecommendation;

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _DetailHero(item: item, top: top),
              const SizedBox(height: 16),
              _ParameterCard(item: item),
              const SizedBox(height: 16),
              _RankingHeader(total: recommendations.length),
              const SizedBox(height: 12),
              if (recommendations.isEmpty)
                const _NoRecommendationCard()
              else
                ...recommendations.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _RankingCard(
                      rank: entry.key + 1,
                      item: entry.value,
                      logId: item.id,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.item, required this.top});

  final RecommendationHistoryItem item;
  final Map? top;

  @override
  Widget build(BuildContext context) {
    final topMap = top == null ? null : Map<String, dynamic>.from(top!);
    final imageUrl = topMap?['link_gambar']?.toString();
    final mapsUrl = topMap?['link_google_maps']?.toString();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF020617), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF020617).withOpacity(0.16),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _ImageFallback(),
                    )
                  else
                    const _ImageFallback(),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Color(0xEE020617)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFACC15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  '🏆 Pilihan Utama',
                                  style: TextStyle(
                                    color: Color(0xFF020617),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item.topDestinationName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 27,
                                  height: 1.1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.locationLabel,
                                style: const TextStyle(
                                  color: Color(0xFFE2E8F0),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 116),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Status',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                _recommendationStatus(top, 1),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF020617),
                                  fontSize: 14,
                                  height: 1.1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _DarkMetric(
                      label: 'Status Pencarian',
                      value: _friendlyStatus(item.isSuccess),
                    ),
                    _DarkMetric(
                      label: 'Cuaca Saat Itu',
                      value: _formatWeather(item.weatherUsed),
                    ),
                    _DarkMetric(
                      label: 'Pilihan Tersedia',
                      value: (item.totalCandidates ?? '-').toString(),
                    ),
                    _DarkMetric(
                      label: 'Kondisi Kunjungan',
                      value: _visitConditionLabel(top),
                    ),
                  ],
                ),
                if (topMap != null) ...[
                  const SizedBox(height: 14),
                  WishlistToggleButton(
                    destination: topMap,
                    recommendationLogId: item.id,
                  ),
                ],
                if (mapsUrl != null && mapsUrl.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => openGoogleMapsUrl(context, mapsUrl),
                      icon: const Icon(Icons.map_outlined, size: 19),
                      label: const Text('Buka Google Maps'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParameterCard extends StatelessWidget {
  const _ParameterCard({required this.item});

  final RecommendationHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final payload = item.requestPayload;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilihan yang Kamu Gunakan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF020617),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ringkasan pilihan yang kamu masukkan saat mencari rekomendasi wisata.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _LightMetric(label: 'Kategori', value: item.categoriesLabel),
              _LightMetric(label: 'Lokasi', value: item.locationLabel),
              _LightMetric(
                label: 'Rating Minimal',
                value: _payloadText(payload, 'min_rating'),
              ),
              _LightMetric(
                label: 'Jumlah Pilihan',
                value: _payloadText(payload, 'top_n'),
              ),
              _LightMetric(
                label: 'Hari Kunjungan',
                value: _visitDayLabel(payload['visit_day']),
              ),
              _LightMetric(
                label: 'Cuaca Otomatis',
                value: payload['use_bmkg'] == true ? 'Aktif' : 'Manual',
              ),
              _LightMetric(
                label: 'Musim Ramai',
                value: _yesNoLabel(payload['is_high_season']),
              ),
              _LightMetric(label: 'Kata Kunci', value: _keywordText(payload)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankingHeader extends StatelessWidget {
  const _RankingHeader({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilihan Wisata yang Cocok',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
              Text(
                'Destinasi paling atas adalah pilihan yang paling direkomendasikan.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF020617),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$total pilihan',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({
    required this.rank,
    required this.item,
    required this.logId,
  });

  final int rank;
  final Map<String, dynamic> item;
  final int logId;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item['link_gambar']?.toString();
    final mapsUrl = item['link_google_maps']?.toString();
    final reason = _friendlyReason(item);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: rank == 1 ? const Color(0xFFFACC15) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: SizedBox(
              height: 170,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _ImageFallback(),
                    )
                  else
                    const _ImageFallback(),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Color(0xCC020617)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: rank == 1
                            ? const Color(0xFFFACC15)
                            : const Color(0xFF020617),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        rank == 1 ? 'Pilihan Utama' : 'Rekomendasi',
                        style: TextStyle(
                          color: rank == 1
                              ? const Color(0xFF020617)
                              : Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (item['nama_tempat_wisata'] ?? '-').toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '${item['kecamatan'] ?? '-'} - ${item['kabupaten_kota'] ?? '-'}',
                                style: const TextStyle(
                                  color: Color(0xFFE2E8F0),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 112),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Status',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                _recommendationStatus(item, rank),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF020617),
                                  fontSize: 13,
                                  height: 1.1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (rank == 1) const _GoldBadge(text: 'Paling Cocok'),
                    _BlueBadge(text: (item['kategori'] ?? '-').toString()),
                    _GrayBadge(text: (item['tipe_wisata'] ?? '-').toString()),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _LightMetric(
                        label: 'Rating',
                        value: (item['rating'] ?? '-').toString(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LightMetric(
                        label: 'Ulasan',
                        value: (item['jumlah_rating'] ?? '-').toString(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _LightMetric(
                        label: 'Kesesuaian',
                        value: _suitabilityLabel(item),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LightMetric(
                        label: 'Kondisi Kunjungan',
                        value: _visitConditionLabel(item),
                      ),
                    ),
                  ],
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      reason,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        height: 1.45,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: WishlistToggleButton(
                        destination: item,
                        recommendationLogId: logId,
                        compact: true,
                      ),
                    ),
                    if (mapsUrl != null && mapsUrl.trim().isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                openGoogleMapsUrl(context, mapsUrl),
                            icon: const Icon(Icons.map_outlined, size: 19),
                            label: const Text('Maps'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkMetric extends StatelessWidget {
  const _DarkMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFBFDBFE),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LightMetric extends StatelessWidget {
  const _LightMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 135),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF020617),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlueBadge extends StatelessWidget {
  const _BlueBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFDBEAFE),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF1D4ED8),
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _GrayBadge extends StatelessWidget {
  const _GrayBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF475569),
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _GoldBadge extends StatelessWidget {
  const _GoldBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF3C7),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFFB45309),
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Color(0xFF64748B),
          size: 36,
        ),
      ),
    );
  }
}

class _NoRecommendationCard extends StatelessWidget {
  const _NoRecommendationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Text(
        'Belum ada pilihan wisata pada riwayat ini.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
      ),
    );
  }
}
