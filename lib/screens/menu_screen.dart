import 'package:flutter/material.dart';

import '../screens/addresses_screen.dart';
import '../screens/media_listing_screen.dart';
import '../screens/adk_events_screen.dart';
import '../screens/product_catalogue_screen.dart';
import '../screens/delivery_center_screen.dart';
import '../screens/contact_us_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_conditions_screen.dart';
import '../theme/app_theme.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  static const routeName = '/menu';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _menuItems(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Quick Menu',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        itemBuilder: (context, index) => _MenuCard(item: items[index]),
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemCount: items.length,
      ),
    );
  }

  List<_MenuItem> _menuItems(BuildContext context) => [
        _MenuItem(
          title: 'Saved addresses',
          subtitle: 'Add, edit, and choose delivery addresses',
          icon: Icons.location_on_outlined,
          color: const Color(0xFF0EA5E9),
          onTap: () =>
              Navigator.of(context).pushNamed(AddressesScreen.routeName),
        ),
        _MenuItem(
          title: 'Media Gallery',
          subtitle: 'Upload & manage event visuals',
          icon: Icons.collections_bookmark,
          color: AppColors.primary,
          onTap: () =>
              Navigator.of(context).pushNamed(MediaListingScreen.routeName),
        ),
        _MenuItem(
          title: 'Product Catalogue',
          subtitle: 'Browse every product line',
          icon: Icons.inventory_2,
          color: const Color(0xFF6366F1),
          onTap: () =>
              Navigator.of(context).pushNamed(ProductCatalogueScreen.routeName),
        ),
        _MenuItem(
          title: 'Contact Us',
          subtitle: 'Reach support & success team',
          icon: Icons.support_agent,
          color: const Color(0xFF0EA5E9),
          onTap: () =>
              Navigator.of(context).pushNamed(ContactUsScreen.routeName),
        ),
        _MenuItem(
          title: 'ADK Events',
          subtitle: 'Upcoming meetups & webinars',
          icon: Icons.event_available,
          color: const Color(0xFFF97316),
          onTap: () =>
              Navigator.of(context).pushNamed(AdkEventsScreen.routeName),
        ),
        _MenuItem(
          title: 'Delivery Center',
          subtitle: 'Track and manage shipments',
          icon: Icons.local_shipping,
          color: const Color(0xFF10B981),
          onTap: () =>
              Navigator.of(context).pushNamed(DeliveryCenterScreen.routeName),
        ),
        _MenuItem(
          title: 'Privacy Policy',
          subtitle: 'How we handle your data',
          icon: Icons.privacy_tip_outlined,
          color: const Color(0xFF6366F1),
          onTap: () => Navigator.of(context)
              .pushNamed(PrivacyPolicyScreen.routeName),
        ),
        _MenuItem(
          title: 'Terms & Conditions',
          subtitle: 'Rules for using the app',
          icon: Icons.gavel_outlined,
          color: const Color(0xFF8B5CF6),
          onTap: () => Navigator.of(context)
              .pushNamed(TermsConditionsScreen.routeName),
        ),
      ];
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item});

  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleBase = theme.textTheme.titleMedium?.fontSize ?? 16;
    final titleSize = (titleBase - 3).clamp(10.0, 24.0);

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: item.color.withValues(alpha: 0.15),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: theme.dividerColor.withValues(alpha: isDark ? 0.3 : 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, color: item.color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700, fontSize: titleSize),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
