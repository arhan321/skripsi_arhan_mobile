import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../data/recommendation_history_api.dart';
import '../data/recommendation_history_model.dart';
import '../../../shared/widgets/tourhub_sidebar.dart';

String _friendlyStatus(bool isSuccess) =>
    isSuccess ? 'Berhasil' : 'Belum Berhasil';

String _formatWeather(String? weather) {
  final value = (weather ?? '-').trim();
  if (value.isEmpty || value == '-') return '-';
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

String _visitDayLabel(dynamic value) {
  switch ((value ?? '').toString().toLowerCase()) {
    case 'weekday':
      return 'Hari Biasa';
    case 'weekend':
      return 'Akhir Pekan';
    default:
      final text = (value ?? '-').toString();
      return text.isEmpty ? '-' : text;
  }
}

String _yesNoLabel(dynamic value) {
  if (value == true) return 'Ya';
  final text = (value ?? '').toString().toLowerCase();
  if (text == '1' || text == 'true' || text == 'ya') return 'Ya';
  return 'Tidak';
}

String _recommendationStatus(Map<String, dynamic>? item, int rank) {
  if (rank == 1) return 'Paling Cocok';

  final score = double.tryParse((item?['final_score'] ?? '0').toString()) ?? 0;

  if (score >= 0.75) return 'Sangat Cocok';
  if (score >= 0.45) return 'Cocok';
  return 'Cukup Cocok';
}

String _suitabilityLabel(Map<String, dynamic>? item) {
  final score = double.tryParse((item?['cbf_score'] ?? '0').toString()) ?? 0;

  if (score >= 0.70) return 'Sangat Sesuai';
  if (score >= 0.40) return 'Sesuai';
  if (score > 0) return 'Cukup Sesuai';
  return 'Sesuai Pilihan';
}

String _visitConditionLabel(Map<String, dynamic>? item) {
  final value =
      double.tryParse((item?['context_multiplier'] ?? '1').toString()) ?? 1;

  if (value >= 1.08) return 'Sangat Mendukung';
  if (value >= 1.00) return 'Mendukung';
  if (value >= 0.90) return 'Cukup Mendukung';
  return 'Perlu Dipertimbangkan';
}

String _friendlyReason(Map<String, dynamic>? item) {
  var reason = (item?['alasan'] ?? '').toString().trim();
  if (reason.isEmpty) return '';

  reason = reason.replaceAll(
    RegExp(r'\s*\(\s*CBF\s*=\s*[^\)]*\)', caseSensitive: false),
    '',
  );
  reason = reason.replaceAll(
    RegExp(r'\s*CBF\s*=\s*[0-9\.]+\s*;?', caseSensitive: false),
    '',
  );
  reason = reason.replaceAll(
    RegExp(r'\s*context\s*=\s*[0-9\.]+\s*;?', caseSensitive: false),
    '',
  );
  reason = reason.replaceAll(
    RegExp(r'\s*final score\s*[^;\.]*[;\.]?', caseSensitive: false),
    '',
  );

  final replacements = <String, String>{
    'cocok dengan fitur/preferensi user': 'Cocok dengan preferensi pencarianmu',
    'fitur/preferensi user': 'preferensi pencarianmu',
    'user': 'kamu',
    'outdoor': 'luar ruangan',
    'indoor': 'dalam ruangan',
    'mixed': 'fleksibel',
    'weekend': 'akhir pekan',
    'weekday': 'hari biasa',
  };

  replacements.forEach((from, to) {
    reason = reason.replaceAll(RegExp(from, caseSensitive: false), to);
  });

  reason = reason.replaceAll(RegExp(r'\s+'), ' ');
  reason = reason.replaceAll(RegExp(r'\s*;\s*'), '; ');
  reason = reason.replaceAll(RegExp(r';\s*;'), ';');
  reason = reason.trim().replaceAll(RegExp(r'^[;\.\s]+|[;\.\s]+$'), '');

  if (reason.isEmpty) return '';

  return '${reason[0].toUpperCase()}${reason.substring(1)}.';
}

String _payloadText(
  Map<String, dynamic> payload,
  String key, {
  String fallback = '-',
}) {
  final value = payload[key];
  final text = (value ?? '').toString().trim();
  return text.isEmpty ? fallback : text;
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<RecommendationHistoryItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = RecommendationHistoryApi.fetchHistories();
  }

  Future<void> _refresh() async {
    setState(() => _future = RecommendationHistoryApi.fetchHistories());
    await _future;
  }

  void _openDetail(RecommendationHistoryItem item) {
    Navigator.pushNamed(context, AppRoutes.historyDetail, arguments: item.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      drawer: TourHubSidebar(activeMenu: TourHubSidebarMenu.history),
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
              'Riwayat Rekomendasi',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            Text(
              'Pencarian wisata yang pernah kamu lakukan',
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
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<RecommendationHistoryItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  const _HeroHistoryCard(total: 0),
                  const SizedBox(height: 16),
                  _ErrorState(
                    message: snapshot.error.toString().replaceFirst(
                      'Exception: ',
                      '',
                    ),
                    onRetry: _refresh,
                  ),
                ],
              );
            }

            final items = snapshot.data ?? const <RecommendationHistoryItem>[];

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _HeroHistoryCard(total: items.length),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  const _EmptyState()
                else
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _HistoryCard(
                        item: item,
                        onTap: () => _openDetail(item),
                      ),
                    ),
                  ),
                const SizedBox(height: 70),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroHistoryCard extends StatelessWidget {
  const _HeroHistoryCard({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF020617), Color(0xFF172554), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GlassBadge(text: 'RIWAYAT WISATA'),
                SizedBox(height: 14),
                Text(
                  'Riwayat rekomendasi wisata kamu.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Semua pencarian rekomendasi yang pernah kamu lakukan akan tersimpan di sini.',
                  style: TextStyle(
                    color: Color(0xFFE2E8F0),
                    height: 1.45,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 88,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Column(
              children: [
                Text(
                  '$total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Riwayat',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item, required this.onTap});

  final RecommendationHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final top = item.topRecommendation;
    final imageUrl = top?['link_gambar']?.toString();
    final statusText = _recommendationStatus(top, 1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: SizedBox(
                height: 160,
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
                                  item.topDestinationName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.locationLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                            constraints: const BoxConstraints(maxWidth: 116),
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
                                  statusText,
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
                  Row(
                    children: [
                      _Pill(
                        text: _friendlyStatus(item.isSuccess),
                        color: item.isSuccess
                            ? const Color(0xFF059669)
                            : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 8),
                      _Pill(
                        text: _formatWeather(item.weatherUsed),
                        color: const Color(0xFF2563EB),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniMetric(
                          label: 'Pilihan Ditemukan',
                          value: (item.totalCandidates ?? '-').toString(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniMetric(
                          label: 'Tanggal Pencarian',
                          value: item.displayDate,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.all(12),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF020617),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFBFDBFE),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
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
          size: 38,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.travel_explore_rounded,
            color: Color(0xFF2563EB),
            size: 42,
          ),
          SizedBox(height: 12),
          Text(
            'Belum ada riwayat rekomendasi',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF020617),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Setelah kamu mencari rekomendasi wisata, riwayatnya akan tampil di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7F1D1D),
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
