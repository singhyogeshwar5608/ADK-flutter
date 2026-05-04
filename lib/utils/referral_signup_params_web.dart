// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

class ReferralSignupQuery {
  const ReferralSignupQuery({this.referralCode, this.leg});

  final String? referralCode;
  final String? leg;
}

/// Reads `ref` / `referral_code` and optional `leg` from the browser URL (path or hash).
ReferralSignupQuery parseReferralSignupFromUrl() {
  String? ref;
  String? leg;

  void takeFromQuery(Map<String, String> q) {
    final r = (q['ref'] ?? q['referral_code'] ?? '').trim();
    if (r.isNotEmpty) ref = r;
    final l = (q['leg'] ?? '').trim().toUpperCase();
    if (l == 'LEFT' || l == 'RIGHT') leg = l;
  }

  try {
    final href = html.window.location.href;
    final uri = Uri.parse(href);
    takeFromQuery(uri.queryParameters);

    final h = html.window.location.hash;
    if (h.contains('?')) {
      final qStart = h.indexOf('?');
      final raw = h.substring(qStart + 1);
      takeFromQuery(Uri.splitQueryString(raw));
    }
  } catch (_) {
    // ignore malformed URI
  }

  return ReferralSignupQuery(referralCode: ref, leg: leg);
}
