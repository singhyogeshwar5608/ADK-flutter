import 'package:flutter/material.dart';

import '../state/profile_state.dart';
import 'all_products_screen.dart';
import 'profile_screen.dart';

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
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
              top:
                  BorderSide(color: theme.dividerColor.withValues(alpha: 0.6))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FooterNavItem(
              icon: Icons.home_filled,
              label: 'Home',
              onTap: () => Navigator.of(context).pushReplacementNamed('/'),
            ),
            _FooterNavItem(
              icon: Icons.grid_view,
              label: 'Shop',
              onTap: () =>
                  Navigator.of(context).pushNamed(AllProductsScreen.routeName),
            ),
            _FooterNavItem(
              icon: Icons.shopping_bag_outlined,
              label: 'Cart',
              onTap: () => Navigator.of(context).pushNamed('/cart'),
            ),
            _FooterNavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () =>
                  Navigator.of(context).pushNamed(ProfileScreen.routeName),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterNavItem extends StatelessWidget {
  const _FooterNavItem(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: theme.colorScheme.onSurface),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _WalletHeroCard(),
          SizedBox(height: 20),
          _WalletStatsRow(),
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

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B9DEE), Color(0xFF1A85D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
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
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '₹${balance.toStringAsFixed(2)}',
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
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
              const SizedBox(height: 12),
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
            const SizedBox(width: 12),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
