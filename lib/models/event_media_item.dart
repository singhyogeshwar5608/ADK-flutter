import '../utils/media_url.dart';

enum EventMediaType { image, video }

EventMediaType _eventMediaTypeFrom(String? value) {
  switch (value?.toUpperCase()) {
    case 'VIDEO':
      return EventMediaType.video;
    default:
      return EventMediaType.image;
  }
}

class EventMediaItem {
  const EventMediaItem({
    required this.id,
    required this.title,
    required this.mediaType,
    required this.fileUrl,
    this.caption,
    this.description,
    this.thumbnailUrl,
    this.mimeType,
    this.fileSizeBytes,
    this.durationSeconds,
    this.isActive = true,
    this.sortOrder,
    this.meta,
    this.uploadedAt,
  });

  factory EventMediaItem.fromJson(Map<String, dynamic> json) {
    return EventMediaItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Untitled',
      caption: json['caption'] as String?,
      description: json['description'] as String?,
      mediaType: _eventMediaTypeFrom(json['mediaType'] as String?),
      fileUrl: normalizeMediaUrl(json['fileUrl'] as String? ?? ''),
      thumbnailUrl: _normThumb(json['thumbnailUrl'] as String?),
      mimeType: json['mimeType'] as String?,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: (json['sortOrder'] as num?)?.toInt(),
      meta: json['meta'] is Map<String, dynamic> ? json['meta'] as Map<String, dynamic>? : null,
      uploadedAt: json['uploadedAt'] != null ? DateTime.tryParse(json['uploadedAt'] as String) : null,
    );
  }

  static String? _normThumb(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    return normalizeMediaUrl(url);
  }

  final int id;
  final String title;
  final String? caption;
  final String? description;
  final EventMediaType mediaType;
  final String fileUrl;
  final String? thumbnailUrl;
  final String? mimeType;
  final int? fileSizeBytes;
  final int? durationSeconds;
  final bool isActive;
  final int? sortOrder;
  final Map<String, dynamic>? meta;
  final DateTime? uploadedAt;

  bool get isVideo => mediaType == EventMediaType.video;

  String get categoryLabel {
    final raw = meta?["category"];
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    return isVideo ? 'Video' : 'Image';
  }

  String? get thumbOrFile => thumbnailUrl?.isNotEmpty == true ? thumbnailUrl : fileUrl;
}

class EventMediaResponse {
  const EventMediaResponse({required this.items, required this.meta});

  factory EventMediaResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(EventMediaItem.fromJson)
        .toList(growable: false);
    return EventMediaResponse(
      items: data,
      meta: PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>? ?? const {}),
    );
  }

  final List<EventMediaItem> items;
  final PaginationMeta meta;
}

class PaginationMeta {
  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 12,
      total: (json['total'] as num?)?.toInt() ?? 0,
      pages: (json['pages'] as num?)?.toInt() ?? 1,
    );
  }

  final int page;
  final int limit;
  final int total;
  final int pages;
}
