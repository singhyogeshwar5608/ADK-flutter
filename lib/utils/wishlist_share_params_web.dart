// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

/// Reads wishlist token from the browser URL path.
/// Supported formats:
/// - /members/wishlist/TOKEN
/// - /wishlist/TOKEN
/// - /members/w/TOKEN
/// - /w/TOKEN
String? parseWishlistTokenFromUrl() {
  try {
    final href = html.window.location.href;
    final uri = Uri.parse(href);
    final path = uri.path.toLowerCase();
    
    // Remove /members prefix if present
    String effectivePath = path;
    if (path.startsWith('/members/')) {
      effectivePath = path.substring(8); // Remove '/members'
    }

    if (effectivePath.startsWith('/wishlist/')) {
      return effectivePath.substring(10);
    }
    if (effectivePath.startsWith('/w/')) {
      return effectivePath.substring(3);
    }
  } catch (_) {
    // ignore malformed URI
  }

  return null;
}
