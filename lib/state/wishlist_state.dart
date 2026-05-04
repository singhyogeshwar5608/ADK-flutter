import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../services/api_client.dart';
import 'profile_state.dart';

/// Wishlist backed by API when signed in; device cache when browsing as guest.
/// On sign-in, guest cache entries are synced to the server when possible.
class WishlistState extends ChangeNotifier {
  WishlistState({required ProfileState profile}) : _profile = profile {
    _profile.addListener(_onProfileAuthChanged);
    _init();
  }

  final ApiClient _apiClient = ApiClient.instance;
  final ProfileState _profile;

  final Map<String, Product> _items = {};
  bool _isLoading = false;
  bool _initialized = false;
  bool _cachedAuthSegment = false;
  String? _error;

  static const String _cacheKey = 'wishlist_device_cache_v1';

  UnmodifiableListView<Product> get items =>
      UnmodifiableListView(_items.values.toList());
  bool get isEmpty => _items.isEmpty;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _onProfileAuthChanged() {
    final authenticated = _profile.isAuthenticated;
    if (authenticated == _cachedAuthSegment) return;
    final wasAuthenticated = _cachedAuthSegment;
    _cachedAuthSegment = authenticated;

    // Signed-out: drop server-backed list so guests never see another account's wishlist.
    if (!authenticated && wasAuthenticated) {
      unawaited(_clearWishlistAfterLogout());
      return;
    }
    unawaited(refresh());
  }

  Future<void> _clearWishlistAfterLogout() async {
    _items.clear();
    _error = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (e) {
      debugPrint('Failed to clear wishlist prefs on logout: $e');
    }
    notifyListeners();
  }

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    _cachedAuthSegment = _profile.isAuthenticated;
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      if (_profile.isAuthenticated) {
        final remoteItems = await _apiClient.fetchWishlistProducts();
        _items
          ..clear()
          ..addEntries(
              remoteItems.map((product) => MapEntry(product.id, product)));
        await _mergeCachedGuestProductsIntoServer();
        _error = null;
      } else {
        await _loadCacheOnly();
        _error = null;
      }
      await _persistCache();
    } catch (error, stack) {
      _error = error.toString();
      debugPrint('Failed to load wishlist: $error');
      debugPrintStack(stackTrace: stack);
      if (!_profile.isAuthenticated) {
        await _loadCacheOnly();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCacheOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      _items.clear();
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      final list =
          decoded is Map<String, dynamic> ? decoded['items'] : null;
      if (list is! List) return;
      for (final element in list) {
        if (element is Map<String, dynamic>) {
          final p = Product.fromJson(element);
          if (p.id.isEmpty) continue;
          _items[p.id] = p;
        }
      }
    } catch (e, st) {
      debugPrint('Failed to decode wishlist cache: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<List<Product>> _readCacheProductsOutsideMemory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      final list =
          decoded is Map<String, dynamic> ? decoded['items'] : null;
      if (list is! List) return const [];
      final out = <Product>[];
      for (final element in list) {
        if (element is Map<String, dynamic>) {
          final p = Product.fromJson(element);
          if (p.id.isEmpty) continue;
          out.add(p);
        }
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _mergeCachedGuestProductsIntoServer() async {
    final cached = await _readCacheProductsOutsideMemory();
    for (final product in cached) {
      if (_items.containsKey(product.id)) continue;
      try {
        await _apiClient.addToWishlist(product.id);
        _items[product.id] = product;
      } catch (e, st) {
        debugPrint(
            'Wishlist merge skipped for ${product.id} (offline or conflict): $e');
        debugPrintStack(stackTrace: st);
      }
    }
  }

  Future<void> _persistCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_items.isEmpty) {
        await prefs.remove(_cacheKey);
        return;
      }
      final list = _items.values.map((p) => p.toJson()).toList(growable: false);
      await prefs.setString(_cacheKey, jsonEncode({'items': list}));
    } catch (e) {
      debugPrint('Failed to persist wishlist cache: $e');
    }
  }

  bool contains(String productId) => _items.containsKey(productId);

  Future<void> add(Product product) async {
    _error = null;
    if (_items.containsKey(product.id)) return;
    _items[product.id] = product;
    notifyListeners();
    await _persistCache();

    if (!_profile.isAuthenticated) {
      return;
    }

    try {
      await _apiClient.addToWishlist(product.id);
    } catch (error, stack) {
      debugPrint('Failed to add to wishlist: $error');
      debugPrintStack(stackTrace: stack);
      _items.remove(product.id);
      await _persistCache();
      notifyListeners();
      _error = 'Unable to save wishlist item. Please try again.';
    }
  }

  Future<void> remove(String productId) async {
    _error = null;
    if (!_items.containsKey(productId)) return;
    final removed = _items.remove(productId);
    notifyListeners();
    await _persistCache();

    if (!_profile.isAuthenticated) {
      return;
    }

    try {
      await _apiClient.removeFromWishlist(productId);
    } catch (error, stack) {
      debugPrint('Failed to remove wishlist item: $error');
      debugPrintStack(stackTrace: stack);
      if (removed != null) {
        _items[productId] = removed;
        await _persistCache();
        notifyListeners();
      }
      _error = 'Unable to update wishlist. Please try again.';
    }
  }

  Future<void> toggle(Product product) async {
    _error = null;
    if (contains(product.id)) {
      await remove(product.id);
    } else {
      await add(product);
    }
  }

  /// Removes every item locally and from the API when signed in.
  Future<void> clearAll() async {
    _error = null;
    if (_items.isEmpty) return;
    final ids = _items.keys.toList(growable: false);
    _items.clear();
    notifyListeners();
    await _persistCache();

    if (!_profile.isAuthenticated) return;

    for (final id in ids) {
      try {
        await _apiClient.removeFromWishlist(id);
      } catch (error, stack) {
        debugPrint('Wishlist clearAll failed for $id: $error');
        debugPrintStack(stackTrace: stack);
      }
    }
  }

  /// Clears in-memory wishlist without touching the server cache file.
  void clearLocal() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _profile.removeListener(_onProfileAuthChanged);
    super.dispose();
  }
}

class WishlistProvider extends InheritedNotifier<WishlistState> {
  const WishlistProvider({
    super.key,
    required WishlistState notifier,
    required super.child,
  }) : super(notifier: notifier);

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
