import 'dart:js_interop';

import 'package:web/web.dart';

/// Uses the [Web Share API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Share_API).
Future<bool> shareReferralNativeWeb({
  required String title,
  required String text,
  required String url,
}) async {
  try {
    final data = ShareData(title: title, text: text, url: url);
    await window.navigator.share(data).toDart;
    return true;
  } catch (_) {
    return false;
  }
}
