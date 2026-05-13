import 'package:flutter/foundation.dart';

/// Web build: Reverb/WebSocket IO stack is omitted (use HTTP refresh only).
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
