import 'package:flutter/material.dart';

import '../models/product.dart';
import '../navigation/checkout_arguments.dart';
import '../screens/customer_details_screen.dart';
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
          final commissionPercent = widget.product.commissionPercent;
          final commissionLabel = commissionPercent > 0
              ? '${commissionPercent.round()}% OFF'
              : null;
          final images = _images;
          // [InkWell] only around the pager; wishlist sits above in paint/hit-test order so it receives taps first.
          Widget pageGallery = PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) => SizedBox.expand(
              child: SafeNetworkImage(
                src: images[index],
                fit: BoxFit.cover,
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
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Container(
                    color: theme.colorScheme.surface,
                    child: pageGallery,
                  ),
                ),
              ),
              Positioned(
                top: 12,
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
                top: 10,
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
              if (commissionLabel != null)
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mlmGreen.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      commissionLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
            ],
          );

          return AspectRatio(
            aspectRatio: isCompactCard ? 1 : 4 / 3,
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
        final priceStyle = theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: isCompactCard ? 14 : null,
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
          required VoidCallback onPressed,
          Color? filledBackgroundOverride,
        }) {
          final fillBg =
              filledBackgroundOverride ?? theme.colorScheme.primary;
          const fillFg = Colors.white;
          final labelStyle = TextStyle(
            fontSize: btnLabelSize,
            fontWeight: FontWeight.w700,
            color: filled ? fillFg : theme.colorScheme.primary,
          );
          final content = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(
                icon,
                size: btnIconSize,
                color: filled ? fillFg : theme.colorScheme.primary,
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
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: fillBg,
                foregroundColor: fillFg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide(color: theme.colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: content,
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.06 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Builder(
            builder: (context) {
              Widget info = Padding(
                padding: bodyPadding,
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
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '₹${originalPrice.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                            decoration: TextDecoration.lineThrough,
                            fontSize: isCompactCard ? 11 : 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '₹${widget.product.price.toStringAsFixed(2)}',
                            style: priceStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.token,
                              size: 16,
                              color: AppColors.mlmGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.product.bv} BV',
                              style: bvStyle,
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: buildActionButton(
                            filled: true,
                            icon: inCart
                                ? Icons.shopping_cart_rounded
                                : Icons.shopping_cart_outlined,
                            label: inCart ? 'In Cart' : 'Add to Cart',
                            filledBackgroundOverride: inCart
                                ? const Color(0xFF059669)
                                : const Color(0xFF0891B2),
                            onPressed: () {
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
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color:
                                            Colors.white.withValues(alpha: 0.98),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    backgroundColor:
                                        theme.colorScheme.inverseSurface,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                            },
                          ),
                        ),
                        SizedBox(width: isCompactCard ? 4 : 6),
                        Expanded(
                          child: buildActionButton(
                            filled: true,
                            icon: Icons.bolt_rounded,
                            label: 'Buy Now',
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                CustomerDetailsScreen.routeName,
                                arguments: CheckoutArguments(
                                  product: widget.product,
                                  quantity: 1,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
