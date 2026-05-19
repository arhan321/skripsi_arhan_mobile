import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/maps_launcher.dart';
import '../../auth/data/auth_api.dart';
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
    await AuthApi.logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  Future<void> _submit() async {
    if (_selectedCategories.isEmpty) {
      _showSnack('Pilih minimal 1 kategori.');
      return;
    }

    FocusScope.of(context).unfocus();
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
      final message = e.toString().replaceFirst('Exception: ', '');
      if (message.toLowerCase().contains('login') ||
          message.toLowerCase().contains('token')) {
        await TokenStorage.clearToken();
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
        return;
      }

      if (!mounted) return;
      _showSnack(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _result?['data'];
    final dataMap = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    final recommendations = ((dataMap['recommendations'] ?? []) as List?) ?? [];
    final weatherUsed = dataMap['weather_used']?.toString() ?? '-';
    final totalCandidates = dataMap['total_candidates']?.toString() ?? '-';
    final responseTime = (_result?['response_time_ms'] ?? '-').toString();

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
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Riwayat',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.history),
            icon: const Icon(Icons.history_rounded),
          ),
          TextButton(onPressed: _logout, child: const Text('Logout')),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_result != null) await _submit();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _HeroCard(),
            const SizedBox(height: 14),
            _FormCard(
              selectedCategories: _selectedCategories,
              onToggleCategory: (category) {
                setState(() {
                  if (_selectedCategories.contains(category)) {
                    if (_selectedCategories.length > 1) {
                      _selectedCategories.remove(category);
                    }
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
              onHighSeasonChanged: (value) =>
                  setState(() => _isHighSeason = value),
              isLoading: _isLoading,
              onSubmit: _submit,
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              _ResultSummary(
                weatherUsed: weatherUsed,
                totalCandidates: totalCandidates,
                responseTimeMs: responseTime,
                totalOutput: recommendations.length,
              ),
              const SizedBox(height: 16),
              _SectionTitle(total: recommendations.length),
              const SizedBox(height: 12),
              if (recommendations.isEmpty)
                const _EmptyResultCard()
              else
                ...recommendations.asMap().entries.map((entry) {
                  final item = Map<String, dynamic>.from(entry.value as Map);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _RecommendationItemCard(
                      rank: entry.key + 1,
                      item: item,
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.history),
        icon: const Icon(Icons.history_rounded),
        label: const Text('Riwayat'),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF020617), Color(0xFF1E3A8A), Color(0xFF2563EB)],
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GlassBadge(text: 'Machine Learning Recommendation System'),
          SizedBox(height: 16),
          Text(
            'Pilihan utama untuk jelajahi Bali',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'CBF menghitung kecocokan preferensi, CARS menyesuaikan hasil berdasarkan cuaca, hari kunjungan, dan high season.',
            style: TextStyle(
              color: Color(0xFFE2E8F0),
              height: 1.5,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
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
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Travel Planner',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2563EB),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mau liburan ke mana?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF020617),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Isi parameter rekomendasi, lalu sistem akan menghitung ranking destinasi terbaik.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Kategori Preferensi',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ['Alam', 'Budaya', 'Rekreasi', 'Umum'].map((category) {
              final selected = selectedCategories.contains(category);
              return ChoiceChip(
                selected: selected,
                label: Text(category),
                onSelected: (_) => onToggleCategory(category),
                selectedColor: const Color(0xFFDBEAFE),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF93C5FD)
                      : const Color(0xFFE2E8F0),
                ),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: selected
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF334155),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TourHubLocation>(
            value: selectedLocation,
            isExpanded: true,
            decoration: _inputDecoration(label: 'Lokasi Wisata'),
            items: tourHubLocations
                .map(
                  (location) => DropdownMenuItem(
                    value: location,
                    child: Text(
                      location.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: onLocationChanged,
          ),
          const SizedBox(height: 8),
          const Text(
            'Lokasi sudah dipasangkan manual agar kecamatan sesuai kabupaten.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: keywordController,
            decoration: _inputDecoration(
              label: 'Keywords',
            ).copyWith(hintText: 'Contoh: pantai, sunset'),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StepperBox(
                  label: 'Min Rating',
                  value: minRating.toStringAsFixed(1),
                  onMinus: () => onMinRatingChanged(
                    ((minRating - 0.1).clamp(0.0, 5.0)).toDouble(),
                  ),
                  onPlus: () => onMinRatingChanged(
                    ((minRating + 0.1).clamp(0.0, 5.0)).toDouble(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StepperBox(
                  label: 'Top N',
                  value: topN.toString(),
                  onMinus: () =>
                      onTopNChanged(((topN - 1).clamp(1, 50)).toInt()),
                  onPlus: () =>
                      onTopNChanged(((topN + 1).clamp(1, 50)).toInt()),
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
                  decoration: _inputDecoration(label: 'Cuaca Manual'),
                  items:
                      const ['cerah', 'hujan', 'mendung', 'berawan', 'unknown']
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                  onChanged: onWeatherChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: visitDay,
                  decoration: _inputDecoration(label: 'Hari'),
                  items: const ['weekday', 'weekend']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: onVisitDayChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SwitchRow(
            title: 'Gunakan BMKG',
            subtitle: 'Prakiraan ±3 hari, interval sekitar 3 jam.',
            value: useBmkg,
            onChanged: onUseBmkgChanged,
          ),
          _SwitchRow(
            title: 'High Season',
            subtitle: 'Simulasi kondisi ramai wisatawan.',
            value: isHighSeason,
            onChanged: onHighSeasonChanged,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onSubmit,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(
                isLoading ? 'Menghitung...' : 'Cari Rekomendasi Wisata',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5267A5),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String label}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }
}

class _StepperBox extends StatelessWidget {
  const _StepperBox({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              InkWell(
                onTap: onMinus,
                child: const Icon(Icons.remove_circle_outline_rounded),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
              InkWell(
                onTap: onPlus,
                child: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF020617),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({
    required this.weatherUsed,
    required this.totalCandidates,
    required this.responseTimeMs,
    required this.totalOutput,
  });

  final String weatherUsed;
  final String totalCandidates;
  final String responseTimeMs;
  final int totalOutput;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _SummaryPill(label: 'Cuaca', value: weatherUsed),
          _SummaryPill(label: 'Candidates', value: totalCandidates),
          _SummaryPill(label: 'Output', value: totalOutput.toString()),
          _SummaryPill(label: 'Response', value: '$responseTimeMs ms'),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Color(0xFF334155),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.total});

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
                'Semua Kandidat Rekomendasi',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              Text(
                'Diurutkan dari final score tertinggi.',
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
            'Total $total',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ],
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
    final mapsUrl = item['link_google_maps']?.toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: rank == 1 ? const Color(0xFFFACC15) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: SizedBox(
              height: 230,
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
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: rank == 1
                            ? const Color(0xFFFACC15)
                            : const Color(0xFF020617),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '#$rank',
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
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (item['nama_tempat_wisata'] ?? '-').toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  height: 1.08,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${item['kecamatan'] ?? '-'} - ${item['kabupaten_kota'] ?? '-'}',
                                style: const TextStyle(
                                  color: Color(0xFFE2E8F0),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
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
                                'Score',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                (item['final_score'] ?? '-').toString(),
                                style: const TextStyle(
                                  color: Color(0xFF020617),
                                  fontSize: 18,
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
                    if (rank == 1)
                      const _GoldBadge(text: '🏆 Paling Direkomendasikan'),
                    _BlueBadge(text: (item['kategori'] ?? '-').toString()),
                    _GrayBadge(text: (item['tipe_wisata'] ?? '-').toString()),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MetricBox(
                        label: 'Rating',
                        value: (item['rating'] ?? '-').toString(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricBox(
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
                      child: _MetricBox(
                        label: 'CBF',
                        value: (item['cbf_score'] ?? '-').toString(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricBox(
                        label: 'Context',
                        value: (item['context_multiplier'] ?? '-').toString(),
                      ),
                    ),
                  ],
                ),
                if ((item['alasan'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      (item['alasan'] ?? '').toString(),
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        height: 1.5,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (mapsUrl != null && mapsUrl.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
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

class _MetricBox extends StatelessWidget {
  const _MetricBox({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
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
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF020617),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
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

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();
  @override
  Widget build(BuildContext context) => Container(
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

class _EmptyResultCard extends StatelessWidget {
  const _EmptyResultCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: const Text(
      'Tidak ada rekomendasi. Coba turunkan min rating atau pilih kategori lain.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
    ),
  );
}
