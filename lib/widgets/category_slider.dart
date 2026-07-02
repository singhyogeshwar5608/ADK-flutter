import 'package:flutter/material.dart';

import '../utils/media_url.dart';

/// Clean, circular horizontal category slider styled exactly as requested.
/// Uses a centered title header with divider lines and fallback icons.
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

class _CategorySliderState extends State<CategorySlider> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final dividerColor = isDark
        ? const Color(0xFF334155) // slate-700
        : const Color(0xFFE2E8F0); // slate-200

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Centered Header with Left & Right Dividers
        Row(
          children: [
            Expanded(
              child: Divider(
                color: dividerColor,
                thickness: 1,
                endIndent: 16,
              ),
            ),
            Text(
              'Categories',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                letterSpacing: 0.2,
              ),
            ),
            Expanded(
              child: Divider(
                color: dividerColor,
                thickness: 1,
                indent: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Subtitle centered below title
        Center(
          child: Text(
            'Find Exactly What You Need.',
            style: TextStyle(
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 18),
        // Horizontal list of categories
        SizedBox(
          height: 115,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 3),
            itemCount: widget.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final category = widget.categories[index];
              final isSelected = category.label == widget.selectedCategory;
              final hasLogo = category.heroImage.trim().isNotEmpty;

              return GestureDetector(
                onTap: () => widget.onCategorySelected(category),
                child: SizedBox(
                  width: 75,
                  child: Column(
                    children: [
                      Container(
                        width: 75,
                        height: 75,
                         decoration: BoxDecoration(
                           color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                           borderRadius: BorderRadius.circular(3),
                           border: Border.all(
                             color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                             width: 1,
                           ),
                           boxShadow: [
                             BoxShadow(
                               color: Colors.black.withValues(alpha: 0.12),
                               blurRadius: 8,
                               offset: const Offset(0, 4),
                             ),
                             BoxShadow(
                               color: Colors.black.withValues(alpha: 0.04),
                               blurRadius: 2,
                               offset: const Offset(0, 1),
                             ),
                           ],
                         ),
                        clipBehavior: Clip.antiAlias,
                        child: hasLogo
                              ? Image.network(
                                  normalizeMediaUrl(category.heroImage),
                                  width: 75,
                                  height: 75,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 28,
                                      color: Color(0xFF0F52BA),
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 28,
                                    color: Color(0xFF0F52BA),
                                  ),
                                ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        category.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF0F52BA)
                              : (isDark ? Colors.white70 : const Color(0xFF334155)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

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
