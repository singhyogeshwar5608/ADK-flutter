import 'package:flutter/material.dart';

import '../utils/media_url.dart';

class SafeNetworkImage extends StatelessWidget {
  const SafeNetworkImage({
    super.key,
    required this.src,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
  });

  final String src;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;

  static const String _fallbackAsset = 'assets/images/img2.png';

  @override
  Widget build(BuildContext context) {
    final placeholderColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final resolved = normalizeMediaUrl(src);

    return Image.network(
      resolved,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        _fallbackAsset,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: placeholderColor.withValues(alpha: 0.4),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }
}
