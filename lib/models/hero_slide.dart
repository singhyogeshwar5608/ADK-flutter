import '../utils/media_url.dart';

/// Active hero slider row from `GET /api/v1/hero-sliders/active`.
class HeroSlide {
  const HeroSlide({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.sortOrder,
  });

  final int id;
  final String imageUrl;
  final String title;
  final String subtitle;
  final String badge;
  final int sortOrder;

  factory HeroSlide.fromJson(Map<String, dynamic> json) {
    final rawImage = json['image_url'] as String? ??
        json['imageUrl'] as String? ??
        '';
    return HeroSlide(
      id: (json['id'] as num?)?.toInt() ?? 0,
      imageUrl: normalizeMediaUrl(rawImage),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      badge: (json['badge'] as String?)?.trim().isNotEmpty == true
          ? json['badge'] as String
          : 'Featured',
      sortOrder: (json['sort_order'] as num?)?.toInt() ??
          (json['sortOrder'] as num?)?.toInt() ??
          0,
    );
  }
}
