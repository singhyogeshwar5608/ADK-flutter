import 'package:flutter/material.dart';

import '../screens/all_products_screen.dart';
import '../screens/menu_screen.dart';
import '../screens/wallet_screen.dart';
import '../screens/wishlist_screen.dart';

/// Brand colors for bottom nav (match reference screenshot).
abstract final class BottomNavColors {
  static const Color homeProducts = Color(0xFF0096D6);
  static const Color wishlist = Color(0xFFE91E63);
  static const Color wallet = Color(0xFFFF9800);
  static const Color menu = Color(0xFF9C27B0);
}

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    tint: BottomNavColors.homeProducts,
                    onTap: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.inventory_2_rounded,
                    label: 'Products',
                    tint: BottomNavColors.homeProducts,
                    onTap: () => Navigator.of(context)
                        .pushNamed(AllProductsScreen.routeName),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.favorite_border_rounded,
                    label: 'Wishlist',
                    tint: BottomNavColors.wishlist,
                    onTap: () => Navigator.of(context)
                        .pushNamed(WishlistScreen.routeName),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Wallet',
                    tint: BottomNavColors.wallet,
                    onTap: () => Navigator.of(context)
                        .pushNamed(WalletScreen.routeName),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.menu_rounded,
                    label: 'Menu',
                    tint: BottomNavColors.menu,
                    onTap: () =>
                        Navigator.of(context).pushNamed(MenuScreen.routeName),
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

class _NavItem extends StatelessWidget {
  const _NavItem({
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
        borderRadius: BorderRadius.circular(12),
        splashColor: tint.withValues(alpha: 0.12),
        highlightColor: tint.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: tint, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                  color: tint,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
