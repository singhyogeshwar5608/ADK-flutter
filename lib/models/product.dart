import 'dart:math' as math;

import '../utils/media_url.dart';

class Product {
  const Product({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.totalPrice,
    required this.bv,
    required this.description,
    required this.shippingCharge,
    this.images = const [],
    this.stock = 0,
    this.weight = 0,
    this.weightUnit = 'g',
  }) : assert(price <= totalPrice, 'Actual price cannot exceed total price');

  final String id;
  final String title;
  final String imageUrl;
  final double price;
  final double totalPrice;
  final int bv;
  final String description;
  final List<ProductImage> images;
  final double shippingCharge;
  /// Available units in inventory (from API `stock`).
  final int stock;
  /// Pack / net weight amount (from API `weight`).
  final double weight;
  /// e.g. g, kg (from API `weightUnit`).
  final String weightUnit;

  factory Product.fromJson(Map<String, dynamic> json) {
    final priceValue =
        json['actualPrice'] ?? json['actual_price'] ?? json['price'] ?? 0;
    final totalPriceValue =
        json['totalPrice'] ?? json['total_price'] ?? priceValue;
    final parsedActual = _parseDouble(priceValue);
    final parsedTotal = _parseDouble(totalPriceValue);
    final normalizedPrice = math.min(parsedActual, parsedTotal);
    final normalizedTotal = math.max(parsedActual, parsedTotal);
    final parsedImages = (json['images'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(ProductImage.fromJson)
            .where((image) => image.url.isNotEmpty)
            .toList(growable: false) ??
        const <ProductImage>[];
    final rawImageUrl = json['imageUrl'] as String? ??
        json['primaryImage'] as String? ??
        (parsedImages.isNotEmpty ? parsedImages.first.url : '');
    final imageUrl = normalizeMediaUrl(rawImageUrl);
    return Product(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          json['productId']?.toString() ??
          '',
      title: json['title'] as String? ??
          json['name'] as String? ??
          'Untitled Product',
      imageUrl: imageUrl,
      price: normalizedPrice,
      totalPrice: normalizedTotal,
      bv: _parseDouble(json['bv']).round(),
      description: json['description'] as String? ?? '',
      shippingCharge: _parseDouble(
        json['shipping_charge'] ?? json['shippingCharge'],
      ),
      images: parsedImages,
      stock: _parseStock(json['stock'] ?? json['inventory']),
      weight: _parseDouble(json['weight'] ?? json['net_weight']),
      weightUnit: _parseWeightUnit(json['weightUnit'] ?? json['weight_unit']),
    );
  }

  /// Human-readable pack size for product detail (e.g. `500 g`).
  String get sizeLabel {
    if (weight <= 0) return '—';
    final w = weight == weight.roundToDouble()
        ? weight.toInt().toString()
        : weight.toStringAsFixed(2);
    return '$w $weightUnit'.trim();
  }

  Product copyWith({
    String? id,
    String? title,
    String? imageUrl,
    double? price,
    double? totalPrice,
    int? bv,
    String? description,
    List<ProductImage>? images,
    double? shippingCharge,
    int? stock,
    double? weight,
    String? weightUnit,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      totalPrice: totalPrice ?? this.totalPrice,
      bv: bv ?? this.bv,
      description: description ?? this.description,
      shippingCharge: shippingCharge ?? this.shippingCharge,
      images: images ?? this.images,
      stock: stock ?? this.stock,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'actualPrice': price,
      'totalPrice': totalPrice,
      'bv': bv,
      'description': description,
      'shippingCharge': shippingCharge,
      'stock': stock,
      'weight': weight,
      'weightUnit': weightUnit,
      'images': images.map((image) => image.toJson()).toList(),
    };
  }

  List<String> get galleryImages {
    final gallery = images
        .map((image) => image.url)
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    if (gallery.isNotEmpty) {
      return gallery;
    }
    return imageUrl.isNotEmpty ? [imageUrl] : const [];
  }

  double get commissionAmount {
    final difference = totalPrice - price;
    return difference > 0 ? difference : 0;
  }

  double get commissionPercent {
    if (totalPrice <= 0 || commissionAmount <= 0) return 0;
    return (commissionAmount / totalPrice) * 100;
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  static int _parseStock(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _parseWeightUnit(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return 'g';
  }
}

class ProductImage {
  const ProductImage({required this.url, this.alt});

  final String url;
  final String? alt;

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      url: normalizeMediaUrl(json['url'] as String? ?? ''),
      alt: json['alt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        if (alt != null && alt!.isNotEmpty) 'alt': alt,
      };
}
