import 'dart:math' as math;
import 'package:flutter/foundation.dart';

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
    this.gstPercent = 0.0,
    this.sgstPercent = 0.0,
    this.cgstPercent = 0.0,
    this.igstPercent = 0.0,
    this.basePrice = 0.0,
    this.images = const [],
    this.stock = 0,
    this.weight = 0,
    this.weightUnit = 'g',
    this.isComingSoon = false,
    this.isMlm = false,
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
  /// GST percentage for this product (e.g., 18.0 for 18% GST)
  final double gstPercent;
  final double sgstPercent;
  final double cgstPercent;
  final double igstPercent;
  final double basePrice;
  /// Available units in inventory (from API `stock`).
  final int stock;
  /// Pack / net weight amount (from API `weight`).
  final double weight;
  /// e.g. g, kg (from API `weightUnit`).
  final String weightUnit;
  /// Whether the product is tagged as "Coming Soon" (from API `is_coming_soon`).
  final bool isComingSoon;
  /// Whether the product is restricted to MLM members (from API `is_mlm`).
  final bool isMlm;

  factory Product.fromJson(Map<String, dynamic> json) {
    // Helper to find the first non-zero price value from a list of possible keys
    double getFirstNonZero(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value != null) {
          final parsed = _parseDouble(value);
          if (parsed > 0) return parsed;
        }
      }
      return 0;
    }

    // Priority 1: total_with_tax (as requested by user)
    // Priority 2: total_price (often used in backend for final display price)
    // Priority 3: price (standard field)
    // Priority 4: actual_price
    final priceValue = getFirstNonZero([
      'total_with_tax',
      'totalWithTax',
      'total_price',
      'totalPrice',
      'price',
      'actual_price',
      'actualPrice',
    ]);

    // Use total_price or actual_price for the "original" (strike-through) price
    // We prioritize fields that usually represent the MRP/Original price.
    final totalPriceValue = getFirstNonZero([
      'actual_price',
      'actualPrice',
      'total_price',
      'totalPrice',
    ]);

    // Ensure total price is at least as much as the current price
    final finalTotalPrice = math.max(priceValue, totalPriceValue > 0 ? totalPriceValue : priceValue);
    
    final parsedActual = priceValue;
    final parsedTotal = finalTotalPrice;
    
    // Debug output to see exactly what is being parsed from API
    if (kDebugMode) {
      print('--- PRODUCT PRICE DEBUG (${json["id"] ?? json["productId"]}) ---');
      print('Raw total_with_tax: ${json['total_with_tax']}');
      print('Raw total_price: ${json['total_price']}');
      print('Raw actual_price: ${json['actual_price']}');
      print('Final Price: $parsedActual');
      print('Final Total Price: $parsedTotal');
      print('-----------------------------------------');
    }

    final normalizedPrice = parsedActual;
    final normalizedTotal = parsedTotal;
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
    // 1. First try to get specific GST percentages from API
    double sgstPercent = _parseDouble(
      json['sgst_percentage'] ?? 
      json['sgst_percent'] ?? 
      json['sgstPercent'] ??
      json['sgst']
    );
    double cgstPercent = _parseDouble(
      json['cgst_percentage'] ?? 
      json['cgst_percent'] ?? 
      json['cgstPercent'] ??
      json['cgst']
    );
    double igstPercent = _parseDouble(
      json['igst_percentage'] ?? 
      json['igst_percent'] ?? 
      json['igstPercent'] ??
      json['igst']
    );
    
    // 2. Try to get a general GST percentage
    double gstPercent = _parseDouble(
      json['gst_percentage'] ??
      json['gst_percent'] ??
      json['gstPercent'] ??
      json['tax_percent'] ??
      json['taxPercent']
    );

    // 3. Smart Fallback: If all are 0, try to infer from total_price vs actual_price
    if (gstPercent <= 0 && sgstPercent <= 0 && cgstPercent <= 0 && igstPercent <= 0) {
      if (parsedTotal > parsedActual && parsedActual > 0) {
        final diff = parsedTotal - parsedActual;
        gstPercent = (diff / parsedActual) * 100;
        // Also distribute to others as a safe default
        sgstPercent = gstPercent;
        cgstPercent = gstPercent;
        igstPercent = gstPercent;
      }
    }
    
    // Robust base price parsing
    final basePrice = getFirstNonZero([
      'base_price',
      'basePrice',
      'actual_price',
      'actualPrice',
      'price',
    ]);

    // Debug GST parsing
    print('=== GST DEBUG ===');
    print('API Response: $json');
    print('Final GST Percent: $gstPercent');
    print('SGST: $sgstPercent, CGST: $cgstPercent, IGST: $igstPercent, Base: $basePrice');
    print('================');
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
      gstPercent: gstPercent,
      sgstPercent: sgstPercent,
      cgstPercent: cgstPercent,
      igstPercent: igstPercent,
      basePrice: basePrice,
      images: parsedImages,
      stock: _parseStock(json['stock'] ?? json['inventory']),
      weight: _parseDouble(json['weight'] ?? json['net_weight']),
      weightUnit: _parseWeightUnit(json['weightUnit'] ?? json['weight_unit']),
      isComingSoon: _parseBool(json['is_coming_soon'] ?? json['isComingSoon']),
      isMlm: _parseBool(json['is_mlm'] ?? json['isMlm']),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) {
      final s = value.toLowerCase().trim();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }

  /// Calculates dynamic price and GST details based on location.
  Map<String, dynamic> calculateDynamicPrice(String country, String state) {
    double selectedGstPercent = 0.0;
    String gstType = '';

    final countryNormalized = country.toLowerCase().trim();
    final stateNormalized = state.toLowerCase().trim();

    if (countryNormalized == 'india' || countryNormalized == 'in') {
      if (stateNormalized == 'haryana' || stateNormalized == 'hr') {
        selectedGstPercent = sgstPercent;
        gstType = 'SGST';
      } else {
        selectedGstPercent = cgstPercent;
        gstType = 'CGST';
      }
    } else {
      selectedGstPercent = igstPercent;
      gstType = 'IGST';
    }

    // Fallback if specific GST not provided but general gstPercent is
    if (selectedGstPercent <= 0 && gstPercent > 0) {
      selectedGstPercent = gstPercent;
    }

    final gstAmount = (basePrice * selectedGstPercent) / 100;
    final finalPrice = basePrice + gstAmount;

    return {
      'basePrice': basePrice,
      'gstType': gstType,
      'gstPercent': selectedGstPercent,
      'gstAmount': gstAmount,
      'finalPrice': finalPrice,
    };
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
    double? gstPercent,
    int? stock,
    double? weight,
    String? weightUnit,
    bool? isComingSoon,
    bool? isMlm,
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
      gstPercent: gstPercent ?? this.gstPercent,
      images: images ?? this.images,
      stock: stock ?? this.stock,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      isComingSoon: isComingSoon ?? this.isComingSoon,
      isMlm: isMlm ?? this.isMlm,
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
      'gstPercent': gstPercent,
      'stock': stock,
      'weight': weight,
      'weightUnit': weightUnit,
      'is_coming_soon': isComingSoon,
      'is_mlm': isMlm,
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

  /// Calculate GST amount for this product
  double get gstAmount {
    if (gstPercent <= 0) return 0;
    return (price * gstPercent) / 100;
  }

  /// Calculate price before GST (base price)
  double get priceBeforeGst {
    if (gstPercent <= 0) return price;
    return price / (1 + (gstPercent / 100));
  }

  /// Get formatted GST percentage string (e.g., "18%")
  String get gstPercentLabel {
    if (gstPercent <= 0) return '0%';
    return '${gstPercent.toStringAsFixed(1)}%';
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
