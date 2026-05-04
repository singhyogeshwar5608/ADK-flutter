import 'package:flutter/material.dart';

import '../screens/all_products_screen.dart';
import '../screens/menu_screen.dart';
import '../screens/wallet_screen.dart';
import '../screens/wishlist_screen.dart';
import '../state/wishlist_state.dart';
import 'nav_item_with_badge.dart';

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
                  child: NavItemWithBadge(
                    badgeCount: 0,
                    icon: Icons.home_rounded,
                    label: 'Home',
                    tint: BottomNavColors.homeProducts,
                    iconSize: 24,
                    fontSize: 11.5,
                    onTap: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ),
                Expanded(
                  child: NavItemWithBadge(
                    badgeCount: 0,
                    icon: Icons.inventory_2_rounded,
                    label: 'Products',
                    tint: BottomNavColors.homeProducts,
                    iconSize: 24,
                    fontSize: 11.5,
                    onTap: () => Navigator.of(context)
                        .pushNamed(AllProductsScreen.routeName),
                  ),
                ),
                Expanded(
                  child: NavItemWithBadge(
                    badgeCount: WishlistProvider.of(context).items.length,
                    icon: Icons.favorite_border_rounded,
                    label: 'Wishlist',
                    tint: BottomNavColors.wishlist,
                    iconSize: 24,
                    fontSize: 11.5,
                    onTap: () => Navigator.of(context)
                        .pushNamed(WishlistScreen.routeName),
                  ),
                ),
                Expanded(
                  child: NavItemWithBadge(
                    badgeCount: 0,
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Wallet',
                    tint: BottomNavColors.wallet,
                    iconSize: 24,
                    fontSize: 11.5,
                    onTap: () => Navigator.of(context)
                        .pushNamed(WalletScreen.routeName),
                  ),
                ),
                Expanded(
                  child: NavItemWithBadge(
                    badgeCount: 0,
                    icon: Icons.menu_rounded,
                    label: 'Menu',
                    tint: BottomNavColors.menu,
                    iconSize: 24,
                    fontSize: 11.5,
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
