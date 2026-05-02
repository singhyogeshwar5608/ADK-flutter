import 'package:flutter/material.dart';

import '../state/cart_state.dart';
import '../widgets/safe_network_image.dart';
import 'all_products_screen.dart';
import 'customer_details_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          const SizedBox(height: 24),
                          _ImpactSummary(
                            isDark: isDark,
                            theme: theme,
                            totalBv: cart.totalBv,
                          ),
                          const SizedBox(height: 24),
                          _PricingSummary(
                            theme: theme,
                            colorScheme: colorScheme,
                            subtotal: cart.subtotal,
                            tax: cart.tax,
                            total: cart.total,
                            selectedSubtotal: cart.selectedSubtotal,
                            selectedTax: cart.selectedTax,
                            selectedShippingTotal: cart.selectedShippingTotal,
                            selectedTotal: cart.selectedTotal,
                            selectedItemsCount: cart.selectedItemsCount,
                            totalItems: cart.totalItems,
                            allItemsSelected: cart.allItemsSelected,
                            onSelectAll: cart.selectAll,
                            onDeselectAll: cart.deselectAll,
                          ),
                        ],
                      ),
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
          const SizedBox(height: 16),
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Selection checkbox
          Checkbox(
            value: item.isSelected,
            onChanged: (value) {
              onToggleSelection(item.product.id);
            },
            activeColor: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 72,
              height: 72,
              color: const Color(0xFFE2E8F0),
              child: SafeNetworkImage(
                src: item.product.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.trending_up,
                          size: 18, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Text(
                        '${item.product.bv} BV',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: const Color(0xFF10B981),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Price: ₹${item.product.price.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Shipping: ₹${item.product.shippingCharge.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.7)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF1F2933)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                _CounterButton(
                                  icon: Icons.remove,
                                  filled: false,
                                  colorScheme: colorScheme,
                                  onTap: () => onDecrement(item.product.id),
                                  isEnabled: item.quantity > 1,
                                ),
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    item.quantity.toString(),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                _CounterButton(
                                  icon: Icons.add,
                                  filled: true,
                                  colorScheme: colorScheme,
                                  onTap: () => onIncrement(item.product.id),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Remove button
                      GestureDetector(
                        onTap: () {
                          // Show confirmation dialog
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Remove Item'),
                                content: Text(
                                    'Are you sure you want to remove "${item.product.title}" from your cart?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      onRemove(item.product.id);
                                    },
                                    child: Text(
                                      'Remove',
                                      style:
                                          TextStyle(color: Colors.red.shade600),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Colors.red.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Remove',
                                style: TextStyle(
                                  color: Colors.red.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.icon,
    required this.filled,
    required this.colorScheme,
    required this.onTap,
    this.isEnabled = true,
  });

  final IconData icon;
  final bool filled;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? const Color(0xFF2B9DEE) : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: isEnabled ? onTap : null,
        child: SizedBox(
          height: 28,
          width: 28,
          child: Icon(
            icon,
            size: 16,
            color: filled
                ? Colors.white
                : isEnabled
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3),
          ),
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
    return Container(
      padding: const EdgeInsets.all(20),
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
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF2B9DEE),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.info_outline,
                      size: 16, color: Color(0xFF2B9DEE)),
                ],
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: 'Total BV Impact: ',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                  children: [
                    TextSpan(
                      text: '$totalBv BV',
                      style: const TextStyle(color: Color(0xFF2B9DEE)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This volume will be added to your weak leg upon order completion to optimize your commission payout.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
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
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.selectedSubtotal,
    required this.selectedTax,
    required this.selectedShippingTotal,
    required this.selectedTotal,
    required this.selectedItemsCount,
    required this.totalItems,
    required this.allItemsSelected,
    required this.onSelectAll,
    required this.onDeselectAll,
  });

  final ThemeData theme;
  final ColorScheme colorScheme;
  final double subtotal;
  final double tax;
  final double total;
  final double selectedSubtotal;
  final double selectedTax;
  final double selectedShippingTotal;
  final double selectedTotal;
  final int selectedItemsCount;
  final int totalItems;
  final bool allItemsSelected;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;

  @override
  Widget build(BuildContext context) {
    final divider = theme.brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF1F5F9);

    Widget row(String label, String value,
        {Color? valueColor, bool bold = false}) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: (bold
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.bodyMedium)
                ?.copyWith(
              color: valueColor ?? theme.colorScheme.onSurface,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      );
    }

    String format(double value) => '₹${value.toStringAsFixed(2)}';

    final cart = CartProvider.of(context, listen: false);

    return Column(
      children: [
        // Selection controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selected Items: $selectedItemsCount',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            TextButton(
              onPressed: allItemsSelected ? onDeselectAll : onSelectAll,
              child: Text(
                allItemsSelected ? 'Deselect All' : 'Select All',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Selected items pricing
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              row('Selected Subtotal', format(selectedSubtotal)),
              const SizedBox(height: 4),
              row('Selected Tax', format(selectedTax)),
              const SizedBox(height: 4),
              row('Shipping Charge', format(selectedShippingTotal)),
              const SizedBox(height: 8),
              Divider(color: divider.withValues(alpha: 0.5)),
              const SizedBox(height: 4),
              row('Selected Total', format(selectedTotal),
                  valueColor: colorScheme.primary, bold: true),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Overall totals
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF111827)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              row('Cart Subtotal', format(cart.subtotal)),
              const SizedBox(height: 4),
              row('Cart Shipping', format(cart.shippingTotal)),
              const SizedBox(height: 4),
              row('Cart Tax', format(cart.tax)),
              const SizedBox(height: 8),
              Divider(color: divider.withValues(alpha: 0.4)),
              const SizedBox(height: 4),
              row('Cart Total', format(cart.total), bold: true),
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
    final cart = CartProvider.of(context);
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: hasSelection
              ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B9DEE),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                    shadowColor: const Color(0xFF2B9DEE).withValues(alpha: 0.3),
                  ),
                  onPressed: () => Navigator.of(context)
                      .pushNamed(CustomerDetailsScreen.routeName),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Proceed to Checkout',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                    ],
                  ),
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.disabledColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_box_outline_blank,
                          size: 18, color: Colors.white70),
                      SizedBox(width: 8),
                      Text(
                        'Select items to checkout',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavItem(
                icon: Icons.home,
                label: 'Home',
                active: true,
                onTap: () => Navigator.of(context).pushReplacementNamed('/'),
              ),
              _NavItem(
                icon: Icons.grid_view,
                label: 'Shop',
                onTap: () => Navigator.of(context)
                    .pushNamed(AllProductsScreen.routeName),
              ),
              _NavItem(
                icon: Icons.account_balance_wallet,
                label: 'Wallet',
                onTap: () =>
                    Navigator.of(context).pushNamed(WalletScreen.routeName),
              ),
              _NavItem(
                icon: Icons.person,
                label: 'Profile',
                onTap: () =>
                    Navigator.of(context).pushNamed(ProfileScreen.routeName),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem(
      {required this.icon,
      required this.label,
      this.active = false,
      this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF2B9DEE) : Colors.grey;

    final content = Column(
      children: [
        Icon(icon, color: color, fill: active ? 1.0 : 0.0),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
      ],
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: content,
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
