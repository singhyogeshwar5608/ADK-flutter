import 'package:flutter/material.dart';

import '../models/product.dart';
import '../state/cart_state.dart';
import '../state/wishlist_state.dart';
import '../theme/app_theme.dart';
import 'safe_network_image.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.rating,
    this.onProductTap,
  });

  final Product product;
  final double rating;
  /// Opens product details; kept inside the card so wishlist / PageView gestures are not eaten by an outer [InkWell].
  final VoidCallback? onProductTap;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late final PageController _pageController;
  int _currentIndex = 0;

  List<String> get _images {
    final gallery = widget.product.galleryImages;
    return gallery.isNotEmpty ? gallery : [widget.product.imageUrl];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleWishlist(BuildContext context) async {
    if (widget.product.id.trim().isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('This product cannot be saved (missing id).'),
        ),
      );
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    final wishlist = WishlistProvider.of(context, listen: false);
    await wishlist.toggle(widget.product);
    if (!context.mounted) return;
    final err = WishlistProvider.of(context, listen: false).error;
    if (err != null && err.isNotEmpty) {
      messenger?.showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dynamicPriceData = widget.product.calculateDynamicPrice('India', 'Haryana');
    final finalPrice = dynamicPriceData['finalPrice'] as double;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactCard = constraints.maxWidth <= 220;

        final wishlistState = WishlistProvider.of(context);
        final isWishlisted = wishlistState.contains(widget.product.id);
        final cartState = CartProvider.of(context);
        final inCart = cartState.items
            .any((e) => e.product.id.trim() == widget.product.id.trim());
        final wishlistIconSize = isCompactCard ? 15.0 : 18.0;
        final wishlistButtonSize = isCompactCard ? 28.0 : 38.0;
        final isLightTheme = !isDark;
        const wishlistRed = Color(0xFFFF3B3B);
        // Neutral pill always; saved state shows only via red icon (not red background).
        final Color wishlistFillColor = isLightTheme
            ? Colors.white.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.18);
        final Color wishlistIconColor = isWishlisted
            ? wishlistRed
            : (isLightTheme ? const Color(0xFF1F1F1F) : Colors.white);
        final wishlistBorderColor = isLightTheme
            ? const Color(0x15000000)
            : Colors.white.withValues(alpha: 0.15);

        Widget buildImageSection() {
          final discountPercent = widget.product.discountPercentage;
          final discountLabel = discountPercent > 0
              ? '${discountPercent.round()}% OFF'
              : null;
          final images = _images;
          // [InkWell] only around the pager; wishlist sits above in paint/hit-test order so it receives taps first.
          Widget pageGallery = PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: SafeNetworkImage(
                src: images[index],
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
          );
          if (widget.onProductTap != null) {
            pageGallery = Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onProductTap,
                child: pageGallery,
              ),
            );
          }

          final imageStack = Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 1.0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: pageGallery,
                  ),
                ),
              ),
              if (widget.product.isComingSoon)
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade600,
                          Colors.orange.shade700,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined,
                            color: Colors.white, size: 12),
                        SizedBox(width: 5),
                        Text(
                          'COMING SOON',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: widget.product.isComingSoon ? 32 : 12,
                left: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          widget.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: widget.product.isComingSoon ? 30 : 10,
                right: 10,
                child: Tooltip(
                  message: isWishlisted
                      ? 'Remove from wishlist'
                      : 'Save to wishlist',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _toggleWishlist(context),
                      child: Ink(
                        width: wishlistButtonSize,
                        height: wishlistButtonSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: wishlistFillColor,
                          border: Border.all(color: wishlistBorderColor),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x24000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Icon(
                              isWishlisted
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              key: ValueKey<bool>(isWishlisted),
                              color: wishlistIconColor,
                              size: wishlistIconSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (images.length > 1)
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (index) {
                      final isActive = index == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 4,
                        width: isActive ? 16 : 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                ),
              if (discountLabel != null)
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      discountLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          );

          return AspectRatio(
            aspectRatio: 1,
            child: imageStack,
          );
        }

        final double? originalPrice =
            widget.product.totalPrice > widget.product.price
                ? widget.product.totalPrice
                : null;
        final bodyPadding = EdgeInsets.all(isCompactCard ? 10 : 16);
        final titleStyle = theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: isCompactCard ? 10 : null,
        );
        final priceStyle = theme.textTheme.labelSmall?.copyWith(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: isCompactCard ? 11 : null,
        );
        final bvStyle = theme.textTheme.labelSmall?.copyWith(
          color: AppColors.mlmGreen,
          fontWeight: FontWeight.w700,
          fontSize: isCompactCard ? 11 : null,
        );
        final smallGap = isCompactCard ? 4.0 : 6.0;

        // 20% less than previous symmetric (6, 4) → scales with card width
        final double btnPadV = (isCompactCard ? 5.0 : 6.0) * 0.8;
        final double btnPadH = (isCompactCard ? 3.0 : 4.0) * 0.8;
        final double btnIconSize = (isCompactCard ? 12.0 : 14.0).clamp(11.0, 16.0);
        final double btnLabelSize =
            (constraints.maxWidth * 0.038).clamp(8.5, 11.5);

        Widget buildActionButton({
          required bool filled,
          required IconData icon,
          required String label,
          required VoidCallback? onPressed,
          Color? filledBackgroundOverride,
          Color? outlineColorOverride,
        }) {
          final isDisabled = onPressed == null;
          final fillBg = isDisabled
              ? theme.disabledColor.withValues(alpha: 0.12)
              : (filledBackgroundOverride ?? theme.colorScheme.primary);
          final fillFg = isDisabled
              ? theme.disabledColor
              : Colors.white;
          final outlineColor = outlineColorOverride ?? theme.colorScheme.primary;
          final labelStyle = TextStyle(
            fontSize: btnLabelSize,
            fontWeight: FontWeight.w700,
            color: filled 
                ? fillFg 
                : (isDisabled ? theme.disabledColor : outlineColor),
          );
          final content = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(
                icon,
                size: btnIconSize,
                color: filled 
                    ? fillFg 
                    : (isDisabled ? theme.disabledColor : outlineColor),
              ),
              SizedBox(width: isCompactCard ? 3 : 5),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: labelStyle,
                  ),
                ),
              ),
            ],
          );

          if (filled) {
            return FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: btnPadV,
                  horizontal: btnPadH,
                ),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: fillBg,
                foregroundColor: fillFg,
                disabledBackgroundColor: theme.disabledColor.withValues(alpha: 0.12),
                disabledForegroundColor: theme.disabledColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: content,
            );
          }
          return OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: btnPadV,
                horizontal: btnPadH,
              ),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide(
                color: isDisabled ? theme.disabledColor : outlineColor,
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: content,
          );
        }

        return Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Builder(
            builder: (context) {
              Widget info = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: bodyPadding.copyWith(bottom: 0, left: 4, right: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                        SizedBox(height: smallGap),
                        if (originalPrice != null)
                          Row(
                            children: [
                              Text(
                                '₹${originalPrice.toStringAsFixed(0)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.45),
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: isCompactCard ? 10 : 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (widget.product.discountPercentage > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: const Color(0xFFFECACA),
                                    ),
                                  ),
                                  child: Text(
                                    '${widget.product.discountPercentage.round()}% OFF',
                                    style: const TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        SizedBox(height: isCompactCard ? 4 : 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '₹${finalPrice.toStringAsFixed(0)}',
                              key: ValueKey('price_${widget.product.id}_${finalPrice}'),
                              style: priceStyle?.copyWith(
                                fontSize: isCompactCard ? 13 : 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.token,
                                  size: 14,
                                  color: AppColors.mlmGreen,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${widget.product.bv} BV',
                                  key: ValueKey('bv_${widget.product.id}_${widget.product.bv}'),
                                  style: bvStyle,
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (originalPrice != null)
                          Padding(
                            padding: EdgeInsets.only(
                              top: isCompactCard ? 4 : 6,
                            ),
                            child: Text(
                              'Save ₹${(widget.product.totalPrice - finalPrice).toStringAsFixed(0)}',
                              style: TextStyle(
                                color: const Color(0xFF059669),
                                fontWeight: FontWeight.w700,
                                fontSize: isCompactCard ? 10 : 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: buildActionButton(
                        filled: false,
                        icon: inCart
                            ? Icons.shopping_cart_rounded
                            : Icons.shopping_cart_outlined,
                        label: inCart ? 'In Cart' : 'Add to Cart',
                        outlineColorOverride: inCart
                            ? const Color(0xFF059669)
                            : theme.colorScheme.primary,
                        onPressed: widget.product.isComingSoon
                            ? null
                            : () {
                                CartProvider.of(context, listen: false)
                                    .addProduct(widget.product);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        inCart
                                            ? 'Quantity updated — this item is in your cart.'
                                            : 'This item has been added to your cart.',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.98),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      backgroundColor: theme.colorScheme.inverseSurface,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                              },
                      ),
                    ),
                  ),
                ],
              );
              if (widget.onProductTap != null) {
                info = Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onProductTap,
                    child: info,
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildImageSection(),
                  info,
                ],
              );
            },
          ),
        );
      },
    );
  }
}
