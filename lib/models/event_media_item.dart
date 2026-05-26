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

  bool get isVideo {
    // If mediaType is explicitly set to video, respect it
    if (mediaType == EventMediaType.video) return true;
    
    final url = fileUrl.toLowerCase();
    
    // Direct file extensions
    if (url.endsWith('.mp4') || url.endsWith('.mov') || url.endsWith('.avi') || 
        url.endsWith('.mkv') || url.endsWith('.webm') || url.endsWith('.3gp') ||
        url.contains('.mp4?') || url.contains('.m3u8')) {
      return true;
    }
    
    // External video platforms
    if (isExternalVideo) {
      return true;
    }
    
    // Check for video markers in URL if mediaType is ambiguous
    if (url.contains('/videos/') || url.contains('/video/') || url.contains('vimeo.com')) {
      return true;
    }
    
    if (mimeType?.toLowerCase().startsWith('video/') == true) {
      return true;
    }
    
    return false;
  }

  bool get isExternalVideo {
    final url = fileUrl.toLowerCase();
    return url.contains('youtube.com') || url.contains('youtu.be') || 
           url.contains('facebook.com') || url.contains('fb.watch') ||
           url.contains('vimeo.com') || url.contains('instagram.com/reels/') ||
           url.contains('instagram.com/tv/');
  }

  bool get isYouTube => fileUrl.toLowerCase().contains('youtube.com') || fileUrl.toLowerCase().contains('youtu.be');
  bool get isFacebook => fileUrl.toLowerCase().contains('facebook.com') || fileUrl.toLowerCase().contains('fb.watch');

  String? get youtubeThumbnail {
    if (!isYouTube) return null;
    final regExp = RegExp(
      r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(fileUrl);
    if (match != null && match.group(7) != null && match.group(7)!.length == 11) {
      final videoId = match.group(7)!;
      return 'https://img.youtube.com/vi/$videoId/0.jpg';
    }
    return null;
  }

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
