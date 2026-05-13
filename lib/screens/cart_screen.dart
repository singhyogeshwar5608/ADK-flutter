import 'package:flutter/material.dart';

import '../services/address_storage_service.dart';
import '../state/cart_state.dart';
import '../state/profile_state.dart';
import '../theme/app_theme.dart';
import '../widgets/safe_network_image.dart';
import 'all_products_screen.dart';
import 'customer_details_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';

/// Cart footer nav tints — different palette than the main home tab bar.
abstract final class _CartFooterNavColors {
  static const Color home = Color(0xFF059669);
  static const Color shop = Color(0xFFF59E0B);
  static const Color wallet = Color(0xFF7C3AED);
  static const Color profile = Color(0xFFE11D48);
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const routeName = '/cart';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cart = CartProvider.of(context);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF101A22) : const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              child: Column(
                children: [
                  _Header(
                    colorScheme: colorScheme,
                    theme: theme,
                    onClear: cart.clear,
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final gutterX = constraints.maxWidth * 0.01;
                        return SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            gutterX,
                            24,
                            gutterX,
                            24,
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: FractionallySizedBox(
                              widthFactor: 0.98,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _CartList(
                                    isDark: isDark,
                                    colorScheme: colorScheme,
                                    items: cart.items,
                                    onIncrement: cart.increment,
                                    onDecrement: cart.decrement,
                                    onToggleSelection: cart.toggleSelection,
                                    onRemove: cart.removeItem,
                                  ),
                                  const SizedBox(height: 20),
                                  _ImpactSummary(
                                    isDark: isDark,
                                    theme: theme,
                                    totalBv: cart.selectedTotalBv,
                                  ),
                                  const SizedBox(height: 20),
                                  _PricingSummary(
                                    theme: theme,
                                    colorScheme: colorScheme,
                                    selectedSubtotal: cart.selectedSubtotal,
                                    selectedTax: cart.selectedTax,
                                    selectedShippingTotal:
                                        cart.selectedShippingTotal,
                                    selectedTotal: cart.selectedTotal,
                                    selectedItemsCount:
                                        cart.selectedItemsCount,
                                    totalItems: cart.totalItems,
                                    allItemsSelected: cart.allItemsSelected,
                                    onSelectAll: cart.selectAll,
                                    onDeselectAll: cart.deselectAll,
                                    selectedTotalGst: cart.selectedTotalGst,
                                    cart: cart,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _Footer(
                    colorScheme: colorScheme,
                    theme: theme,
                    payableTotal: cart.selectedTotal,
                    selectedItemsCount: cart.selectedItemsCount,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(
      {required this.colorScheme, required this.theme, required this.onClear});

  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final divider = theme.brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);

    return ClipRect(
      child: Container(
        decoration: BoxDecoration(
          color: (theme.brightness == Brightness.dark
                  ? const Color(0xFF0F172A)
                  : Colors.white)
              .withValues(alpha: 0.8),
          border: Border(bottom: BorderSide(color: divider)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _CircleIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.of(context).maybePop(),
              color: theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Shopping Cart',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: onClear,
              child: Text(
                'Clear All',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF2B9DEE),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartList extends StatelessWidget {
  const _CartList({
    required this.isDark,
    required this.colorScheme,
    required this.items,
    required this.onIncrement,
    required this.onDecrement,
    required this.onToggleSelection,
    required this.onRemove,
  });

  final bool isDark;
  final ColorScheme colorScheme;
  final List<CartItem> items;
  final void Function(String productId) onIncrement;
  final void Function(String productId) onDecrement;
  final void Function(String productId) onToggleSelection;
  final void Function(String productId) onRemove;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 48, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'Your cart is empty',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Add items to see them here with BV impact and totals.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final item in items) ...[
          _CartItemCard(
            item: item,
            isDark: isDark,
            colorScheme: colorScheme,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
            onToggleSelection: onToggleSelection,
            onRemove: onRemove,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.isDark,
    required this.colorScheme,
    required this.onIncrement,
    required this.onDecrement,
    required this.onToggleSelection,
    required this.onRemove,
  });

  final CartItem item;
  final bool isDark;
  final ColorScheme colorScheme;
  final void Function(String productId) onIncrement;
  final void Function(String productId) onDecrement;
  final void Function(String productId) onToggleSelection;
  final void Function(String productId) onRemove;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9);
    final tt = Theme.of(context).textTheme;
    final titleBase = tt.titleMedium;
    final titleStyle = titleBase?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: (titleBase.fontSize ?? 16) - 6,
      height: 1.25,
    );
    final priceBase = tt.titleMedium;
    final priceStyle = priceBase?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: (priceBase.fontSize ?? 16) - 5,
    );
    final shipBase = tt.bodySmall;
    final shipStyle = shipBase?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      fontSize: (shipBase.fontSize ?? 12) - 3,
    );
    final bvBase = tt.labelMedium;
    final bvStyle = bvBase?.copyWith(
      color: const Color(0xFF10B981),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      fontSize: (bvBase.fontSize ?? 12) - 2,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            value: item.isSelected,
            onChanged: (value) => onToggleSelection(item.product.id),
            activeColor: colorScheme.primary,
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: () {
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) {
                  final media = MediaQuery.sizeOf(dialogContext);
                  final theme = Theme.of(dialogContext);
                  return Dialog(
                    insetPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: Container(
                      width: media.width * 0.9,
                      height: media.height * 0.65,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header with close button
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                topRight: Radius.circular(18),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.product.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(),
                                  icon: Icon(
                                    Icons.close,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Product image
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: ColoredBox(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  child: SafeNetworkImage(
                                    src: item.product.imageUrl,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Product details
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Price:',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '₹${item.product.price.toStringAsFixed(2)}',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Quantity:',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total:',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '₹${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
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
                  );
                },
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 68,
                height: 68,
                child: ColoredBox(
                  color: const Color(0xFFE2E8F0),
                  child: SafeNetworkImage(
                    src: item.product.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.title,
                    style: titleStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.trending_up,
                          size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${item.product.bv} BV',
                          style: bvStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price: ₹${item.product.price.toStringAsFixed(2)} × ${item.quantity}',
                              style: priceStyle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ship: ₹${item.product.shippingCharge.toStringAsFixed(2)} ea.',
                              style: shipStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _QuantityControl(
                        colorScheme: colorScheme,
                        isDark: isDark,
                        quantity: item.quantity,
                        onIncrement: () => onIncrement(item.product.id),
                        onDecrement: () => onDecrement(item.product.id),
                        decrementEnabled: item.quantity > 1,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: GestureDetector(
                      onTap: () {
                        showDialog<void>(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            final dt = Theme.of(dialogContext).textTheme;
                            final titleFont = dt.titleLarge;
                            final bodyFont = dt.bodyMedium;
                            final btnFont = dt.labelLarge;
                            return AlertDialog(
                              title: Text(
                                'Remove Item',
                                style: titleFont?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize:
                                      (titleFont.fontSize ?? 22) - 3,
                                ),
                              ),
                              content: Text(
                                'Remove "${item.product.title}" from your cart?',
                                style: bodyFont?.copyWith(
                                  fontSize:
                                      (bodyFont.fontSize ?? 14) - 3,
                                  height: 1.35,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  child: Text(
                                    'Cancel',
                                    style: btnFont?.copyWith(
                                      fontSize:
                                          (btnFont.fontSize ?? 14) - 3,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    onRemove(item.product.id);
                                  },
                                  child: Text(
                                    'Remove',
                                    style: btnFont?.copyWith(
                                      fontSize:
                                          (btnFont.fontSize ?? 14) - 3,
                                      color: Colors.red.shade600,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 14,
                              color: Colors.red.shade600,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Remove',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.colorScheme,
    required this.isDark,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.decrementEnabled,
  });

  final ColorScheme colorScheme;
  final bool isDark;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool decrementEnabled;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final iconColor = colorScheme.primary;
    final muted = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: decrementEnabled ? 0.75 : 0.28);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyStrokeButton(
            icon: Icons.remove,
            enabled: decrementEnabled,
            iconColor: muted,
            size: 24,
            onTap: decrementEnabled ? onDecrement : null,
          ),
          SizedBox(
            width: 22,
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize:
                        (Theme.of(context).textTheme.labelMedium?.fontSize ??
                                13) -
                            1,
                  ),
            ),
          ),
          _QtyStrokeButton(
            icon: Icons.add,
            enabled: true,
            iconColor: iconColor,
            size: 24,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _QtyStrokeButton extends StatelessWidget {
  const _QtyStrokeButton({
    required this.icon,
    required this.enabled,
    required this.iconColor,
    required this.size,
    this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final Color iconColor;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.46, color: iconColor),
        ),
      ),
    );
  }
}

class _ImpactSummary extends StatelessWidget {
  const _ImpactSummary(
      {required this.isDark, required this.theme, required this.totalBv});

  final bool isDark;
  final ThemeData theme;
  final int totalBv;

  @override
  Widget build(BuildContext context) {
    final badge =
        theme.textTheme.labelSmall;
    final ttl = theme.textTheme.titleLarge;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2B9DEE).withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: const Color(0xFF2B9DEE).withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Icon(Icons.account_tree,
                size: 64,
                color: const Color(0xFF2B9DEE).withValues(alpha: 0.15)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'NETWORK IMPACT',
                    style: badge?.copyWith(
                      color: const Color(0xFF2B9DEE),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontSize: (badge.fontSize ?? 11) - 4,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.info_outline,
                      size: ((theme.iconTheme.size ?? 24) - 5).clamp(12.0, 22.0),
                      color: const Color(0xFF2B9DEE)),
                ],
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  text: 'Total BV Impact: ',
                  style: ttl?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: (ttl.fontSize ?? 22) - 8,
                  ),
                  children: [
                    TextSpan(
                      text: '$totalBv BV',
                      style: const TextStyle(color: Color(0xFF2B9DEE)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'This volume will be added to your weak leg upon order completion to optimize your commission payout.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.45,
                  fontSize:
                      (theme.textTheme.bodySmall?.fontSize ?? 12) - 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PricingSummary extends StatelessWidget {
  const _PricingSummary({
    required this.theme,
    required this.colorScheme,
    required this.selectedSubtotal,
    required this.selectedTax,
    required this.selectedShippingTotal,
    required this.selectedTotal,
    required this.selectedItemsCount,
    required this.totalItems,
    required this.allItemsSelected,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.selectedTotalGst,
    required this.cart,
  });

  final ThemeData theme;
  final ColorScheme colorScheme;
  final double selectedSubtotal;
  final double selectedTax;
  final double selectedShippingTotal;
  final double selectedTotal;
  final int selectedItemsCount;
  final int totalItems;
  final bool allItemsSelected;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final double selectedTotalGst;
  final CartState cart;

  @override
  Widget build(BuildContext context) {
    final divider = theme.brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);

    Widget row(String label, String value,
        {Color? valueColor, bool bold = false}) {
      final labelStyle = theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
        height: 1.2,
      );
      final valBase = bold ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium;
      final valStyle = valBase?.copyWith(
        color: valueColor ?? theme.colorScheme.onSurface,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
        fontSize: (valBase?.fontSize ?? 16) - 2,
        height: 1.2,
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 12,
              child: Text(label, style: labelStyle),
            ),
            Expanded(
              flex: 10,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: valStyle,
              ),
            ),
          ],
        ),
      );
    }

    String format(double value) => '₹${value.toStringAsFixed(2)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                '$selectedItemsCount of $totalItems units selected',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: allItemsSelected ? onDeselectAll : onSelectAll,
              child: Text(
                allItemsSelected ? 'Deselect all' : 'Select all',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              row('Subtotal (selected)', format(selectedSubtotal)),
              row('Shipping', format(selectedShippingTotal)),
              Divider(
                  height: 16,
                  thickness: 1,
                  color: divider.withValues(alpha: 0.45)),
              row('Estimated total', format(selectedTotal),
                  valueColor: colorScheme.primary, bold: true),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.mlmGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.mlmGreen.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 14,
                      color: AppColors.mlmGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All prices include GST and applicable taxes',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mlmGreen,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.colorScheme,
    required this.theme,
    required this.payableTotal,
    required this.selectedItemsCount,
  });

  final ColorScheme colorScheme;
  final ThemeData theme;
  final double payableTotal;
  final int selectedItemsCount;

  @override
  Widget build(BuildContext context) {
    final divider = theme.brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);
    final hasSelection = selectedItemsCount > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          color: theme.scaffoldBackgroundColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Payable',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${payableTotal.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2B9DEE),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$selectedItemsCount item${selectedItemsCount == 1 ? '' : 's'} selected',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: divider)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: hasSelection
              ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B9DEE),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    minimumSize: const Size(double.infinity, 42),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 5,
                    shadowColor: const Color(0xFF2B9DEE).withValues(alpha: 0.28),
                  ),
                  onPressed: () async {
                    final profile =
                        ProfileProvider.of(context, listen: false).data;
                    final uid = profile.partnerId.trim().isEmpty
                        ? null
                        : profile.partnerId.trim();
                    final list =
                        await AddressStorageService.instance.listForUserId(uid);
                    if (!context.mounted) return;
                    if (list.isNotEmpty) {
                      final primary = AddressStorageService.instance
                          .pickPrimaryForCheckout(list);
                      final payload = primary.toShippingDetailsPayload();
                      await AddressStorageService.instance
                          .writeCheckoutShippingOverride(payload);
                      await AddressStorageService.instance
                          .markAddressUsed(primary.id, userId: uid);
                      if (!context.mounted) return;
                      await Navigator.of(context).pushNamed('/checkout',
                          arguments: payload);
                    } else {
                      await Navigator.of(context).pushNamed(
                          CustomerDetailsScreen.routeName);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Proceed to Checkout',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: (theme.textTheme.titleSmall?.fontSize ?? 14) - 2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward,
                          size: 17, color: Colors.white.withValues(alpha: 0.95)),
                    ],
                  ),
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.disabledColor,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    minimumSize: const Size(double.infinity, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_box_outline_blank,
                          size: 16, color: Colors.white70),
                      const SizedBox(width: 8),
                      Text(
                        'Select items to checkout',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          fontSize: (theme.textTheme.titleSmall?.fontSize ?? 14) - 2,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 16),
          child: Row(
            children: [
              Expanded(
                child: _CartFooterNavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  tint: _CartFooterNavColors.home,
                  onTap: () =>
                      Navigator.of(context).pushReplacementNamed('/'),
                ),
              ),
              Expanded(
                child: _CartFooterNavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Shop',
                  tint: _CartFooterNavColors.shop,
                  onTap: () => Navigator.of(context)
                      .pushNamed(AllProductsScreen.routeName),
                ),
              ),
              Expanded(
                child: _CartFooterNavItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Wallet',
                  tint: _CartFooterNavColors.wallet,
                  onTap: () =>
                      Navigator.of(context).pushNamed(WalletScreen.routeName),
                ),
              ),
              Expanded(
                child: _CartFooterNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  tint: _CartFooterNavColors.profile,
                  onTap: () =>
                      Navigator.of(context).pushNamed(ProfileScreen.routeName),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartFooterNavItem extends StatelessWidget {
  const _CartFooterNavItem({
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: tint.withValues(alpha: 0.14),
        highlightColor: tint.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: tint, size: 24),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.08,
                  color: tint,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton(
      {required this.icon, required this.onTap, required this.color});

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          width: 40,
          child: Icon(icon, color: color),
        ),
      ),
    );
  }
}
