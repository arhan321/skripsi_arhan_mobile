import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../data/recommendation_api.dart';
import '../data/tourhub_location.dart';

class RecommendationPage extends StatefulWidget {
  const RecommendationPage({super.key});

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  final _keywordController = TextEditingController();

  final Set<String> _selectedCategories = {'Alam'};
  TourHubLocation _selectedLocation = tourHubLocations.first;
  String _weather = 'cerah';
  String _visitDay = 'weekday';
  double _minRating = 4.0;
  int _topN = 10;
  bool _useBmkg = true;
  bool _isHighSeason = false;
  bool _isLoading = false;

  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await TokenStorage.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  Future<void> _submit() async {
    if (_selectedCategories.isEmpty) {
      _showSnack('Pilih minimal 1 kategori.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await RecommendationApi.recommend(
        categories: _selectedCategories.toList(),
        location: _selectedLocation,
        keywords: _keywordController.text,
        minRating: _minRating,
        topN: _topN,
        weather: _weather,
        visitDay: _visitDay,
        isHighSeason: _isHighSeason,
        useBmkg: _useBmkg,
      );

      if (!mounted) return;
      setState(() => _result = response);
      _showSnack('Rekomendasi berhasil dihitung.');
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recommendations = ((_result?['data']?['recommendations'] ?? []) as List?) ?? [];
    final weatherUsed = _result?['data']?['weather_used']?.toString();
    final totalCandidates = _result?['data']?['total_candidates']?.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(
        titleSpacing: 20,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TourHub Bali',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            Text(
              'Rekomendasi CBF + CARS',
              style: TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _logout,
            child: const Text('Logout'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _submit(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeroCard(),
            const SizedBox(height: 14),
            _FormCard(
              selectedCategories: _selectedCategories,
              onToggleCategory: (category) {
                setState(() {
                  if (_selectedCategories.contains(category)) {
                    _selectedCategories.remove(category);
                  } else {
                    _selectedCategories.add(category);
                  }
                });
              },
              selectedLocation: _selectedLocation,
              onLocationChanged: (value) {
                if (value != null) setState(() => _selectedLocation = value);
              },
              keywordController: _keywordController,
              minRating: _minRating,
              onMinRatingChanged: (value) => setState(() => _minRating = value),
              topN: _topN,
              onTopNChanged: (value) => setState(() => _topN = value),
              weather: _weather,
              onWeatherChanged: (value) {
                if (value != null) setState(() => _weather = value);
              },
              visitDay: _visitDay,
              onVisitDayChanged: (value) {
                if (value != null) setState(() => _visitDay = value);
              },
              useBmkg: _useBmkg,
              onUseBmkgChanged: (value) => setState(() => _useBmkg = value),
              isHighSeason: _isHighSeason,
              onHighSeasonChanged: (value) => setState(() => _isHighSeason = value),
              isLoading: _isLoading,
              onSubmit: _submit,
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              _ResultHeader(
                weatherUsed: weatherUsed ?? '-',
                totalCandidates: totalCandidates ?? '-',
                responseTimeMs: (_result?['response_time_ms'] ?? '-').toString(),
              ),
              const SizedBox(height: 12),
              if (recommendations.isEmpty)
                _EmptyResultCard()
              else
                ...recommendations.asMap().entries.map((entry) {
                  final item = Map<String, dynamic>.from(entry.value as Map);
                  return _RecommendationItemCard(
                    rank: entry.key + 1,
                    item: item,
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF071329), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Chip(
            label: Text('Machine Learning Recommendation System'),
            labelStyle: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            backgroundColor: Color(0x332196F3),
            side: BorderSide.none,
          ),
          SizedBox(height: 14),
          Text(
            'Pilihan utama untuk jelajahi Bali',
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.15),
          ),
          SizedBox(height: 10),
          Text(
            'CBF menghitung kecocokan preferensi, CARS menyesuaikan hasil berdasarkan cuaca, hari kunjungan, dan high season.',
            style: TextStyle(color: Color(0xFFD8E5FF), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.selectedCategories,
    required this.onToggleCategory,
    required this.selectedLocation,
    required this.onLocationChanged,
    required this.keywordController,
    required this.minRating,
    required this.onMinRatingChanged,
    required this.topN,
    required this.onTopNChanged,
    required this.weather,
    required this.onWeatherChanged,
    required this.visitDay,
    required this.onVisitDayChanged,
    required this.useBmkg,
    required this.onUseBmkgChanged,
    required this.isHighSeason,
    required this.onHighSeasonChanged,
    required this.isLoading,
    required this.onSubmit,
  });

  final Set<String> selectedCategories;
  final ValueChanged<String> onToggleCategory;
  final TourHubLocation selectedLocation;
  final ValueChanged<TourHubLocation?> onLocationChanged;
  final TextEditingController keywordController;
  final double minRating;
  final ValueChanged<double> onMinRatingChanged;
  final int topN;
  final ValueChanged<int> onTopNChanged;
  final String weather;
  final ValueChanged<String?> onWeatherChanged;
  final String visitDay;
  final ValueChanged<String?> onVisitDayChanged;
  final bool useBmkg;
  final ValueChanged<bool> onUseBmkgChanged;
  final bool isHighSeason;
  final ValueChanged<bool> onHighSeasonChanged;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(color: Color(0x140F172A), blurRadius: 18, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Travel Planner', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w900, fontSize: 12)),
          const SizedBox(height: 4),
          const Text('Mau liburan ke mana?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Isi parameter rekomendasi, lalu sistem akan menghitung ranking destinasi terbaik.', style: TextStyle(color: Colors.blueGrey)),
          const SizedBox(height: 18),
          const Text('Kategori Preferensi', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Alam', 'Budaya', 'Rekreasi', 'Umum'].map((category) {
              final selected = selectedCategories.contains(category);
              return ChoiceChip(
                selected: selected,
                label: Text(category),
                onSelected: (_) => onToggleCategory(category),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TourHubLocation>(
            value: selectedLocation,
            items: tourHubLocations
                .map((location) => DropdownMenuItem(
                      value: location,
                      child: Text(location.label, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: onLocationChanged,
            decoration: const InputDecoration(labelText: 'Lokasi Wisata'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: keywordController,
            decoration: const InputDecoration(labelText: 'Keywords', hintText: 'Contoh: pantai, sunset'),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _NumberBox(
                  label: 'Min Rating',
                  value: minRating.toStringAsFixed(1),
                  onMinus: () => onMinRatingChanged((minRating - 0.1).clamp(0.0, 5.0)),
                  onPlus: () => onMinRatingChanged((minRating + 0.1).clamp(0.0, 5.0)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NumberBox(
                  label: 'Top N',
                  value: topN.toString(),
                  onMinus: () => onTopNChanged((topN - 1).clamp(1, 50)),
                  onPlus: () => onTopNChanged((topN + 1).clamp(1, 50)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: weather,
                  items: ['cerah', 'hujan', 'mendung', 'berawan', 'unknown']
                      .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: onWeatherChanged,
                  decoration: const InputDecoration(labelText: 'Cuaca Manual'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: visitDay,
                  items: ['weekday', 'weekend']
                      .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: onVisitDayChanged,
                  decoration: const InputDecoration(labelText: 'Hari'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Gunakan BMKG', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: const Text('Prakiraan ±3 hari, interval sekitar 3 jam.'),
            value: useBmkg,
            onChanged: onUseBmkgChanged,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('High Season', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: const Text('Simulasi kondisi ramai wisatawan.'),
            value: isHighSeason,
            onChanged: onHighSeasonChanged,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onSubmit,
              icon: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.search),
              label: Text(isLoading ? 'Menghitung...' : 'Cari Rekomendasi Wisata'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberBox extends StatelessWidget {
  const _NumberBox({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

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
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w700)),
          Row(
            children: [
              IconButton(onPressed: onMinus, icon: const Icon(Icons.remove_circle_outline)),
              Expanded(
                child: Text(value, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              IconButton(onPressed: onPlus, icon: const Icon(Icons.add_circle_outline)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({
    required this.weatherUsed,
    required this.totalCandidates,
    required this.responseTimeMs,
  });

  final String weatherUsed;
  final String totalCandidates;
  final String responseTimeMs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Chip(label: Text('Cuaca: $weatherUsed')),
          Chip(label: Text('Candidates: $totalCandidates')),
          Chip(label: Text('Response: $responseTimeMs ms')),
        ],
      ),
    );
  }
}

class _RecommendationItemCard extends StatelessWidget {
  const _RecommendationItemCard({required this.rank, required this.item});

  final int rank;
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item['link_gambar']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: rank == 1 ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x120F172A), blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: imageUrl == null || imageUrl.isEmpty
                  ? const ColoredBox(
                      color: Color(0xFFE2E8F0),
                      child: Center(child: Text('No Image')),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFE2E8F0),
                        child: Center(child: Text('Gambar tidak bisa dimuat')),
                      ),
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
                    Chip(label: Text('#$rank')),
                    Chip(label: Text(item['kategori']?.toString() ?? '-')),
                    Chip(label: Text(item['tipe_wisata']?.toString() ?? '-')),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item['nama_tempat_wisata']?.toString() ?? '-',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['kecamatan'] ?? '-'} - ${item['kabupaten_kota'] ?? '-'}',
                  style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricChip(label: 'Rating', value: '${item['rating'] ?? '-'}'),
                    _MetricChip(label: 'Ulasan', value: '${item['jumlah_rating'] ?? '-'}'),
                    _MetricChip(label: 'CBF', value: '${item['cbf_score'] ?? '-'}'),
                    _MetricChip(label: 'Final', value: '${item['final_score'] ?? '-'}'),
                  ],
                ),
                if ((item['alasan'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    item['alasan'].toString(),
                    style: const TextStyle(height: 1.5, color: Colors.black87),
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

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _EmptyResultCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.explore_outlined, size: 42, color: Colors.blueGrey),
          SizedBox(height: 10),
          Text('Tidak ada rekomendasi', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          SizedBox(height: 6),
          Text('Coba turunkan min rating, pilih lokasi lain, atau pilih lebih banyak kategori.', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
