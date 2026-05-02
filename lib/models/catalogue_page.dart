import '../utils/media_url.dart';

class CataloguePage {
  const CataloguePage({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.imagePath,
    required this.orderIndex,
    required this.isActive,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String title;
  final String imageUrl;
  final String imagePath;
  final int orderIndex;
  final bool isActive;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CataloguePage.fromJson(Map<String, dynamic> json) {
    return CataloguePage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Untitled Page',
      imageUrl: normalizeMediaUrl(
        json['imageUrl'] as String? ?? json['image_url'] as String? ?? '',
      ),
      imagePath: json['imagePath'] as String? ?? json['image_path'] as String? ?? '',
      orderIndex: (json['orderIndex'] ?? json['order_index'] ?? 0) as int,
      isActive: (json['isActive'] ?? json['is_active'] ?? true) as bool,
      publishedAt: _parseDate(json['publishedAt'] ?? json['published_at']),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  CataloguePage copyWith({
    int? id,
    String? title,
    String? imageUrl,
    String? imagePath,
    int? orderIndex,
    bool? isActive,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CataloguePage(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      orderIndex: orderIndex ?? this.orderIndex,
      isActive: isActive ?? this.isActive,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
