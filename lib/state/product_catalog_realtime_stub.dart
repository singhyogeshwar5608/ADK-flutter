import 'package:flutter/foundation.dart';

/// Web build: never import `pusher_client` (avoids DDC / web init failures).
class ProductCatalogRealtime {
  ProductCatalogRealtime();

  Future<bool> connect({
    required void Function() onProductEvent,
    required Iterable<String> eventNames,
  }) async {
    debugPrint('Product catalog realtime skipped on Flutter web.');
    return false;
  }

  void dispose() {}
}
