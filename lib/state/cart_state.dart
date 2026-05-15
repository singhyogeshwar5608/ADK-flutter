import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../utils/media_url.dart';
import '../services/location_service.dart';
import 'profile_state.dart';
import 'location_state.dart';

class CartItem {
  CartItem({required this.product, this.quantity = 1}) : assert(quantity > 0);

  final Product product;
  int quantity;
  bool isSelected = true; // Default to selected

  double unitPrice([String? country, String? state]) {
    final data = product.calculateDynamicPrice(country ?? 'India', state ?? 'Haryana');
    return data['finalPrice'] as double;
  }

  double totalPrice([String? country, String? state]) {
    final data = product.calculateDynamicPrice(country ?? 'India', state ?? 'Haryana');
    return (data['finalPrice'] as double) * quantity;
  }

  double get totalShipping => product.shippingCharge * quantity;
  int get totalBv => product.bv * quantity;
  
  // GST calculations
  double totalGst([String? country, String? state]) {
    final data = product.calculateDynamicPrice(country ?? 'India', state ?? 'Haryana');
    return (data['gstAmount'] as double) * quantity;
  }

  double priceBeforeGst([String? country, String? state]) {
    final data = product.calculateDynamicPrice(country ?? 'India', state ?? 'Haryana');
    return (data['basePrice'] as double) * quantity;
  }
  
  // Debug GST in cart
  void debugCartGst() {
    print('=== CART GST DEBUG ===');
    print('Product ID: ${product.id}');
    print('Product Name: ${product.title}');
    print('Product GST Percent: ${product.gstPercent}');
    print('Product GST Amount: ${product.gstAmount}');
    print('Product Price: ${product.price}');
    print('Product Total Price: ${product.totalPrice}');
    print('Quantity: $quantity');
    print('Total GST: $totalGst');
    print('===================');
  }

  // Debug logging for GST
  void debugGstCalculation() {
    print('=== GST Debug ===');
    print('Product GST Percent: ${product.gstPercent}');
    print('Product GST Amount: ${product.gstAmount}');
    print('Product Price Before GST: ${product.priceBeforeGst}');
    print('Product Total Price: ${product.totalPrice}');
    print('Quantity: $quantity');
    print('Total GST: $totalGst');
    print('Price Before GST Total: $priceBeforeGst');
    print('=== End GST Debug ===');
  }

