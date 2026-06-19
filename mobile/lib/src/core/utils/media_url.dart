import 'package:flutter/foundation.dart';

/// Ensures media URLs load on Flutter Web (same-origin + relative /storage paths).
String resolveMediaUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;

  if (trimmed.startsWith('blob:') || trimmed.startsWith('data:')) {
    return trimmed;
  }

  if (!kIsWeb) return trimmed;

  if (trimmed.startsWith('/')) {
    return '${Uri.base.origin}$trimmed';
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) return trimmed;

  final host = uri.host.toLowerCase();
  if ((host == 'syaratiiq.com' || host == 'www.syaratiiq.com') &&
      uri.path.startsWith('/storage/')) {
    return '${Uri.base.origin}${uri.path}';
  }

  return trimmed;
}
