import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/utils/maps_launcher.dart';
import '../../../shared/widgets/tourhub_sidebar.dart';
import '../data/wishlist_api.dart';
import '../data/wishlist_item.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  bool _isLoading = true;
  bool _isDeleting = false;
  String? _errorMessage;
  List<WishlistItem> _wishlists = const [];

  @override
  void initState() {
    super.initState();
    _loadWishlists();
  }

  Future<void> _loadWishlists() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await WishlistApi.fetchWishlists(forceRefresh: true);

      if (!mounted) return;

      setState(() {
        _wishlists = data;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteWishlist(WishlistItem item) async {
    if (_isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Wishlist?'),
          content: Text(
            'Destinasi "${item.destinationName}" akan dihapus dari wishlist.',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await WishlistApi.deleteWishlist(item.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.destinationName} dihapus dari wishlist.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );

      await _loadWishlists();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const TourHubSidebar(activeMenu: TourHubSidebarMenu.wishlist),
      backgroundColor: const Color(0xFFF3F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              tooltip: 'Menu',
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded),
            );
          },
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wishlist Saya',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF020617),
              ),
            ),
            Text(
              'Destinasi wisata tersimpan',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Rekomendasi',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.recommendation),
            icon: const Icon(Icons.explore_rounded),
          ),
          IconButton(
            tooltip: 'Riwayat',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.history),
            icon: const Icon(Icons.history_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(onRefresh: _loadWishlists, child: _buildBody()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.recommendation),
        icon: const Icon(Icons.search_rounded),
        label: const Text('Cari Wisata'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _ErrorCard(message: _errorMessage!, onRetry: _loadWishlists),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        _HeroCard(total: _wishlists.length),
        const SizedBox(height: 16),
        if (_wishlists.isEmpty)
          const _EmptyWishlistCard()
        else
          ..._wishlists.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _WishlistDestinationCard(
                item: item,
                isDeleting: _isDeleting,
                onDelete: () => _deleteWishlist(item),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.total});

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SmallBadge(text: '★ Destinasi Tersimpan'),
                const SizedBox(height: 16),
                const Text(
                  'Wishlist TourHub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Kamu punya $total destinasi wisata yang disimpan.',
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            alignment: Alignment.center,
            child: Text(
              total.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WishlistDestinationCard extends StatelessWidget {
  const _WishlistDestinationCard({
    required this.item,
    required this.isDeleting,
    required this.onDelete,
  });

  final WishlistItem item;
  final bool isDeleting;
  final VoidCallback onDelete;

  String _formatTourismType(String? value) {
    final text = (value ?? '').trim().toLowerCase();

    if (text.isEmpty) return '-';

    switch (text) {
      case 'outdoor':
        return 'Luar Ruangan';
      case 'indoor':
        return 'Dalam Ruangan';
      case 'mixed':
        return 'Campuran';
      default:
        return value ?? '-';
    }
  }

  String _cleanReason(String? value) {
    var text = (value ?? '').trim();

    if (text.isEmpty) {
      return '';
    }

    text = text.replaceAll(
      RegExp(r'\(\s*CBF\s*=\s*[\d.,]+\s*\)', caseSensitive: false),
      '',
    );

    text = text.replaceAll(
      RegExp(r'\bCBF\s*[:=]\s*[\d.,]+;?\s*', caseSensitive: false),
      '',
    );

    text = text.replaceAll(
      RegExp(r'\bCARS\s*[:=]\s*[\d.,]+;?\s*', caseSensitive: false),
      '',
    );

    text = text.replaceAll(
      RegExp(
        r'\bfinal[_\s-]*score\s*[:=]\s*[\d.,]+;?\s*',
        caseSensitive: false,
      ),
      '',
    );

    text = text.replaceAll(
      RegExp(r'\bbase[_\s-]*score\s*[:=]\s*[\d.,]+;?\s*', caseSensitive: false),
      '',
    );

    text = text.replaceAll(
      RegExp(
        r'\bcontext[_\s-]*multiplier\s*[:=]\s*[\d.,]+;?\s*',
        caseSensitive: false,
      ),
      '',
    );

    text = text.replaceAll(
      RegExp(
        r'\brating[_\s-]*score\s*[:=]\s*[\d.,]+;?\s*',
        caseSensitive: false,
      ),
      '',
    );

    text = text.replaceAll(
      RegExp(
        r'\bpopularity[_\s-]*score\s*[:=]\s*[\d.,]+;?\s*',
        caseSensitive: false,
      ),
      '',
    );

    text = text.replaceAll(
      RegExp(r'\bfitur/preferensi user\b', caseSensitive: false),
      'pilihan wisatamu',
    );

    text = text.replaceAll(
      RegExp(r'\bpreferensi user\b', caseSensitive: false),
      'pilihan wisatamu',
    );

    text = text.replaceAll(RegExp(r'\buser\b', caseSensitive: false), 'kamu');

    text = text.replaceAll(
      RegExp(r'\boutdoor\b', caseSensitive: false),
      'luar ruangan',
    );

    text = text.replaceAll(
      RegExp(r'\bindoor\b', caseSensitive: false),
      'dalam ruangan',
    );

    text = text.replaceAll(
      RegExp(r'\bmixed\b', caseSensitive: false),
      'campuran',
    );

    text = text.replaceAll(
      RegExp(
        r'\bcuaca cerah mendukung destinasi luar ruangan\b',
        caseSensitive: false,
      ),
      'cuaca cerah cocok untuk destinasi luar ruangan',
    );

    text = text.replaceAll(
      RegExp(
        r'\bcuaca hujan kurang mendukung destinasi luar ruangan\b',
        caseSensitive: false,
      ),
      'cuaca hujan kurang cocok untuk destinasi luar ruangan',
    );

    text = text.replaceAll(RegExp(r'\s+;'), ';');
    text = text.replaceAll(RegExp(r';\s*;'), ';');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (text.startsWith(';')) {
      text = text.substring(1).trim();
    }

    if (text.endsWith(';')) {
      text = text.substring(0, text.length - 1).trim();
    }

    if (text.isEmpty) {
      return 'Destinasi ini sesuai dengan pilihan wisatamu.';
    }

    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl;
    final displayReason = _cleanReason(item.reason);

    return Container(
      clipBehavior: Clip.antiAlias,
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
        children: [
          SizedBox(
            height: 188,
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
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      '★ Tersimpan',
                      style: TextStyle(
                        color: Color(0xFF020617),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.destinationName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.locationLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _Chip(label: item.category ?? '-'),
                    const SizedBox(width: 8),
                    _Chip(label: _formatTourismType(item.tourismType)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _InfoBox(label: 'Rating', value: item.ratingLabel),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoBox(label: 'Ulasan', value: item.reviewLabel),
                    ),
                  ],
                ),
                if (displayReason.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Text(
                      displayReason,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            openGoogleMapsUrl(context, item.googleMapsUrl),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.location_on_rounded),
                        label: const Text(
                          'Maps',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isDeleting ? null : onDelete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text(
                          'Hapus',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Disimpan: ${item.createdAtLabel}',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

class _EmptyWishlistCard extends StatelessWidget {
  const _EmptyWishlistCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.star_border_rounded,
            size: 64,
            color: Color(0xFFF59E0B),
          ),
          const SizedBox(height: 14),
          const Text(
            'Wishlist masih kosong',
            style: TextStyle(
              color: Color(0xFF020617),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tambahkan destinasi dari hasil rekomendasi atau detail riwayat.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
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

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gagal memuat wishlist',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF991B1B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF7F1D1D),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.label, required this.value});

  final String label;
  final String value;

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
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF020617),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFDBEAFE),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF1D4ED8),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFE0F2FE),
          fontSize: 12,
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
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_rounded,
        size: 46,
        color: Color(0xFF94A3B8),
      ),
    );
  }
}
