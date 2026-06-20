import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../auth/data/auth_api.dart';
import '../../recommendation/data/recommendation_history_api.dart';
import '../../recommendation/data/recommendation_history_model.dart';
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

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  _DashboardData? _data;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadInitialDashboard();
  }

  Future<_DashboardData> _fetchDashboardData() async {
    final user = await AuthApi.me();
    final histories = await RecommendationHistoryApi.fetchHistories();

    histories.sort((a, b) {
      final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });

    return _DashboardData(user: user, histories: histories);
  }

  Future<void> _loadInitialDashboard() async {
    if (!mounted) return;

    setState(() {
      _isLoading = _data == null;
      _errorMessage = null;
    });

    try {
      final result = await _fetchDashboardData();

      if (!mounted) return;

      setState(() {
        _data = result;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().replaceFirst('Exception: ', '');

      setState(() => _errorMessage = message);
      _handleAuthError(message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshDashboard() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      final result = await _fetchDashboardData();

      if (!mounted) return;

      setState(() {
        _data = result;
        _errorMessage = null;
      });

      _showSnack('Beranda berhasil diperbarui.');
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().replaceFirst('Exception: ', '');

      if (_data == null) {
        setState(() => _errorMessage = message);
      }

      _showSnack(message);
      _handleAuthError(message);
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _handleAuthError(String message) {
    final lowered = message.toLowerCase();

    if (lowered.contains('login') ||
        lowered.contains('token') ||
        lowered.contains('sesi')) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    }
  }

  Future<void> _logout() async {
    await AuthApi.logout();

    if (!mounted) return;

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  void _openDetail(RecommendationHistoryItem item) {
    Navigator.pushNamed(context, AppRoutes.historyDetail, arguments: item.id);
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final latest = data?.latestHistory;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FB),
      drawer: TourHubSidebar(activeMenu: TourHubSidebarMenu.dashboard),
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
        title: InkWell(
          onTap: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.landing,
            (_) => false,
          ),
          borderRadius: BorderRadius.circular(14),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TourHub Bali',
                  style: TextStyle(
                    color: Color(0xFF020617),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Beranda Akun',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: const [SizedBox(width: 12)],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        triggerMode: RefreshIndicatorTriggerMode.onEdge,
        displacement: 42,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(18),
          children: [
            if (_isLoading && data == null) ...[
              const SizedBox(height: 180),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Memuat beranda akun...',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ] else if (_errorMessage != null && data == null) ...[
              const SizedBox(height: 40),
              _ErrorDashboard(
                message: _errorMessage!,
                onRetry: _loadInitialDashboard,
              ),
            ] else ...[
              if (_isRefreshing)
                const _RefreshingBanner()
              else
                const SizedBox.shrink(),
              _HeroDashboardCard(
                userName: data?.userName ?? 'Wisatawan',
                totalSearch: data?.total ?? 0,
              ),
              const SizedBox(height: 16),
              _StatsGrid(
                data: data ?? const _DashboardData(user: null, histories: []),
              ),
              const SizedBox(height: 16),
              if (latest != null)
                _LatestRecommendationCard(
                  item: latest,
                  onDetail: () => _openDetail(latest),
                )
              else
                const _NoLatestCard(),
              const SizedBox(height: 16),
              const _TipsCard(),
              const SizedBox(height: 16),
              _HistoryPreviewSection(
                histories: (data?.histories ?? const []).take(5).toList(),
                onOpenDetail: _openDetail,
              ),
              const SizedBox(height: 82),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.recommendation),
        icon: const Icon(Icons.search_rounded),
        label: const Text(
          'Cari Wisata Baru',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _RefreshingBanner extends StatelessWidget {
  const _RefreshingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        children: [
          SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Memperbarui beranda...',
              style: TextStyle(
                color: Color(0xFF1D4ED8),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({required this.user, required this.histories});

  final dynamic user;
  final List<RecommendationHistoryItem> histories;

  int get total => histories.length;

  int get successCount => histories.where((item) => item.isSuccess).length;

  int get failedCount => total - successCount;

  int get successRate {
    if (total == 0) return 0;
    return ((successCount / total) * 100).round();
  }

  String get userName {
    final name = user?.name?.toString().trim();
    if (name != null && name.isNotEmpty) return name;

    final email = user?.email?.toString().trim();
    if (email != null && email.isNotEmpty) return email.split('@').first;

    return 'Wisatawan';
  }

  RecommendationHistoryItem? get latestHistory {
    if (histories.isEmpty) return null;
    return histories.first;
  }
}

class _HeroDashboardCard extends StatelessWidget {
  const _HeroDashboardCard({required this.userName, required this.totalSearch});

  final String userName;
  final int totalSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF020617), Color(0xFF172554), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -34,
            child: Container(
              width: 126,
              height: 126,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _GlassBadge(text: 'Beranda TourHub Bali'),
              const SizedBox(height: 16),
              Text(
                'Halo, $userName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Di sini kamu bisa melihat rekomendasi terakhir, tips pencarian, dan riwayat wisata yang pernah kamu cari.',
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  height: 1.5,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const _HeroChip(text: 'Rekomendasi Pintar'),
                  const _HeroChip(text: 'Cuaca Otomatis'),
                  _HeroChip(text: '$totalSearch Pencarian'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.08,
      children: [
        _StatCard(
          label: 'Total Pencarian',
          value: data.total.toString(),
          subtitle: 'Jumlah pencarian wisata kamu.',
          icon: Icons.push_pin_rounded,
          color: const Color(0xFF2563EB),
        ),
        _StatCard(
          label: 'Berhasil',
          value: data.successCount.toString(),
          subtitle: 'Pencarian yang menemukan hasil.',
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF059669),
        ),
        _StatCard(
          label: 'Belum Berhasil',
          value: data.failedCount.toString(),
          subtitle: 'Pencarian yang perlu dicoba ulang.',
          icon: Icons.warning_rounded,
          color: const Color(0xFFF59E0B),
        ),
        _StatCard(
          label: 'Hasil Tersedia',
          value: '${data.successRate}%',
          subtitle: 'Pencarian yang berhasil memberi pilihan.',
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF1D4ED8),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.11),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  softWrap: true,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const Spacer(),
                Text(
                  subtitle,
                  softWrap: true,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    height: 1.28,
                    fontWeight: FontWeight.w600,
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

class _LatestRecommendationCard extends StatelessWidget {
  const _LatestRecommendationCard({required this.item, required this.onDetail});

  final RecommendationHistoryItem item;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final top = item.topRecommendation;
    final imageUrl = top?['link_gambar']?.toString();
    final destinationName = item.topDestinationName;
    final weather = _formatWeather(item.weatherUsed);
    final choices = item.totalCandidates?.toString() ?? '-';
    final category = item.categoriesLabel;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
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
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: SizedBox(
              height: 180,
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
                        colors: [Colors.transparent, Color(0xDD020617)],
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
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rekomendasi Terakhir',
                                style: TextStyle(
                                  color: Color(0xFFBFDBFE),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                destinationName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  height: 1.08,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: onDetail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF020617),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Detail',
                            style: TextStyle(fontWeight: FontWeight.w900),
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
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SmallInfoBox(
                        label: 'Lokasi',
                        value: item.locationLabel,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SmallInfoBox(label: 'Cuaca', value: weather),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SmallInfoBox(label: 'Pilihan', value: choices),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Pill(
                      text: _friendlyStatus(item.isSuccess),
                      color: item.isSuccess
                          ? const Color(0xFF059669)
                          : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Pill(
                        text: category,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    'Info cuaca: $weather • pencarian pada ${item.displayDate}',
                    style: const TextStyle(
                      color: Color(0xFF047857),
                      height: 1.35,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
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

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    final tips = [
      'Gunakan kata kunci sederhana, misalnya pantai atau sunset.',
      'Coba pilih lebih dari satu kategori wisata.',
      'Turunkan rating minimal jika hasil terlalu sedikit.',
      'Pilih lokasi populer seperti Gianyar, Badung, atau Denpasar.',
    ];

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
            'Tips Pencarian',
            style: TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Agar rekomendasi lebih sesuai',
            style: TextStyle(
              color: Color(0xFF020617),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...tips.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key + 1}.',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HistoryPreviewSection extends StatelessWidget {
  const _HistoryPreviewSection({
    required this.histories,
    required this.onOpenDetail,
  });

  final List<RecommendationHistoryItem> histories;
  final ValueChanged<RecommendationHistoryItem> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Pencarian Saya',
                      style: TextStyle(
                        color: Color(0xFF020617),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Destinasi yang pernah kamu cari akan muncul di sini.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.history),
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (histories.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Belum ada riwayat.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ...histories.map((item) {
              return _HistoryRow(item: item, onTap: () => onOpenDetail(item));
            }),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item, required this.onTap});

  final RecommendationHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final topName = item.topDestinationName;
    final statusColor = item.isSuccess
        ? const Color(0xFF059669)
        : const Color(0xFFF59E0B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  item.isSuccess
                      ? Icons.check_circle_rounded
                      : Icons.info_rounded,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF020617),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_formatWeather(item.weatherUsed)} • ${item.displayDate}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoLatestCard extends StatelessWidget {
  const _NoLatestCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.travel_explore_rounded,
            color: Color(0xFF2563EB),
            size: 42,
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada rekomendasi terakhir',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF020617),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mulai cari rekomendasi wisata agar dashboard kamu terisi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.recommendation),
            icon: const Icon(Icons.search_rounded),
            label: const Text('Cari Rekomendasi'),
          ),
        ],
      ),
    );
  }
}

class _SmallInfoBox extends StatelessWidget {
  const _SmallInfoBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.all(10),
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
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF020617),
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w900,
              ),
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
      constraints: const BoxConstraints(maxWidth: 180),
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
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 11,
          fontWeight: FontWeight.w800,
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

class _LoadingDashboard extends StatelessWidget {
  const _LoadingDashboard();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: const [
        SizedBox(height: 180),
        Center(child: CircularProgressIndicator()),
        SizedBox(height: 16),
        Center(
          child: Text(
            'Memuat dashboard...',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorDashboard extends StatelessWidget {
  const _ErrorDashboard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final isAuthError =
        message.toLowerCase().contains('login') ||
        message.toLowerCase().contains('token') ||
        message.toLowerCase().contains('sesi');

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
          if (isAuthError)
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (_) => false,
              ),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Login Ulang'),
            )
          else
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
