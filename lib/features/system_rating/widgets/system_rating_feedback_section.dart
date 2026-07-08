import 'package:flutter/material.dart';

import '../data/system_rating_api.dart';

enum SystemRatingSectionMode {
  /// Tampilkan form rating kalau user belum pernah rating.
  /// Kalau user sudah rating, section otomatis tidak tampil.
  promptOnly,

  /// Tampilkan ucapan terima kasih kalau user sudah rating.
  /// Kalau user belum rating, section otomatis tidak tampil.
  thankYouOnly,

  /// Tampilkan form kalau belum rating, atau ucapan terima kasih kalau sudah rating.
  auto,
}

/// Section rating sistem TourHub untuk dashboard, history, dan detail history.
///
/// Konsep final mengikuti website:
/// - Rating ini untuk kualitas sistem TourHub, bukan rating destinasi wisata.
/// - Satu user cukup memberi rating satu kali.
/// - recommendationLogId hanya disimpan sebagai konteks saat user pertama kali rating.
final class TourHubSystemRatingSection extends StatefulWidget {
  const TourHubSystemRatingSection({
    super.key,
    this.recommendationLogId,
    this.source = 'mobile_page',
    this.mode = SystemRatingSectionMode.auto,
    this.compact = false,
    this.onChanged,
  });

  final int? recommendationLogId;
  final String source;
  final SystemRatingSectionMode mode;
  final bool compact;
  final VoidCallback? onChanged;

  @override
  State<TourHubSystemRatingSection> createState() =>
      _TourHubSystemRatingSectionState();
}

final class _TourHubSystemRatingSectionState
    extends State<TourHubSystemRatingSection> {
  final TextEditingController _commentController = TextEditingController();

  late Future<SystemRatingStatus> _future;
  int _selectedRating = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _future = SystemRatingApi.fetchStatus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _future = SystemRatingApi.fetchStatus();
    });
  }

  Future<void> _submitRating() async {
    if (_selectedRating < 1 || _selectedRating > 5) {
      setState(() {
        _errorMessage = 'Pilih rating 1 sampai 5 terlebih dahulu.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await SystemRatingApi.submitRating(
        rating: _selectedRating,
        comment: _commentController.text,
        recommendationLogId: widget.recommendationLogId,
        source: widget.source,
        platform: 'mobile',
      );

      if (!mounted) {
        return;
      }

      widget.onChanged?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Terima kasih, rating sistem berhasil dikirim.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );

      _commentController.clear();
      _selectedRating = 0;
      await _reload();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SystemRatingStatus>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.mode == SystemRatingSectionMode.thankYouOnly
              ? const SizedBox.shrink()
              : _LoadingRatingCard(compact: widget.compact);
        }

        if (snapshot.hasError) {
          // Section rating tidak boleh membuat halaman utama gagal dipakai.
          return const SizedBox.shrink();
        }

        final status = snapshot.data;
        final hasRating = status?.hasRating == true;

        if (widget.mode == SystemRatingSectionMode.promptOnly && hasRating) {
          return const SizedBox.shrink();
        }

        if (widget.mode == SystemRatingSectionMode.thankYouOnly && !hasRating) {
          return const SizedBox.shrink();
        }

        if (hasRating) {
          return _ThankYouRatingCard(status: status!, compact: widget.compact);
        }

        return _PromptRatingCard(
          selectedRating: _selectedRating,
          isSubmitting: _isSubmitting,
          errorMessage: _errorMessage,
          commentController: _commentController,
          compact: widget.compact,
          onRatingChanged: (value) {
            final safeValue = value.clamp(1, 5).toInt();
            setState(() {
              _selectedRating = safeValue;
              _errorMessage = null;
            });
          },
          onSubmit: _submitRating,
        );
      },
    );
  }
}

