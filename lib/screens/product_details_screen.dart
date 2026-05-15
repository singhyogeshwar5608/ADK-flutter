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
import '../state/wishlist_state.dart';
import '../theme/app_theme.dart';
import '../utils/product_share.dart';
import '../widgets/product_card.dart';
import '../widgets/safe_network_image.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final Product product;

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

    final dynamicPriceData = product.calculateDynamicPrice('India', 'Haryana');

    final catalogState = ProductCatalogProvider.of(context);
    final sourceEntries = catalogState.entries;
    final relatedEntries =
        (sourceEntries.isNotEmpty ? sourceEntries : local_data.productCatalog)
            .where((entry) => entry.product.id != product.id)
            .take(6)
            .toList();

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
                        ImageCarousel(images: product.galleryImages),
                        const SizedBox(height: 20),
                        _TitleSection(product: product),
                        const SizedBox(height: 4),
                        PriceSection(
                          product: product,
                          dynamicPriceData: dynamicPriceData,
                        ),
                        const SizedBox(height: 16),
                        _ProductSummaryCard(
                          product: product,
                          quantity: _quantity,
                          maxQuantity: _maxOrderQuantity,
                          onQuantityChanged: _setQuantity,
                        ),
                        const SizedBox(height: 20),
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
            BottomActionBar(product: product, quantity: _quantity),
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
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Product Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    _CircleIconButton(
                      icon: Icons.share,
                      onPressed: () async {
                        final ok = await shareProductDetails(product);
                        if (!context.mounted) return;
                        if (!ok && kIsWeb) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Product details copied — paste to share '
                                '(image link included).',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
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
  const ImageCarousel({super.key, required this.images});

  final List<String> images;

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
        final imageHeight = (safeW * 0.54).clamp(158.0, 232.0);

        return SizedBox(
          height: imageHeight,
          width: safeW,
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _controller,
                    itemCount: images.length,
                    onPageChanged: (index) => setState(() => _current = index),
                    itemBuilder: (context, index) => SafeNetworkImage(
                      src: images[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white
                                  .withValues(alpha: isDark ? 0.03 : 0.06),
                              Colors.transparent,
                              Colors.black
                                  .withValues(alpha: isDark ? 0.14 : 0.07),
                            ],
                            stops: const [0.0, 0.42, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'BEST SELLER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (index) {
                          final isActive = index == _current;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isActive ? 18 : 6,
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primary
                                  : (isDark
                                      ? const Color(0xFF475569)
                                      : const Color(0xFFD1D5DB)),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/* ---------------------- TITLE SECTION ---------------------- */

class _TitleSection extends StatelessWidget {
  const _TitleSection({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            product.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -2),
          child: _WishlistHeartButton(product: product),
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
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: thumb.isNotEmpty
                      ? SafeNetworkImage(src: thumb, fit: BoxFit.cover)
                      : ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.35),
                          ),
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
    final finalPrice = dynamicPriceData['finalPrice'] as double;
    final gstType = dynamicPriceData['gstType'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '₹${finalPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            if (gstType.isNotEmpty)
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
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
          ],
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
                          fontSize: 13,
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

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.product,
    required this.quantity,
  });

  final Product product;
  final int quantity;

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
    final dividerColor = theme.brightness == Brightness.dark
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
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: const Color(0xFF0891B2).withValues(alpha: 0.12),
                    border: Border.all(
                      color: const Color(0xFF0891B2),
                      width: 1.2,
                    ),
                  ),
                  child: IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints.tightFor(width: 44, height: 44),
                    icon: const Icon(
                      Icons.add_shopping_cart,
                      color: Color(0xFF0891B2),
                      size: 17,
                    ),
                    onPressed: () {
                      CartProvider.of(context, listen: false)
                          .addProduct(product, quantity: quantity);
                      _showSnackBar(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ScaleOnPress(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        CustomerDetailsScreen.routeName,
                        arguments: CheckoutArguments(
                          product: product,
                          quantity: quantity,
                        ),
                      );
                    },
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.26),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Buy Now',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
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
  final VoidCallback onPressed;

  @override
  State<_ScaleOnPress> createState() => _ScaleOnPressState();
}

class _ScaleOnPressState extends State<_ScaleOnPress> {
  bool _pressed = false;

  void _setPressed(bool value) {
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