  Map<String, dynamic> toJson() {
    return {
      'product': _productSnapshot(product),
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'];
    if (productJson is! Map<String, dynamic>) {
      throw const FormatException('Cart item missing product payload');
    }
    final quantityValue = (json['quantity'] as num?)?.toInt() ?? 1;
    return CartItem(
      product: _productFromSnapshot(productJson),
      quantity: quantityValue > 0 ? quantityValue : 1,
    );
  }

  static Map<String, dynamic> _productSnapshot(Product product) {
    return {
      'id': product.id,
      'title': product.title,
      'imageUrl': product.imageUrl,
      'price': product.price,
      'totalPrice': product.totalPrice,
      'bv': product.bv,
      'description': product.description,
      'shippingCharge': product.shippingCharge,
      'gstPercent': product.gstPercent,
      'sgstPercent': product.sgstPercent,
      'cgstPercent': product.cgstPercent,
      'igstPercent': product.igstPercent,
      'basePrice': product.basePrice,
      'stock': product.stock,
      'weight': product.weight,
      'weightUnit': product.weightUnit,
      'images': product.images
          .map((image) => {
                'url': image.url,
                if (image.alt != null && image.alt!.isNotEmpty)
                  'alt': image.alt,
              })
          .toList(growable: false),
    };
  }

  static Product _productFromSnapshot(Map<String, dynamic> data) {
    final images = (data['images'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((image) => ProductImage(
                  url: normalizeMediaUrl(image['url'] as String? ?? ''),
                  alt: image['alt'] as String?,
                ))
            .toList(growable: false) ??
        const <ProductImage>[];

    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final totalPrice = (data['totalPrice'] as num?)?.toDouble() ?? price;
    final gstPercent = (data['gstPercent'] as num?)?.toDouble() ?? 0.0;
    final sgstPercent = (data['sgstPercent'] as num?)?.toDouble() ?? 0.0;
    final cgstPercent = (data['cgstPercent'] as num?)?.toDouble() ?? 0.0;
    final igstPercent = (data['igstPercent'] as num?)?.toDouble() ?? 0.0;
    final basePrice = (data['basePrice'] as num?)?.toDouble() ?? 0.0;

    return Product(
      id: data['id']?.toString() ?? '',
      title: data['title'] as String? ?? 'Untitled Product',
      imageUrl: normalizeMediaUrl(data['imageUrl'] as String? ?? ''),
      price: price,
      totalPrice: totalPrice,
      bv: (data['bv'] as num?)?.toInt() ?? 0,
      description: data['description'] as String? ?? '',
      shippingCharge: (data['shippingCharge'] as num?)?.toDouble() ?? 0.0,
      gstPercent: gstPercent,
      sgstPercent: sgstPercent,
      cgstPercent: cgstPercent,
      igstPercent: igstPercent,
      basePrice: basePrice,
      images: images,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      weight: (data['weight'] as num?)?.toDouble() ?? 0,
      weightUnit: (data['weightUnit'] as String?)?.trim().isNotEmpty == true
          ? (data['weightUnit'] as String).trim()
          : 'g',
    );
  }
}

class CartState extends ChangeNotifier {
  static const String _storageKey = 'cart_state_items';

  final Map<String, CartItem> _items = {};

  CartState({required ProfileState profile}) 
      : _profile = profile {
    _cachedAuthSegment = _profile.isAuthenticated;
    _profile.addListener(_onProfileAuthChanged);
    print('=== CART STATE INIT DEBUG ===');
    print('Cart State Initialized');
    print('========================');
    unawaited(_restoreCart());
  }

  final ProfileState _profile;
  bool _cachedAuthSegment = false;

  void _onProfileAuthChanged() {
    final authenticated = _profile.isAuthenticated;
    if (authenticated == _cachedAuthSegment) return;
    final wasAuthenticated = _cachedAuthSegment;
    _cachedAuthSegment = authenticated;
    if (!authenticated && wasAuthenticated) {
      clear();
    }
  }

  @override
  void dispose() {
    _profile.removeListener(_onProfileAuthChanged);
    super.dispose();
  }

  UnmodifiableListView<CartItem> get items =>
      UnmodifiableListView(_items.values);
  bool get isEmpty => _items.isEmpty;
  int get totalItems =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  double subtotal([String? country, String? state]) =>
      _items.values.fold(0.0, (sum, item) => sum + item.priceBeforeGst(country, state));
  double get shippingTotal =>
      _items.values.fold(0.0, (sum, item) => sum + item.totalShipping);
  double tax([String? country, String? state]) =>
      _items.values.fold(0.0, (sum, item) => sum + item.totalGst(country, state));
  double total([String? country, String? state]) => subtotal(country, state) + tax(country, state);

  int get totalBv => _items.values.fold(0, (sum, item) => sum + item.totalBv);

  // Selection related getters
  double selectedSubtotal([String? country, String? state]) => _items.values
      .where((item) => item.isSelected)
      .fold(0.0, (sum, item) => sum + item.priceBeforeGst(country, state));
  double selectedTax([String? country, String? state]) => _items.values
      .where((item) => item.isSelected)
      .fold(0.0, (sum, item) => sum + item.totalGst(country, state));
  double get selectedShippingTotal => _items.values
      .where((item) => item.isSelected)
      .fold(0.0, (sum, item) => sum + item.totalShipping);
  double selectedTotalGst([String? country, String? state]) => selectedTax(country, state);
  double selectedPriceBeforeGst([String? country, String? state]) => selectedSubtotal(country, state);
  double selectedTotal([String? country, String? state]) => selectedSubtotal(country, state) + selectedTax(country, state);

  int get selectedTotalBv => _items.values
      .where((item) => item.isSelected)
      .fold(0, (sum, item) => sum + item.totalBv);
  int get selectedItemsCount => _items.values
      .where((item) => item.isSelected)
      .fold(0, (sum, item) => sum + item.quantity);
  bool get allItemsSelected => _items.values.every((item) => item.isSelected);

  void addProduct(Product product, {int quantity = 1}) {
    final addQty = quantity < 1 ? 1 : quantity;
    final existing = _items[product.id];
    if (existing != null) {
      existing.quantity += addQty;
    } else {
      _items[product.id] = CartItem(
        product: product, 
        quantity: addQty,
      );
    }
    
    // Debug GST when adding product
    print('=== ADD PRODUCT GST DEBUG ===');
    print('Product: ${product.title}');
    print('Product GST Percent: ${product.gstPercent}');
    print('Product GST Amount: ${product.gstAmount}');
    print('Product Price: ${product.price}');
    print('Product Total Price: ${product.totalPrice}');
    print('Quantity: $addQty');
    print('============================');
    
    _persistCart();
    notifyListeners();
  }

  void increment(String productId) {
    final item = _items[productId];
    if (item == null) return;
    item.quantity += 1;
    _persistCart();
    notifyListeners();
  }

  void decrement(String productId) {
    final item = _items[productId];
    if (item == null) return;
    // Prevent quantity from going below 1
    if (item.quantity > 1) {
      item.quantity -= 1;
      _persistCart();
      notifyListeners();
    }
    // If quantity is 1, do nothing - don't remove the item
  }

  void removeItem(String productId) {
    final item = _items[productId];
    if (item == null) return;
    _items.remove(productId);
    _persistCart();
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    _persistCart();
    notifyListeners();
  }

  // Selection methods
  void toggleSelection(String productId) {
    final item = _items[productId];
    if (item == null) return;
    item.isSelected = !item.isSelected;
    _persistCart();
    notifyListeners();
  }

  void selectAll() {
    for (final item in _items.values) {
      item.isSelected = true;
    }
    _persistCart();
    notifyListeners();
  }

  void deselectAll() {
    for (final item in _items.values) {
      item.isSelected = false;
    }
    _persistCart();
    notifyListeners();
  }

  void toggleAllSelection() {
    if (allItemsSelected) {
      deselectAll();
    } else {
      selectAll();
    }
  }

  Future<void> _restoreCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      _items.clear();
      decoded.forEach((key, value) {
        if (value is! Map<String, dynamic>) return;
        try {
          final item = CartItem.fromJson(value);
          if (item.product.id.isEmpty) return;
          
          // Create new item
          _items[key] = CartItem(
            product: item.product,
            quantity: item.quantity,
          );
        } catch (error) {
          debugPrint('Failed to parse cart item $key: $error');
        }
      });
      notifyListeners();
    } catch (error) {
      debugPrint('Failed to restore cart: $error');
    }
  }

  Future<void> _persistCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_items.isEmpty) {
        await prefs.remove(_storageKey);
        return;
      }
      final serialized =
          _items.map((key, item) => MapEntry(key, item.toJson()));
      await prefs.setString(_storageKey, jsonEncode(serialized));
    } catch (error) {
      debugPrint('Failed to persist cart: $error');
    }
  }
}

class CartProvider extends InheritedNotifier<CartState> {
  const CartProvider(
      {super.key, required CartState notifier, required super.child})
      : super(notifier: notifier);

  static CartState of(BuildContext context, {bool listen = true}) {
    if (listen) {
      final provider =
          context.dependOnInheritedWidgetOfExactType<CartProvider>();
      assert(provider != null, 'No CartProvider found in context');
      return provider!.notifier!;
    }
    final element =
        context.getElementForInheritedWidgetOfExactType<CartProvider>();
    assert(element != null, 'No CartProvider found in context');
    final provider = element!.widget as CartProvider;
    return provider.notifier!;
  }
}
