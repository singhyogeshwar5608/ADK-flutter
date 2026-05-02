import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/product.dart';
import '../services/api_client.dart';

class WishlistState extends ChangeNotifier {
  WishlistState() {
    _init();
  }

  final ApiClient _apiClient = ApiClient.instance;
  final Map<String, Product> _items = {};
  bool _isLoading = false;
  bool _initialized = false;
  String? _error;

  UnmodifiableListView<Product> get items =>
      UnmodifiableListView(_items.values.toList());
  bool get isEmpty => _items.isEmpty;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      final remoteItems = await _apiClient.fetchWishlistProducts();
      _items
        ..clear()
        ..addEntries(
            remoteItems.map((product) => MapEntry(product.id, product)));
      _error = null;
    } catch (error, stack) {
      _error = error.toString();
      debugPrint('Failed to load wishlist: $error');
      debugPrintStack(stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool contains(String productId) => _items.containsKey(productId);

  Future<void> add(Product product) async {
    if (_items.containsKey(product.id)) return;
    _items[product.id] = product;
    notifyListeners();

    try {
      await _apiClient.addToWishlist(product.id);
    } catch (error, stack) {
      debugPrint('Failed to add to wishlist: $error');
      debugPrintStack(stackTrace: stack);
      _items.remove(product.id);
      notifyListeners();
      _error = 'Unable to save wishlist item. Please try again.';
    }
  }

  Future<void> remove(String productId) async {
    if (!_items.containsKey(productId)) return;
    final removed = _items.remove(productId);
    notifyListeners();

    try {
      await _apiClient.removeFromWishlist(productId);
    } catch (error, stack) {
      debugPrint('Failed to remove wishlist item: $error');
      debugPrintStack(stackTrace: stack);
      if (removed != null) {
        _items[productId] = removed;
        notifyListeners();
      }
      _error = 'Unable to update wishlist. Please try again.';
    }
  }

  Future<void> toggle(Product product) async {
    if (contains(product.id)) {
      await remove(product.id);
    } else {
      await add(product);
    }
  }

  void clearLocal() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}

class WishlistProvider extends InheritedNotifier<WishlistState> {
  const WishlistProvider(
      {super.key, required WishlistState notifier, required super.child})
      : super(notifier: notifier);

  static WishlistState of(BuildContext context, {bool listen = true}) {
    if (listen) {
      final provider =
          context.dependOnInheritedWidgetOfExactType<WishlistProvider>();
      assert(provider != null, 'No WishlistProvider found in context');
      return provider!.notifier!;
    }
    final element =
        context.getElementForInheritedWidgetOfExactType<WishlistProvider>();
    assert(element != null, 'No WishlistProvider found in context');
    final provider = element!.widget as WishlistProvider;
    return provider.notifier!;
  }
}
