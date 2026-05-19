import 'package:flutter/material.dart';

import '../data/recommendation_history_api.dart';
import '../data/recommendation_history_model.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detail Riwayat', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            Text('Ranking rekomendasi user', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
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
                child: Text(snapshot.error.toString(), textAlign: TextAlign.center),
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
                    child: _RankingCard(rank: entry.key + 1, item: entry.value),
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
  final Map<String, dynamic>? top;

  @override
  Widget build(BuildContext context) {
    final imageUrl = top?['link_gambar']?.toString();
    final score = top?['final_score']?.toString() ?? '-';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF020617), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: const Color(0xFF020617).withOpacity(0.16), blurRadius: 28, offset: const Offset(0, 16))],
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
                    Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _ImageFallback())
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
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(color: const Color(0xFFFACC15), borderRadius: BorderRadius.circular(999)),
                                child: const Text('🏆 Top Recommendation', style: TextStyle(color: Color(0xFF020617), fontSize: 11, fontWeight: FontWeight.w900)),
                              ),
                              const SizedBox(height: 10),
                              Text(item.topDestinationName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 27, height: 1.1, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 6),
                              Text(item.locationLabel, style: const TextStyle(color: Color(0xFFE2E8F0), fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            children: [
                              const Text('Score', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w800)),
                              Text(score, style: const TextStyle(color: Color(0xFF020617), fontSize: 20, fontWeight: FontWeight.w900)),
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
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _DarkMetric(label: 'Status', value: item.isSuccess ? 'Success' : 'Failed'),
                _DarkMetric(label: 'Cuaca', value: item.weatherUsed ?? '-'),
                _DarkMetric(label: 'Candidates', value: (item.totalCandidates ?? '-').toString()),
                _DarkMetric(label: 'Response', value: item.responseTimeMs == null ? '-' : '${item.responseTimeMs} ms'),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Preferensi yang Digunakan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF020617))),
          const SizedBox(height: 6),
          const Text('Ringkasan parameter user saat request rekomendasi dibuat.', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _LightMetric(label: 'Kategori', value: item.categoriesLabel),
              _LightMetric(label: 'Lokasi', value: item.locationLabel),
              _LightMetric(label: 'Min Rating', value: (payload['min_rating'] ?? '-').toString()),
              _LightMetric(label: 'Top N', value: (payload['top_n'] ?? '-').toString()),
              _LightMetric(label: 'Hari', value: (payload['visit_day'] ?? '-').toString()),
              _LightMetric(label: 'BMKG', value: payload['use_bmkg'] == true ? 'Aktif' : 'Manual'),
              _LightMetric(label: 'High Season', value: payload['is_high_season'] == true ? 'Ya' : 'Tidak'),
              _LightMetric(label: 'ADM4', value: (payload['bmkg_adm4'] ?? '-').toString()),
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
              Text('Ranking Rekomendasi', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
              Text('Diurutkan berdasarkan final score tertinggi.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF020617), borderRadius: BorderRadius.circular(999)),
          child: Text('Total $total', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({required this.rank, required this.item});

  final int rank;
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item['link_gambar']?.toString();

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: rank == 1 ? const Color(0xFFFACC15) : const Color(0xFFE2E8F0))),
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
                    Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _ImageFallback())
                  else
                    const _ImageFallback(),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.transparent, Color(0xCC020617)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(color: rank == 1 ? const Color(0xFFFACC15) : const Color(0xFF020617), borderRadius: BorderRadius.circular(999)),
                      child: Text('#$rank', style: TextStyle(color: rank == 1 ? const Color(0xFF020617) : Colors.white, fontWeight: FontWeight.w900)),
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
                              Text((item['nama_tempat_wisata'] ?? '-').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                              Text('${item['kecamatan'] ?? '-'} - ${item['kabupaten_kota'] ?? '-'}', style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        Text((item['final_score'] ?? '-').toString(), style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
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
                    _BlueBadge(text: (item['kategori'] ?? '-').toString()),
                    _GrayBadge(text: (item['tipe_wisata'] ?? '-').toString()),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _LightMetric(label: 'Rating', value: (item['rating'] ?? '-').toString())),
                    const SizedBox(width: 10),
                    Expanded(child: _LightMetric(label: 'Ulasan', value: (item['jumlah_rating'] ?? '-').toString())),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _LightMetric(label: 'CBF', value: (item['cbf_score'] ?? '-').toString())),
                    const SizedBox(width: 10),
                    Expanded(child: _LightMetric(label: 'Context', value: (item['context_multiplier'] ?? '-').toString())),
                  ],
                ),
                if ((item['alasan'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Text((item['alasan'] ?? '').toString(), style: const TextStyle(color: Color(0xFF475569), height: 1.45, fontSize: 12, fontWeight: FontWeight.w600)),
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

class _DarkMetric extends StatelessWidget {
  const _DarkMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.12))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
      ]),
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
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF020617), fontSize: 15, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class _BlueBadge extends StatelessWidget {
  const _BlueBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 11, fontWeight: FontWeight.w900)),
      );
}

class _GrayBadge extends StatelessWidget {
  const _GrayBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: const TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w900)),
      );
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(color: const Color(0xFFE2E8F0), child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF64748B), size: 36)));
  }
}

class _NoRecommendationCard extends StatelessWidget {
  const _NoRecommendationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: const Text('Tidak ada rekomendasi pada riwayat ini.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
    );
  }
}
