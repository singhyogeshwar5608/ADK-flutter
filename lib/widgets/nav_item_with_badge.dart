import 'package:flutter/material.dart';

/// Icon centered in the nav slot with optional count badge (e.g. wishlist/cart).
class NavItemWithBadge extends StatelessWidget {
  const NavItemWithBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
    this.badgeCount = 0,
    this.iconSize = 22,
    this.fontSize = 11,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;
  final int badgeCount;
  final double iconSize;
  final double fontSize;

  static String badgeText(int count) =>
      count > 99 ? '99+' : (count <= 0 ? '' : '$count');

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: tint.withValues(alpha: 0.12),
        highlightColor: tint.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 28,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Icon(icon, color: tint, size: iconSize),
                    if (badgeCount > 0)
                      Positioned(
                        right: -8,
                        top: -6,
                        child: Container(
                          constraints: const BoxConstraints(
                              minWidth: 17, minHeight: 17),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white, width: 1.2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            badgeText(badgeCount),
                            style: const TextStyle(
                              fontSize: 9,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  height: 1.05,
                  color: tint,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
