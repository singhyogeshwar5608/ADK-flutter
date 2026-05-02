import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/media_url.dart';

/// Home categories: horizontal row with chevron scroll, inner soft circle + teal
/// icon, and a continuously rotating dotted outer ring (screenshot design).
class CategorySlider extends StatefulWidget {
  const CategorySlider({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.onViewAllTap,
  });

  final List<CategoryCardData> categories;
  final String selectedCategory;
  final ValueChanged<CategoryCardData> onCategorySelected;
  final VoidCallback? onViewAllTap;

  @override
  State<CategorySlider> createState() => _CategorySliderState();
}

class _CategorySliderState extends State<CategorySlider>
    with SingleTickerProviderStateMixin {
  /// ~80% of original 72 / 52 (user-requested smaller circles).
  static const double _outerSize = 58;
  static const double _innerSize = 42;
  static const double _listSeparator = 6;
  static const int _visibleSlots = 4;

  late final ScrollController _scrollController;
  late final AnimationController _ringRotation;
  /// Updated each layout; used for chevron scroll step.
  double _scrollStep = 88;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _ringRotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _ringRotation.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollBy(double delta) {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + delta).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  double get _rowHeight =>
      12 + _outerSize + 6 + 34; // padding + ring + gap + ~2 lines label

  /// Top padding inside each category cell (must match item `Padding`).
  static const double _itemPadTop = 2;

  /// Y of dotted-ring center from top of list row (items are top-aligned).
  double get _circleCenterY => _itemPadTop + _outerSize / 2;

  /// Align chevrons to this row fraction so they line up with circles, not labels.
  Alignment get _chevronRingAlign {
    final h = _rowHeight;
    if (h <= 0) return Alignment.centerLeft;
    final y = (2 * _circleCenterY / h) - 1;
    return Alignment(0, y);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final teal = colorScheme.primary;
    final innerFill = colorScheme.surfaceContainerHighest.withValues(alpha: 0.65);
    final rowH = _rowHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Categories',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: widget.onViewAllTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: Size.zero,
              ),
              child: Text(
                'View All',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: teal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: rowH,
              width: 28,
              child: Align(
                alignment: _chevronRingAlign,
                child: _ChevronNavButton(
                  icon: Icons.chevron_left_rounded,
                  iconColor: teal,
                  onPressed: () => _scrollBy(-_scrollStep),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final listW = constraints.maxWidth;
                  final itemWidth = (listW -
                          (_visibleSlots - 1) * _listSeparator) /
                      _visibleSlots;
                  _scrollStep = itemWidth + _listSeparator;

                  return SizedBox(
                    height: rowH,
                    child: ListView.separated(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: widget.categories.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: _listSeparator),
                      itemBuilder: (context, index) {
                        final category = widget.categories[index];
                        final isSelected =
                            category.label == widget.selectedCategory;
                        final accent =
                            _categoryAccentColors[category.label] ?? teal;
                        final hasLogo =
                            category.heroImage.trim().isNotEmpty;

                        return SizedBox(
                          width: itemWidth,
                          height: rowH,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () =>
                                    widget.onCategorySelected(category),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: _itemPadTop,
                                    bottom: _itemPadTop,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                    SizedBox(
                                      width: _outerSize,
                                      height: _outerSize,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        clipBehavior: Clip.none,
                                        children: [
                                          RotationTransition(
                                            turns: _ringRotation,
                                            child: CustomPaint(
                                              size: const Size.square(
                                                  _outerSize),
                                              painter: _DottedRingPainter(
                                                color: accent,
                                                strokeWidth: 1.75,
                                                dashSweep: 0.11,
                                                gapSweep: 0.09,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: _innerSize,
                                            height: _innerSize,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: innerFill,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(
                                                          alpha: 0.04),
                                                  blurRadius: 3,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: hasLogo
                                                ? Image.network(
                                                    normalizeMediaUrl(category
                                                        .heroImage),
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, __, ___) => Icon(
                                                      category.icon,
                                                      size: 20,
                                                      color: accent,
                                                    ),
                                                  )
                                                : Icon(
                                                    category.icon,
                                                    size: 20,
                                                    color: accent,
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      category.label,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        fontSize: 11.5,
                                        height: 1.12,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? accent
                                            : colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 2),
            SizedBox(
              height: rowH,
              width: 28,
              child: Align(
                alignment: _chevronRingAlign,
                child: _ChevronNavButton(
                  icon: Icons.chevron_right_rounded,
                  iconColor: teal,
                  onPressed: () => _scrollBy(_scrollStep),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChevronNavButton extends StatelessWidget {
  const _ChevronNavButton({
    required this.icon,
    required this.iconColor,
    required this.onPressed,
  });

  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 26,
        minHeight: 26,
      ),
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: iconColor, size: 17),
    );
  }
}

/// Dotted / dashed ring drawn as short arcs around a circle (rotated by parent).
class _DottedRingPainter extends CustomPainter {
  _DottedRingPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashSweep,
    required this.gapSweep,
  });

  final Color color;
  final double strokeWidth;
  final double dashSweep;
  final double gapSweep;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    var theta = -math.pi / 2;
    const twoPi = 2 * math.pi;
    final step = dashSweep + gapSweep;
    while (theta < -math.pi / 2 + twoPi - 1e-4) {
      canvas.drawArc(rect, theta, dashSweep, false, paint);
      theta += step;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedRingPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashSweep != dashSweep ||
      oldDelegate.gapSweep != gapSweep;
}

const Map<String, Color> _categoryAccentColors = {
  'Smart Tech': Color(0xFF3B82F6),
  'Health & Wellness': Color(0xFF10B981),
  'Beauty & Care': Color(0xFFEC4899),
  'Home & Decor': Color(0xFFF97316),
  'Accessories': Color(0xFF8B5CF6),
};

class CategoryCardData {
  const CategoryCardData({
    required this.label,
    required this.icon,
    required this.heroImage,
    required this.productCount,
  });

  final String label;
  final IconData icon;
  final String heroImage;
  final int productCount;

  CategoryCardData copyWith({
    String? label,
    IconData? icon,
    String? heroImage,
    int? productCount,
  }) {
    return CategoryCardData(
      label: label ?? this.label,
      icon: icon ?? this.icon,
      heroImage: heroImage ?? this.heroImage,
      productCount: productCount ?? this.productCount,
    );
  }
}
