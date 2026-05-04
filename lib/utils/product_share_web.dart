import 'package:flutter/services.dart';

import '../models/product.dart';
import 'product_share_text.dart';
import 'share_referral_web.dart';

Future<bool> shareProductDetails(Product product) async {
  final text = formatProductShareText(product);
  final imageUrl = primaryProductImageUrl(product);

  final ok = await shareReferralNativeWeb(
    title: product.title,
    text: text,
    url: imageUrl,
  );
  if (ok) return true;

  final clip = imageUrl.isNotEmpty ? '$text\n\nImage:\n$imageUrl' : text;
  await Clipboard.setData(ClipboardData(text: clip));
  return false;
}
