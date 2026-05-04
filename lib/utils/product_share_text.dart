import '../models/product.dart';

String formatProductShareText(Product product) {
  final buf = StringBuffer();
  buf.writeln(product.title);
  buf.writeln('Price: ₹${product.price.toStringAsFixed(2)}');
  buf.writeln('BV: ${product.bv}');
  final d = product.description.trim();
  if (d.isNotEmpty) {
    buf.writeln();
    buf.writeln(d.length > 500 ? '${d.substring(0, 500)}…' : d);
  }
  return buf.toString().trimRight();
}

String primaryProductImageUrl(Product product) {
  final urls = product.galleryImages;
  if (urls.isNotEmpty) return urls.first;
  return product.imageUrl;
}
