import 'package:flutter/material.dart';

import '../data/system_rating_api.dart';

/// Modal rating sistem TourHub untuk aplikasi mobile.
///
/// Cara pakai paling aman di halaman rekomendasi:
///
/// ```dart
/// await TourHubSystemRatingPrompt.maybeShow(
///   context: context,
///   recommendationResponse: responseMap,
/// );
/// ```
///
/// Modal hanya muncul jika:
/// - user login,
/// - rekomendasi berhasil menghasilkan data,
/// - backend belum mencatat rating sistem dari user tersebut.
final class TourHubSystemRatingPrompt {
  const TourHubSystemRatingPrompt._();

  static Future<bool> maybeShow({
    required BuildContext context,
    required Map<dynamic, dynamic> recommendationResponse,
  }) async {
    if (!context.mounted) {
      return false;
    }

    if (!_responseHasRecommendations(recommendationResponse)) {
      return false;
    }

    final requiresRating = _extractBool(recommendationResponse, const [
      'requires_system_rating',
      'data.requires_system_rating',
      'rating_prompt.show',
      'data.rating_prompt.show',
    ]);

    // Kalau backend eksplisit bilang tidak perlu rating, modal jangan tampil.
    if (requiresRating == false) {
      return false;
    }

    final status = await SystemRatingApi.fetchStatus();

    if (status.hasRating) {
      return false;
    }

    if (!context.mounted) {
      return false;
    }

    final recommendationLogId = _extractInt(recommendationResponse, const [
      'recommendation_log_id',
      'data.recommendation_log_id',
      'rating_prompt.recommendation_log_id',
      'data.rating_prompt.recommendation_log_id',
    ]);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SystemRatingPromptSheet(
          recommendationLogId: recommendationLogId,
        );
      },
    );

    return result == true;
  }

  static bool _responseHasRecommendations(Map<dynamic, dynamic> response) {
    final rootRecommendations = response['recommendations'];
    final data = response['data'];
    final dataRecommendations = data is Map ? data['recommendations'] : null;

    final recommendations = rootRecommendations is List
        ? rootRecommendations
        : dataRecommendations is List
        ? dataRecommendations
        : const [];

    return recommendations.isNotEmpty;
  }

  static bool? _extractBool(Map<dynamic, dynamic> source, List<String> paths) {
    for (final path in paths) {
      final value = _readPath(source, path);

      if (value is bool) {
        return value;
      }

      if (value is num) {
        return value != 0;
      }

      if (value is String) {
        final normalized = value.trim().toLowerCase();

        if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
          return true;
        }

        if (normalized == 'false' || normalized == '0' || normalized == 'no') {
          return false;
        }
      }
    }

    return null;
  }

  static int? _extractInt(Map<dynamic, dynamic> source, List<String> paths) {
    for (final path in paths) {
      final value = _readPath(source, path);

      if (value is int) {
        return value;
      }

      if (value is num) {
        return value.toInt();
      }

      if (value != null) {
        final parsed = int.tryParse(value.toString());

        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }

  static Object? _readPath(Map<dynamic, dynamic> source, String path) {
    Object? current = source;

    for (final key in path.split('.')) {
      if (current is Map) {
        current = current[key];
      } else {
        return null;
      }
    }

    return current;
  }
}

final class _SystemRatingPromptSheet extends StatefulWidget {
  const _SystemRatingPromptSheet({this.recommendationLogId});

  final int? recommendationLogId;

  @override
  State<_SystemRatingPromptSheet> createState() =>
      _SystemRatingPromptSheetState();
}

final class _SystemRatingPromptSheetState
    extends State<_SystemRatingPromptSheet> {
  final TextEditingController _commentController = TextEditingController();

  int _selectedRating = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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
        source: 'mobile_recommendation_page',
        platform: 'mobile',
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.46,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33020617),
                  blurRadius: 28,
                  offset: Offset(0, -10),
                ),
              ],
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _Header(
                  onClose: _isSubmitting
                      ? null
                      : () => Navigator.pop(context, false),
                ),
                const SizedBox(height: 20),
                _RatingSelector(
                  selectedRating: _selectedRating,
                  onChanged: (value) {
                    final safeValue = value.clamp(1, 5).toInt();
                    setState(() {
                      _selectedRating = safeValue;
                      _errorMessage = null;
                    });
                  },
                ),
                const SizedBox(height: 18),
                _LiveRatingInfo(rating: _selectedRating),
                const SizedBox(height: 18),
                TextField(
                  controller: _commentController,
                  minLines: 4,
                  maxLines: 5,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    labelText: 'Komentar tambahan',
                    hintText:
                        'Contoh: rekomendasinya sudah sesuai, tapi saya ingin pilihan yang lebih dekat dari lokasi saya.',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        child: const Text('Nanti saja'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _isSubmitting ? 'Mengirim...' : 'Kirim Rating',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF020617),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF94A3B8),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

final class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF020617), Color(0xFF172554), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'RATING SISTEM TOURHUB',
                  style: TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Bagaimana pengalaman rekomendasi TourHub?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Rating ini digunakan untuk menilai kualitas sistem rekomendasi, bukan rating destinasi wisata.',
                  style: TextStyle(
                    color: Color(0xFFE2E8F0),
                    height: 1.45,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            onPressed: onClose,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.12),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

final class _RatingSelector extends StatelessWidget {
  const _RatingSelector({
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seberapa membantu sistem rekomendasi ini?',
          style: TextStyle(
            color: Color(0xFF020617),
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
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
                            color: active
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFF8FAFC),
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
                                size: constraints.maxWidth < 340 ? 24 : 28,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$value/5',
                                style: TextStyle(
                                  color: active
                                      ? const Color(0xFF020617)
                                      : const Color(0xFF64748B),
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
        ),
      ],
    );
  }
}

final class _LiveRatingInfo extends StatelessWidget {
  const _LiveRatingInfo({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    final safeRating = rating.clamp(0, 5).toInt();
    final label = _ratingLabel(safeRating);
    final description = _ratingDescription(safeRating);
    final emoji = _ratingEmoji(safeRating);
    final progress = safeRating / 5.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF020617), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    height: 1.35,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 9,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
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
    2 => 'Hasil rekomendasi masih perlu banyak diperbaiki.',
    3 => 'Hasil rekomendasi cukup membantu, tetapi masih bisa ditingkatkan.',
    4 => 'Hasil rekomendasi sudah membantu memilih destinasi wisata.',
    5 => 'Hasil rekomendasi sangat membantu dan sesuai dengan preferensimu.',
    _ => 'Pilih bintang untuk memberikan penilaian kualitas sistem TourHub.',
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
