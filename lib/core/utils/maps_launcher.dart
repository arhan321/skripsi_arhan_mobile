import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openGoogleMapsUrl(BuildContext context, String? rawUrl) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final url = rawUrl?.trim() ?? '';

  if (url.isEmpty) {
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Link Google Maps belum tersedia untuk destinasi ini.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) {
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Format link Google Maps tidak valid.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  } catch (_) {
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Gagal membuka Google Maps.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
