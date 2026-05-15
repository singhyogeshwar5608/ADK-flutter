class SocialLink {
  const SocialLink({
    required this.id,
    required this.platform,
    required this.link,
    this.title,
  });

  factory SocialLink.fromJson(Map<String, dynamic> json) {
    return SocialLink(
      id: (json['id'] as num?)?.toInt() ?? 0,
      platform: json['platform'] as String? ?? '',
      link: (json['url'] ?? json['link']) as String? ?? '',
      title: json['title'] as String?,
    );
  }

  final int id;
  final String platform;
  final String link;
  final String? title;

  bool get isYouTube => platform.toLowerCase() == 'youtube' || link.contains('youtube.com') || link.contains('youtu.be');
  bool get isFacebook => platform.toLowerCase() == 'facebook' || link.contains('facebook.com');
  bool get isInstagram => platform.toLowerCase() == 'instagram' || link.contains('instagram.com');
}
