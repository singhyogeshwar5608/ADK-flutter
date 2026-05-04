import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Default when `.env` is missing or `API_BASE_URL` is unset.
const String kDefaultApiV1Base = 'https://www.offerlifetime.com/api/v1';

String _trimmedApiV1Base(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return kDefaultApiV1Base;
  return t.endsWith('/') ? t.substring(0, t.length - 1) : t;
}

/// Resolves `API_BASE_URL` (e.g. `https://host/api/v1`) for building media URLs.
String effectiveApiV1Base({String? override}) {
  if (override != null && override.trim().isNotEmpty) {
    return _trimmedApiV1Base(override);
  }
  final fromEnv = dotenv.env['API_BASE_URL']?.trim();
  if (fromEnv != null && fromEnv.isNotEmpty) {
    return _trimmedApiV1Base(fromEnv);
  }
  return kDefaultApiV1Base;
}

bool _isApiV1MediaUrl(String s) {
  return s.toLowerCase().contains('/api/v1/media/');
}

/// Rewrites Laravel web route `/storage-proxy/...` to `/api/v1/media/...`
/// ([MediaProxyController]) so clients receive image bytes + CORS instead of HTML SPA fallback.
String normalizeMediaUrl(String raw, {String? apiBaseUrl}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;

  if (_isApiV1MediaUrl(trimmed)) {
    return trimmed;
  }

  final lower = trimmed.toLowerCase();
  final marker = '/storage-proxy/';
  final idx = lower.indexOf(marker);
  if (idx < 0) {
    return trimmed;
  }

  final rest = trimmed.substring(idx + marker.length).replaceFirst(RegExp(r'^/+'), '');
  if (rest.isEmpty) {
    return trimmed;
  }

  final base = effectiveApiV1Base(override: apiBaseUrl);
  return '$base/media/$rest';
}
