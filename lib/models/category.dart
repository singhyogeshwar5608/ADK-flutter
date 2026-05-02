import '../utils/media_url.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    required this.isActive,
  });

  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final bool isActive;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'Category',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      logoUrl: _normLogo(json['logoUrl'] as String? ?? json['logo_url'] as String?),
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
    );
  }

  static String? _normLogo(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    return normalizeMediaUrl(url);
  }
}
