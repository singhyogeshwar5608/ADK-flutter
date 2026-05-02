import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/product.dart';
import '../screens/product_details_screen.dart';
import '../state/cart_state.dart';
import '../state/wishlist_state.dart';
import '../widgets/safe_network_image.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  static const routeName = '/wishlist';

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
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share'),
          ),
          const SizedBox(width: 12),
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
                            SnackBar(content: Text('${product.title} moved to cart')),
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
                    ),
                  ),
                );
              },
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
  const _WishlistCard({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final showFullLabel = width >= 420;
    final ctaLabel = showFullLabel ? 'Add to Cart' : 'Add';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
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
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                child: SafeNetworkImage(
                  src: product.imageUrl,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${product.price.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                          ),
                          FilledButton.icon(
                            onPressed: () {
                              CartProvider.of(context, listen: false).addProduct(product);
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(content: Text('${product.title} added to cart')),
                                );
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              backgroundColor: theme.colorScheme.primary,
                            ),
                            icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                            label: Text(ctaLabel),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