final class _LoadingRatingCard extends StatelessWidget {
  const _LoadingRatingCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 24 : 30),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Memeriksa status rating sistem...',
                  style: TextStyle(
                    color: Color(0xFF020617),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'TourHub sedang mengecek apakah kamu sudah pernah memberi rating.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    height: 1.35,
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

final class _PromptRatingCard extends StatelessWidget {
  const _PromptRatingCard({
    required this.selectedRating,
    required this.isSubmitting,
    required this.errorMessage,
    required this.commentController,
    required this.compact,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  final int selectedRating;
  final bool isSubmitting;
  final String? errorMessage;
  final TextEditingController commentController;
  final bool compact;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 24 : 30),
        border: Border.all(color: const Color(0xFFFDE68A)),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFFFFFF), Color(0xFFEFF6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Icon(Icons.star_rounded, color: Color(0xFFD97706)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Rating Sistem TourHub',
                      style: TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 12,
                        letterSpacing: 0.4,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Bantu nilai sistem rekomendasi TourHub',
                      style: TextStyle(
                        color: Color(0xFF020617),
                        fontSize: 20,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Rating ini cukup diberikan satu kali untuk menilai kualitas sistem, bukan untuk menilai tempat wisata.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InlineStarPicker(
            selectedRating: selectedRating,
            onChanged: onRatingChanged,
          ),
          const SizedBox(height: 14),
          _LiveRatingCaption(rating: selectedRating),
          const SizedBox(height: 14),
          TextField(
            controller: commentController,
            minLines: 3,
            maxLines: 4,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: 'Komentar tambahan',
              hintText:
                  'Contoh: rekomendasinya sudah sesuai dan mudah digunakan.',
              alignLabelWithHint: true,
              filled: true,
              fillColor: Colors.white,
              counterStyle: const TextStyle(fontSize: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.4,
                ),
              ),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(isSubmitting ? 'Mengirim...' : 'Kirim Rating Sistem'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF020617),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _ThankYouRatingCard extends StatelessWidget {
  const _ThankYouRatingCard({required this.status, required this.compact});

  final SystemRatingStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rating = status.rating ?? 0;
    final comment = status.comment?.trim();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 24 : 30),
        border: Border.all(color: const Color(0xFFA7F3D0)),
        gradient: const LinearGradient(
          colors: [Color(0xFFECFDF5), Color(0xFFFFFFFF), Color(0xFFFFFBEB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Terima kasih sudah menilai sistem TourHub',
                      style: TextStyle(
                        color: Color(0xFF020617),
                        fontSize: 20,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Rating kamu sudah tersimpan sebagai penilaian kualitas sistem rekomendasi secara keseluruhan. Form rating tidak akan muncul lagi.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (status.ratedAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Diberikan pada ${status.ratedAt}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Column(
                  children: [
                    Text(
                      rating > 0 ? '$rating/5' : '-',
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _ratingLabel(rating),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF047857),
                        fontSize: 10,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.82),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Komentar kamu',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      letterSpacing: 0.3,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '“$comment”',
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

final class _InlineStarPicker extends StatelessWidget {
  const _InlineStarPicker({
    required this.selectedRating,
    required this.onChanged,
  });

  final int selectedRating;
  final ValueChanged<int> onChanged;

  int get _safeSelectedRating => selectedRating.clamp(0, 5).toInt();

  void _safeChange(int value) {
    final safeValue = value.clamp(1, 5).toInt();
    onChanged(safeValue);
  }

  @override
  Widget build(BuildContext context) {
    final safeRating = _safeSelectedRating;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemGap = constraints.maxWidth < 340 ? 5.0 : 7.0;
        final itemHeight = constraints.maxWidth < 340 ? 62.0 : 68.0;

        return Row(
          children: List.generate(5, (index) {
            final value = index + 1;
            final active = safeRating >= value;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: value == 5 ? 0 : itemGap),
                child: Semantics(
                  button: true,
                  selected: active,
                  label: 'Rating $value dari 5',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _safeChange(value),
                    child: Container(
                      height: itemHeight,
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFFFBBF24) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: active
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFE2E8F0),
                          width: active ? 1.4 : 1,
                        ),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFF59E0B,
                                  ).withOpacity(0.14),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : const [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            active
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: active
                                ? const Color(0xFF020617)
                                : const Color(0xFF94A3B8),
                            size: constraints.maxWidth < 340 ? 24 : 26,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$value/5',
                            style: TextStyle(
                              color: active
                                  ? const Color(0xFF020617)
                                  : const Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

final class _LiveRatingCaption extends StatelessWidget {
  const _LiveRatingCaption({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    final safeRating = rating.clamp(0, 5).toInt();
    final label = _ratingLabel(safeRating);
    final description = _ratingDescription(safeRating);
    final progress = safeRating / 5.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                _ratingEmoji(safeRating),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  height: 8,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
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

String _ratingLabel(int rating) {
  return switch (rating) {
    1 => 'Kurang membantu',
    2 => 'Cukup kurang',
    3 => 'Cukup membantu',
    4 => 'Membantu',
    5 => 'Sangat membantu',
    _ => 'Belum diberi rating',
  };
}

String _ratingDescription(int rating) {
  return switch (rating) {
    1 => 'Hasil rekomendasi belum sesuai dengan kebutuhanmu.',
    2 => 'Sistem masih perlu banyak perbaikan.',
    3 => 'Sistem cukup membantu, tetapi masih bisa ditingkatkan.',
    4 => 'Sistem sudah membantu memilih destinasi wisata.',
    5 => 'Sistem sangat membantu dan sesuai dengan rencana wisata.',
    _ => 'Pilih bintang untuk menilai sistem rekomendasi TourHub.',
  };
}

String _ratingEmoji(int rating) {
  return switch (rating) {
    1 => '😕',
    2 => '🙂',
    3 => '😊',
    4 => '🤩',
    5 => '🏆',
    _ => '⭐',
  };
}
