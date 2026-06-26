import 'package:flutter/material.dart';

import '../data/wishlist_api.dart';

class WishlistToggleButton extends StatefulWidget {
  const WishlistToggleButton({
    super.key,
    required this.destination,
    this.recommendationLogId,
    this.compact = false,
    this.onChanged,
  });

  final Map<String, dynamic> destination;
  final int? recommendationLogId;
  final bool compact;
  final ValueChanged<bool>? onChanged;

  @override
  State<WishlistToggleButton> createState() => _WishlistToggleButtonState();
}

class _WishlistToggleButtonState extends State<WishlistToggleButton> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isWished = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void didUpdateWidget(covariant WishlistToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.destination.toString() != widget.destination.toString()) {
      _loadState();
    }
  }

  Future<void> _loadState() async {
    setState(() => _isLoading = true);

    try {
      final wished = await WishlistApi.isDestinationWished(widget.destination);

      if (!mounted) return;

      setState(() {
        _isWished = wished;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggle() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final wished = await WishlistApi.toggleWishlist(
        destination: widget.destination,
        recommendationLogId: widget.recommendationLogId,
      );

      if (!mounted) return;

      setState(() => _isWished = wished);
      widget.onChanged?.call(wished);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wished
                ? 'Destinasi berhasil ditambahkan ke wishlist.'
                : 'Destinasi berhasil dihapus dari wishlist.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isLoading || _isSubmitting;

    final backgroundColor = _isWished
        ? const Color(0xFFFBBF24)
        : const Color(0xFFFFFFFF);

    final foregroundColor = _isWished
        ? const Color(0xFF020617)
        : const Color(0xFF334155);

    return SizedBox(
      height: widget.compact ? 42 : 48,
      child: FilledButton.icon(
        onPressed: isBusy ? null : _toggle,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          foregroundColor: foregroundColor,
          disabledForegroundColor: const Color(0xFF64748B),
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 14 : 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: _isWished ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
            ),
          ),
        ),
        icon: isBusy
            ? SizedBox(
                width: widget.compact ? 14 : 16,
                height: widget.compact ? 14 : 16,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                _isWished ? Icons.star_rounded : Icons.star_border_rounded,
                size: widget.compact ? 18 : 20,
              ),
        label: Text(
          _isWished ? 'Tersimpan' : 'Wishlist',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: widget.compact ? 12 : 13,
          ),
        ),
      ),
    );
  }
}
