import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_theme.dart';
import '../models/product.dart';
import '../screens/product_details_screen.dart';
import '../state/cart_state.dart';
import '../state/wishlist_state.dart';
import '../widgets/safe_network_image.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  static const routeName = '/wishlist';

  static Future<void> shareItems(BuildContext context, List<Product> items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add items to your wishlist to share.')),
      );
      return;
    }
    final buffer = StringBuffer('My wishlist (${items.length} items)\n\n');
    for (var i = 0; i < items.length; i++) {
      final p = items[i];
      buffer.writeln(
        '${i + 1}. ${p.title} — ₹${p.price.toStringAsFixed(2)} · ${p.bv} BV',
      );
    }
    await Share.share(buffer.toString(), subject: 'My wishlist');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wishlistState = WishlistProvider.of(context);
    final favorites = wishlistState.items;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Wishlist'),
        actions: [
          if (favorites.isNotEmpty)
            TextButton(
              onPressed: () => _promptClearWishlist(context),
              child: Text(
                'Clear all',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          IconButton(
            tooltip: 'Share wishlist',
            icon: const Icon(Icons.share_outlined),
            onPressed: () async {
              final items =
                  WishlistProvider.of(context, listen: false).items;
              await shareItems(context, items);
            },
          ),
        ],
      ),
      body: favorites.isEmpty
          ? _EmptyWishlist(theme: theme)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final product = favorites[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Dismissible(
                    key: ValueKey(product.id),
                    background: _buildDismissBackground(context, true),
                    secondaryBackground: _buildDismissBackground(context, false),
                    onDismissed: (direction) {
                      final wishlist = WishlistProvider.of(context, listen: false);
                      final cart = CartProvider.of(context, listen: false);
                      if (direction == DismissDirection.endToStart) {
                        cart.addProduct(product);
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text(
                                  'This item has been moved to your cart.'),
                            ),
                          );
                      } else {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(content: Text('${product.title} removed from wishlist')),
                          );
                      }
                      wishlist.remove(product.id);
                    },
                    child: _WishlistCard(
                      product: product,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsScreen(product: product),
                        ),
                      ),
                      onRemove: () => _promptRemoveWishlistItem(context, product),
                    ),
                  ),
                );
              },
            ),
    );
  }

  static Future<void> _promptRemoveWishlistItem(
      BuildContext context, Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove item'),
        content: Text('Remove "${product.title}" from your wishlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Remove',
              style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await WishlistProvider.of(context, listen: false).remove(product.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Removed from wishlist.'),
      ),
    );
  }

  static Future<void> _promptClearWishlist(BuildContext context) async {
    final wishlist = WishlistProvider.of(context, listen: false);
    if (wishlist.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear wishlist'),
        content: Text(
          'Remove all ${wishlist.items.length} ${wishlist.items.length == 1 ? 'item' : 'items'} from your wishlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Clear all',
              style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await wishlist.clearAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Wishlist cleared.'),
      ),
    );
  }

  Widget _buildDismissBackground(BuildContext context, bool isLeft) {
    return Container(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isLeft ? Colors.redAccent : AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        isLeft ? Icons.delete_outline : Icons.shopping_cart,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

class _EmptyWishlist extends StatelessWidget {
  const _EmptyWishlist({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Wishlist is empty',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Save items you love to easily find them later and share with your network.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : const Color(0xFF475569),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Start Shopping'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  const _WishlistCard({
    required this.product,
    required this.onTap,
    required this.onRemove,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final showFullLabel = width >= 420;
    final ctaLabel = showFullLabel ? 'Add to Cart' : 'Add';
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(18)),
                child: SafeNetworkImage(
                  src: product.imageUrl,
                  width: 108,
                  height: 108,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(12, 10, 4, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize:
                              (theme.textTheme.titleMedium?.fontSize ?? 16) -
                                  3,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              '₹${product.price.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: (theme
                                            .textTheme.titleMedium?.fontSize ??
                                        16) -
                                    2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                CartProvider.of(context, listen: false)
                                    .addProduct(product);
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    const SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      content: Text(
                                        'This item has been added to your cart.',
                                      ),
                                    ),
                                  );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF06B6D4),
                                      Color(0xFF0891B2),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0891B2)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: showFullLabel ? 10 : 8,
                                  vertical: 7,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.add_shopping_cart_rounded,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      ctaLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11.5,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 2),
              child: IconButton(
                tooltip: 'Remove from wishlist',
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red.shade400,
                  size: 22,
                ),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                onPressed: onRemove,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
