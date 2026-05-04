import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Compact social links (same targets as former Contact Us row) for Media Gallery header.
class SocialMediaLinksBar extends StatelessWidget {
  const SocialMediaLinksBar({super.key});

  static const List<_SocialLink> _links = [
    _SocialLink(
      icon: Icons.play_circle_filled_rounded,
      color: Color(0xFFFF0000),
      tooltip: 'YouTube',
      url: 'https://youtube.com/@adkofficial',
    ),
    _SocialLink(
      icon: Icons.facebook_rounded,
      color: Color(0xFF1877F2),
      tooltip: 'Facebook',
      url: 'https://facebook.com/adkofficial',
    ),
    _SocialLink(
      icon: Icons.camera_alt_rounded,
      color: Color(0xFFE4405F),
      tooltip: 'Instagram',
      url: 'https://instagram.com/adkofficial',
    ),
  ];

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final link in _links)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Tooltip(
              message: link.tooltip,
              child: Material(
                color: link.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _open(context, link.url),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(link.icon, color: link.color, size: 22),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SocialLink {
  const _SocialLink({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.url,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final String url;
}
