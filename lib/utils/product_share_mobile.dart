import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import '../models/product.dart';
import 'product_share_text.dart';

/// Shares product copy + downloadable primary image via the platform sheet.
Future<bool> shareProductDetails(Product product) async {
  final text = formatProductShareText(product);
  final uriStr = primaryProductImageUrl(product);
  if (uriStr.isEmpty) {
    await Share.share(text, subject: product.title);
    return true;
  }
  try {
    final uri = Uri.tryParse(uriStr);
    if (uri == null || !uri.hasScheme) {
      await Share.share('$text\n\nImage: $uriStr', subject: product.title);
      return true;
    }
    final res = await http.get(uri).timeout(const Duration(seconds: 25));
    if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
      final lower = uri.path.toLowerCase();
      final ext = lower.endsWith('.png')
          ? 'png'
          : lower.endsWith('.webp')
              ? 'webp'
              : 'jpg';
      final path =
          '${Directory.systemTemp.path}/product_share_${product.id.hashCode.abs()}.$ext';
      final file = File(path);
      await file.writeAsBytes(res.bodyBytes);
      final mime = ext == 'png'
          ? 'image/png'
          : ext == 'webp'
              ? 'image/webp'
              : 'image/jpeg';
      await Share.shareXFiles(
        [XFile(path, mimeType: mime)],
        text: text,
        subject: product.title,
      );
      try {
        await file.delete();
      } catch (_) {}
      return true;
    }
  } catch (_) {}
  await Share.share(
    '$text\n\nImage: $uriStr',
    subject: product.title,
  );
  return true;
}
