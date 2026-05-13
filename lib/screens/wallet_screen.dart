import 'package:flutter/material.dart';

import '../state/profile_state.dart';
import 'all_products_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'withdraw_screen.dart';

/// Wallet-only bottom bar palette (distinct from [BottomNavColors] on Home).
abstract final class WalletFooterNavColors {
  static const Color home = Color(0xFF6366F1); // Indigo
  static const Color shop = Color(0xFF0D9488); // Teal
  static const Color cart = Color(0xFFEC4899); // Pink
  static const Color withdraw = Color(0xFFC2410C); // Burnt orange
  static const Color profile = Color(0xFF9333EA); // Purple
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  static const routeName = '/wallet';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF101A22) : const Color(0xFFF6F7F8);

    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: const _WalletFooter(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 1024
                ? 72.0
                : constraints.maxWidth >= 768
                    ? 56.0
                    : constraints.maxWidth >= 540
                        ? 32.0
                        : 16.0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _WalletHeader(),
                Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: const _WalletBody(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WalletFooter extends StatelessWidget {
  const _WalletFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final barColor =
        isDark ? theme.colorScheme.surface : Colors.white;

    return Material(
      color: barColor,
      elevation: isDark ? 0 : 8,
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
                  child: _WalletFooterNavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    tint: WalletFooterNavColors.home,
                    onTap: () =>
                        Navigator.of(context).pushReplacementNamed('/'),
                  ),
                ),
                Expanded(
                  child: _WalletFooterNavItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Shop',
                    tint: WalletFooterNavColors.shop,
                    onTap: () => Navigator.of(context)
                        .pushNamed(AllProductsScreen.routeName),
                  ),
                ),
                Expanded(
                  child: _WalletFooterNavItem(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Cart',
                    tint: WalletFooterNavColors.cart,
                    onTap: () =>
                        Navigator.of(context).pushNamed(CartScreen.routeName),
                  ),
                ),
                Expanded(
                  child: _WalletFooterNavItem(
                    icon: Icons.payments_rounded,
                    label: 'Withdraw',
                    tint: WalletFooterNavColors.withdraw,
                    onTap: () => Navigator.of(context)
                        .pushNamed(WithdrawScreen.routeName),
                  ),
                ),
                Expanded(
                  child: _WalletFooterNavItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    tint: WalletFooterNavColors.profile,
                    onTap: () => Navigator.of(context)
                        .pushNamed(ProfileScreen.routeName),
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

class _WalletFooterNavItem extends StatelessWidget {
  const _WalletFooterNavItem({
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

class _WalletHeader extends StatelessWidget {
  const _WalletHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final border = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(bottom: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _CircleIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.of(context).maybePop()),
          Expanded(
            child: Text(
              'Wallet',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _WalletBody extends StatelessWidget {
  const _WalletBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _WalletHeroCard(),
          const SizedBox(height: 12),
          const _WalletStatsRow(),
        ],
      ),
    );
  }
}

class _WalletHeroCard extends StatelessWidget {
  const _WalletHeroCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ProfileProvider.of(context).data;
    final balance = profile.walletBalance ?? 0.0;

    final titleStyle = theme.textTheme.labelSmall;
    final balanceStyle = theme.textTheme.displaySmall;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B9DEE), Color(0xFF1A85D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B9DEE).withValues(alpha: 0.25),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Balance',
            style: titleStyle?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 1.1,
              fontSize: (titleStyle.fontSize ?? 12) - 3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${balance.toStringAsFixed(2)}',
            style: balanceStyle?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: (balanceStyle.fontSize ?? 36) - 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletStatsRow extends StatelessWidget {
  const _WalletStatsRow();

  @override
  Widget build(BuildContext context) {
    final profile = ProfileProvider.of(context).data;
    final totalEarnings = profile.totalIncome;
    final currentBalance = profile.walletBalance ?? 0.0;
    final withdrawals = totalEarnings - currentBalance;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 412) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WalletStatTile(
                title: 'Total Earnings',
                amount: '₹${totalEarnings.toStringAsFixed(2)}',
                subtitle: 'Lifetime earnings',
              ),
              const SizedBox(height: 8),
              _WalletStatTile(
                title: 'Withdrawals',
                amount: '₹${withdrawals.toStringAsFixed(2)}',
                subtitle: 'Total withdrawn',
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: _WalletStatTile(
                title: 'Total Earnings',
                amount: '₹${totalEarnings.toStringAsFixed(2)}',
                subtitle: 'Lifetime earnings',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _WalletStatTile(
                title: 'Withdrawals',
                amount: '₹${withdrawals.toStringAsFixed(2)}',
                subtitle: 'Total withdrawn',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WalletStatTile extends StatelessWidget {
  const _WalletStatTile(
      {required this.title, required this.amount, required this.subtitle});

  final String title;
  final String amount;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleSmall = theme.textTheme.labelSmall;
    final headline = theme.textTheme.headlineSmall;
    final subStyle = theme.textTheme.bodySmall;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 0.6,
              fontSize: (titleSmall.fontSize ?? 12) - 3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: headline?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: (headline.fontSize ?? 24) - 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: subStyle?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: (subStyle.fontSize ?? 12) - 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      ),
    );
  }
}
