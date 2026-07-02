import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../data/product_catalog.dart' as local_data;
import '../models/product.dart';
import '../models/product_entry.dart';
import '../navigation/checkout_arguments.dart';
import 'customer_details_screen.dart';

import '../state/cart_state.dart';
import '../state/product_catalog_state.dart';
import '../state/profile_state.dart';
import '../state/wishlist_state.dart';
import '../theme/app_theme.dart';
import '../utils/product_share.dart';
import '../widgets/product_card.dart';
import '../widgets/safe_network_image.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final Product product;

  static const routeName = '/product-details';

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  late Product _product;
  late final ScrollController _scrollController;

  int get _maxOrderQuantity =>
      _product.stock > 0 ? _product.stock : 99;

  void _setQuantity(int value) {
    final clamped = value.clamp(1, _maxOrderQuantity);
    if (clamped == _quantity) return;
    setState(() => _quantity = clamped);
  }

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant ProductDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      _product = widget.product;
      _quantity = 1;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openRelatedProduct(Product product) {
    if (product.id == _product.id) return;
    setState(() {
      _product = product;
      _quantity = 1;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = _product;

    // Check if user is allowed to view this product
    final profileState = ProfileProvider.of(context);
    final isPartner = profileState.isAuthenticated && profileState.data.partnerId.trim().isNotEmpty;
    if (product.isMlm && !isPartner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Restricted')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'This product is reserved for MLM Partners.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please sign in as a partner to view this item.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final dynamicPriceData = product.calculateDynamicPrice('India', 'Haryana');

    final catalogState = ProductCatalogProvider.of(context);
    final sourceEntries = catalogState.entries;
    final relatedEntries =
        (sourceEntries.isNotEmpty ? sourceEntries : local_data.productCatalog)
            .where((entry) {
              // Filter out the current product and MLM products for guests
              if (entry.product.id == product.id) return false;
              if (entry.product.isMlm && !isPartner) return false;
              return true;
            })
            .take(6)
            .toList();
    final entry = sourceEntries.where((e) => e.product.id == product.id).firstOrNull;
    final brand = entry?.brand ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 96, 16, 96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ImageCarousel(images: product.galleryImages, product: product),
                        const SizedBox(height: 20),
                        _TitleSection(product: product, brand: brand),
                        const SizedBox(height: 4),
                        PriceSection(
                          product: product,
                          dynamicPriceData: dynamicPriceData,
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 12),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.brightness == Brightness.dark ? Colors.white60 : Colors.black54,
                            ),
                            children: [
                              const TextSpan(text: 'Net Content : '),
                              TextSpan(
                                text: product.sizeLabel.isNotEmpty ? product.sizeLabel : '1',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 16),
                        _DescriptionSection(description: product.description),
                        const SizedBox(height: 24),
                        RelatedProductsSection(
                          entries: relatedEntries,
                          onProductTap: _openRelatedProduct,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _StickyHeader(product: product),
            BottomActionBar(
              product: product,
              quantity: _quantity,
              onQuantityChanged: _setQuantity,
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------------- STICKY HEADER ---------------------- */

class _StickyHeader extends StatelessWidget {
  const _StickyHeader({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.surface;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.8),
                  border: Border(
                    bottom: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF1F2933)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _CircleIconButton(
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    _CircleIconButton(
                      icon: Icons.search,
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    ),
                    const SizedBox(width: 8),
                    _CircleIconButton(
                      icon: Icons.shopping_cart_outlined,
                      onPressed: () {
                        Navigator.pushNamed(context, '/cart');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 40,
      width: 40,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(icon, color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}

/* ---------------------- IMAGE CAROUSEL ---------------------- */

class ImageCarousel extends StatefulWidget {
  const ImageCarousel({super.key, required this.images, required this.product});

  final List<String> images;
  final Product product;

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  late final PageController _controller;
  int _current = 0;

  List<String> get _images =>
      widget.images.isNotEmpty ? widget.images : const [];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final images = _images.isNotEmpty ? _images : [''];

    const radius = 22.0;
    // Fixed visual height (not only aspect ratio) so the hero is clearly shorter than the old 1:1 square.
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final safeW = w.isFinite && w > 0 ? w : MediaQuery.sizeOf(context).width - 32;
        final imageHeight = (safeW * 0.95).clamp(250.0, 380.0);

        return SizedBox(
          height: imageHeight,
          width: safeW,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: images.length,
                onPageChanged: (index) => setState(() => _current = index),
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => _showFullscreenImage(context, images[index]),
                  child: SafeNetworkImage(
                    src: images[index],
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 60), // Spacer to balance share button
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F52BA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_current + 1}/${images.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (images.length > 1) ...[
                          const SizedBox(width: 6),
                          for (int i = 0; i < images.length; i++)
                            if (i != _current)
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE2E8F0),
                                  shape: BoxShape.circle,
                                ),
                              ),
                        ],
                      ],
                    ),
                    _ShareButton(product: widget.product),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFullscreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => _FullscreenImageDialog(imageUrl: imageUrl),
    );
  }
}

class _FullscreenImageDialog extends StatelessWidget {
  const _FullscreenImageDialog({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: SafeNetworkImage(
                  src: imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            right: 20,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------------- TITLE SECTION ---------------------- */

class _TitleSection extends StatelessWidget {
  const _TitleSection({required this.product, required this.brand});

  final Product product;
  final String brand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final brandName = brand.trim().toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (brandName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              brandName,
              textAlign: TextAlign.start,
              style: const TextStyle(
                color: Color(0xFF0F52BA),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                product.title,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _WishlistHeartButton(product: product),
          ],
        ),
      ],
    );
  }
}

class _WishlistHeartButton extends StatelessWidget {
  const _WishlistHeartButton({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final wishlist = WishlistProvider.of(context);
    final isWishlisted = wishlist.contains(product.id);

    return IconButton(
      tooltip: isWishlisted ? 'Remove from wishlist' : 'Save to wishlist',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      visualDensity: VisualDensity.compact,
      alignment: Alignment.center,
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () {
        final notifier = WishlistProvider.of(context, listen: false);
        if (notifier.contains(product.id)) {
          notifier.remove(product.id);
        } else {
          notifier.add(product);
        }
      },
      icon: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.favorite_border,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            size: 24,
          ),
          AnimatedScale(
            scale: isWishlisted ? 1 : 0.4,
            duration: const Duration(milliseconds: 200),
            curve: isWishlisted ? Curves.easeOutBack : Curves.easeIn,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isWishlisted ? 1 : 0,
              curve: Curves.easeInOut,
              child: const Icon(
                Icons.favorite,
                size: 21,
                color: Color(0xFFFF3B3B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------------- PRODUCT SUMMARY (qty + size) ---------------------- */

class _ProductSummaryCard extends StatelessWidget {
  const _ProductSummaryCard({
    required this.product,
    required this.quantity,
    required this.maxQuantity,
    required this.onQuantityChanged,
  });

  final Product product;
  final int quantity;
  final int maxQuantity;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.brightness == Brightness.dark
        ? const Color(0xFF1F2A37)
        : const Color(0xFFE2E8F0);
    final images = product.galleryImages;
    final thumb = images.isNotEmpty ? images.first : product.imageUrl;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 72,
                  height: 72,
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  child: thumb.isNotEmpty
                      ? SafeNetworkImage(src: thumb, fit: BoxFit.contain)
                      : Icon(
                          Icons.image_not_supported_outlined,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.35),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SummaryMetaRow(
                      label: 'Size',
                      value: product.sizeLabel,
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: borderColor,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Quantity',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _QuantityChipButton(
                icon: Icons.remove,
                enabled: quantity > 1,
                onPressed: () => onQuantityChanged(quantity - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  '$quantity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _QuantityChipButton(
                icon: Icons.add,
                enabled: quantity < maxQuantity,
                onPressed: () => onQuantityChanged(quantity + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetaRow extends StatelessWidget {
  const _SummaryMetaRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuantityChipButton extends StatelessWidget {
  const _QuantityChipButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: enabled
          ? AppColors.primary.withValues(alpha: 0.12)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? AppColors.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.25),
          ),
        ),
      ),
    );
  }
}

/* ---------------------- PRICE SECTION ---------------------- */

class PriceSection extends StatelessWidget {
  const PriceSection({
    super.key,
    required this.product,
    required this.dynamicPriceData,
  });

  final Product product;
  final Map<String, dynamic> dynamicPriceData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final finalPrice = dynamicPriceData['finalPrice'] as double;
    final gstType = dynamicPriceData['gstType'] as String;
    final discountPercent = product.discountPercentage;
    final hasDiscount = discountPercent > 0;
    final savedAmount = product.totalPrice - finalPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        if (hasDiscount)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text(
                  '₹${product.totalPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 15,
                    color: (isDark ? Colors.white60 : Colors.black54),
                    decoration: TextDecoration.lineThrough,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${discountPercent.round()}% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                children: [
                  TextSpan(text: hasDiscount ? 'Price : ' : 'M.R.P. : '),
                  TextSpan(
                    text: '₹${finalPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${product.bv} BV',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.info_outline,
                    size: 13,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            if (gstType.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  gstType,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ]
          ],
        ),
        const SizedBox(height: 6),
        if (hasDiscount && savedAmount > 0)
          Text(
            'You save ₹${savedAmount.toStringAsFixed(0)} (${discountPercent.round()}% off)',
            style: const TextStyle(
              color: Color(0xFF059669),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        const SizedBox(height: 4),
        const Text(
          'Inclusive of all taxes',
          style: TextStyle(
            color: Color(0xFF15803D),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/* ---------------------- DESCRIPTION SECTION ---------------------- */

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Parse the markdown-like description into stylish blocks
    final blocks = _parseDescription(description);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        ...blocks.map((block) => _buildDescriptionBlock(context, block)),
      ],
    );
  }

  List<_DescriptionBlock> _parseDescription(String text) {
    final lines = text.split('\n');
    final List<_DescriptionBlock> blocks = [];
    _DescriptionBlock? currentBlock;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Handle Section Headers (### **Title**)
      if (line.startsWith('###')) {
        final title = line.replaceAll('#', '').replaceAll('*', '').trim();
        currentBlock = _DescriptionBlock(title: title, items: []);
        blocks.add(currentBlock);
        continue;
      }

      // Handle Key Benefits or bold titles (**Title**)
      if (line.startsWith('**') && line.endsWith('**')) {
        final title = line.replaceAll('*', '').trim();
        currentBlock = _DescriptionBlock(title: title, items: []);
        blocks.add(currentBlock);
        continue;
      }

      // Handle List Items (* Item)
      if (line.startsWith('*')) {
        final item = line.substring(1).replaceAll('*', '').trim();
        if (currentBlock == null) {
          currentBlock = _DescriptionBlock(title: '', items: []);
          blocks.add(currentBlock);
        }
        currentBlock.items.add(item);
      } else if (line != '---') {
        // Handle plain text
        if (currentBlock == null) {
          currentBlock = _DescriptionBlock(title: '', items: []);
          blocks.add(currentBlock);
        }
        currentBlock.items.add(line);
      }
    }

    return blocks;
  }

  Widget _buildDescriptionBlock(BuildContext context, _DescriptionBlock block) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (block.title.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    block.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          ...block.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (block.items.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, right: 10),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        item,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          height: 1.5,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _DescriptionBlock {
  _DescriptionBlock({required this.title, required this.items});
  final String title;
  final List<String> items;
}

/* ---------------------- BOTTOM ACTION BAR (FIXED _showSnackBar) ---------------------- */

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        await shareProductDetails(product);
      },
      icon: const Icon(Icons.share, size: 14, color: Color(0xFF0F52BA)),
      label: const Text(
        'Share',
        style: TextStyle(
          color: Color(0xFF0F52BA),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: const Color(0xFFF8FAFC),
      ),
    );
  }
}

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
  });

  final Product product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  void _showSnackBar(BuildContext context) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'This item has been added to your cart.',
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor = isDark
        ? const Color(0xFF1F2933)
        : const Color(0xFFE2E8F0);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: dividerColor)),
            ),
            child: Row(
              children: [
                Text(
                  'Quantity: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF0F52BA), width: 1.2),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: quantity.clamp(1, 10),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0F52BA), size: 18),
                      style: const TextStyle(
                        color: Color(0xFF0F52BA),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      onChanged: (val) {
                        if (val != null) {
                          onQuantityChanged(val);
                        }
                      },
                      items: List.generate(
                        10,
                        (index) => DropdownMenuItem<int>(
                          value: index + 1,
                          child: Text('${index + 1}'),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ScaleOnPress(
                    onPressed: product.isComingSoon
                        ? null
                        : () {
                            CartProvider.of(context, listen: false)
                                .addProduct(product, quantity: quantity);
                            _showSnackBar(context);
                          },
                    child: Container(
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: product.isComingSoon
                            ? theme.disabledColor
                            : const Color(0xFF0F52BA),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: product.isComingSoon
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(0xFF0F52BA).withValues(alpha: 0.26),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Add to Cart',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------------- SCALE ON PRESS ---------------------- */

class _ScaleOnPress extends StatefulWidget {
  const _ScaleOnPress({required this.child, required this.onPressed});

  final Widget child;
  final VoidCallback? onPressed;

  @override
  State<_ScaleOnPress> createState() => _ScaleOnPressState();
}

class _ScaleOnPressState extends State<_ScaleOnPress> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null) return;
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class RelatedProductsSection extends StatelessWidget {
  const RelatedProductsSection({
    super.key,
    required this.entries,
    required this.onProductTap,
  });

  final List<ProductCatalogEntry> entries;
  final void Function(Product product) onProductTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Related Products",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 290,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              const spacing = 16.0;
              final itemWidth = (availableWidth - spacing) / 2;
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(width: spacing),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return SizedBox(
                    width: itemWidth,
                    child: ProductCard(
                      product: entry.product,
                      rating: entry.rating,
                      onProductTap: () => onProductTap(entry.product),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
