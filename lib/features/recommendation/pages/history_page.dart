import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../data/recommendation_history_api.dart';
import '../data/recommendation_history_model.dart';

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
    setState(() {
      _future = RecommendationHistoryApi.fetchHistories();
    });
    await _future;
  }

  void _openDetail(RecommendationHistoryItem item) {
    Navigator.pushNamed(
      context,
      AppRoutes.historyDetail,
      arguments: item.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Riwayat Rekomendasi', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            Text('History hasil TourHub user', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
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
                  _HeroHistoryCard(total: 0),
                  const SizedBox(height: 16),
                  _ErrorState(message: snapshot.error.toString().replaceFirst('Exception: ', ''), onRetry: _refresh),
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
          colors: [Color(0xFF020617), Color(0xFF1D4ED8)],
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: const Text(
                    'USER HISTORY',
                    style: TextStyle(color: Color(0xFFBFDBFE), fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Riwayat rekomendasi wisata kamu.',
                  style: TextStyle(color: Colors.white, fontSize: 26, height: 1.15, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Semua request rekomendasi yang pernah kamu jalankan tersimpan di Laravel.',
                  style: TextStyle(color: Color(0xFFE2E8F0), height: 1.45, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 82,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Column(
              children: [
                Text('$total', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                const Text('Log', style: TextStyle(color: Color(0xFFBFDBFE), fontSize: 12, fontWeight: FontWeight.w800)),
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
    final finalScore = top?['final_score']?.toString() ?? '-';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: SizedBox(
                height: 150,
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
                                Text(item.topDestinationName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                Text(item.locationLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Text('Score', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w800)),
                                Text(finalScore, style: const TextStyle(color: Color(0xFF020617), fontSize: 15, fontWeight: FontWeight.w900)),
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
                      _Pill(text: item.isSuccess ? 'Success' : 'Failed', color: item.isSuccess ? const Color(0xFF059669) : const Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      _Pill(text: item.weatherUsed ?? '-', color: const Color(0xFF2563EB)),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _MiniMetric(label: 'Candidates', value: (item.totalCandidates ?? '-').toString())),
                      const SizedBox(width: 10),
                      Expanded(child: _MiniMetric(label: 'Response', value: item.responseTimeMs == null ? '-' : '${item.responseTimeMs} ms')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(item.displayDate, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w700)),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Color(0xFF020617), fontSize: 16, fontWeight: FontWeight.w900)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
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
        child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF64748B), size: 34),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: const Column(
        children: [
          Icon(Icons.history_rounded, size: 44, color: Color(0xFF64748B)),
          SizedBox(height: 14),
          Text('Belum ada riwayat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          SizedBox(height: 6),
          Text('Jalankan rekomendasi terlebih dahulu, nanti history akan muncul di sini.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B))),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFFECACA))),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 38),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF7F1D1D), fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          ElevatedButton.icon(onPressed: () => onRetry(), icon: const Icon(Icons.refresh_rounded), label: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}
