import 'product.dart';

class ProductCatalogEntry {
  const ProductCatalogEntry({
    required this.category,
    required this.brand,
    required this.product,
    required this.rating,
    required this.popularityScore,
    required this.publishedAt,
  });

  final String category;
  final String brand;
  final Product product;
  final double rating;
  final int popularityScore;
  final DateTime publishedAt;

  factory ProductCatalogEntry.fromJson(Map<String, dynamic> json) {
    final categories = (json['categories'] as List?)?.whereType<String>().toList() ?? const [];
    return ProductCatalogEntry(
      category: categories.isNotEmpty ? categories.first : (json['category'] as String? ?? 'General'),
      brand: json['brand'] as String? ?? 'Independent',
      product: Product.fromJson(json),
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      popularityScore: (json['popularityScore'] as num?)?.toInt() ?? 0,
      publishedAt: _parseDate(json['publishedAt']),
    );
  }

  ProductCatalogEntry copyWith({
    String? category,
    String? brand,
    Product? product,
    double? rating,
    int? popularityScore,
    DateTime? publishedAt,
  }) {
    return ProductCatalogEntry(
      category: category ?? this.category,
      brand: brand ?? this.brand,
      product: product ?? this.product,
      rating: rating ?? this.rating,
      popularityScore: popularityScore ?? this.popularityScore,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'brand': brand,
      'rating': rating,
      'popularityScore': popularityScore,
      'publishedAt': publishedAt.toIso8601String(),
      ...product.toJson(),
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }
}
