import 'dart:async';

import 'package:flutter/material.dart';

import 'product_catalog_realtime_io.dart'
    if (dart.library.html) 'product_catalog_realtime_stub.dart';

import '../models/category.dart';
import '../models/product_entry.dart';
import '../services/api_client.dart';

const _productEventNames = <String>{
  'products.created',
  'products.updated',
  'products.deleted',
  'products.stock_adjusted',
};

class ProductCatalogState extends ChangeNotifier {
  ProductCatalogState() {
    _init();
  }

  final ApiClient _apiClient = ApiClient.instance;
  final ProductCatalogRealtime _realtime = ProductCatalogRealtime();
  List<ProductCatalogEntry> _entries = const [];
  List<Category> _categories = const [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshDebounce;
  bool _initialized = false;
  bool _realtimeReady = false;

  List<ProductCatalogEntry> get entries => _entries;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
    _setupRealtime();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      final productsFuture = _apiClient.fetchPublicProducts(limit: 100);
      final categoriesFuture = _apiClient.fetchPublicCategories(limit: 100);
      final remoteEntries = await productsFuture;
      final remoteCategories = await categoriesFuture;
      _entries = remoteEntries;
      _categories = remoteCategories;
      _error = null;
    } catch (error, stack) {
      _error = error.toString();
      debugPrint('Failed to refresh product catalog: $error');
      debugPrintStack(stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _setupRealtime() async {
    if (_realtimeReady) return;
    try {
      _realtimeReady = await _realtime.connect(
        onProductEvent: _debouncedRefresh,
        eventNames: _productEventNames,
      );
    } catch (error, stack) {
      debugPrint('Failed to initialize realtime updates: $error');
      debugPrintStack(stackTrace: stack);
    }
  }

  void _debouncedRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 600), () {
      refresh();
    });
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    _realtime.dispose();
    super.dispose();
  }
}

class ProductCatalogProvider extends InheritedNotifier<ProductCatalogState> {
  const ProductCatalogProvider(
      {super.key,
      required ProductCatalogState super.notifier,
      required super.child});

  static ProductCatalogState of(BuildContext context, {bool listen = true}) {
    if (listen) {
      final provider =
          context.dependOnInheritedWidgetOfExactType<ProductCatalogProvider>();
      assert(provider != null, 'No ProductCatalogProvider found in context');
      return provider!.notifier!;
    }
    final element = context
        .getElementForInheritedWidgetOfExactType<ProductCatalogProvider>();
    assert(element != null, 'No ProductCatalogProvider found in context');
    final provider = element!.widget as ProductCatalogProvider;
    return provider.notifier!;
  }
}
