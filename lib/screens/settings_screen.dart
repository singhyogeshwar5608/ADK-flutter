import 'package:flutter/material.dart';

import '../state/theme_controller.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);
    final themeController = ThemeControllerProvider.maybeOf(context);
    final resolvedMode = themeController?.mode ?? ThemeMode.system;
    final isDarkMode = resolvedMode == ThemeMode.dark
        ? true
        : resolvedMode == ThemeMode.light
            ? false
            : theme.brightness == Brightness.dark;
    final ValueChanged<bool>? onToggle = themeController == null
        ? null
        : (value) => themeController.setMode(value ? ThemeMode.dark : ThemeMode.light);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _ThemeModeCard(
            isDarkMode: isDarkMode,
            onChanged: onToggle,
            cardColor: cardColor,
            borderColor: borderColor,
            enabled: themeController != null,
          ),
          const SizedBox(height: 20),
          _SettingsCard(
            title: 'Account',
            items: const [
              _SettingsItem(icon: Icons.person_outline, title: 'Profile information', subtitle: 'Name, contact & address'),
              _SettingsItem(icon: Icons.credit_card, title: 'Payment methods', subtitle: 'UPI, cards & payout accounts'),
              _SettingsItem(icon: Icons.lock_clock, title: 'Login & security', subtitle: 'Password, biometrics, devices'),
            ],
            cardColor: cardColor,
            borderColor: borderColor,
          ),
          const SizedBox(height: 20),
          _SettingsCard(
            title: 'Notifications',
            items: const [
              _SettingsItem(icon: Icons.notifications_outlined, title: 'Push alerts', subtitle: 'Product drops & payouts'),
              _SettingsItem(icon: Icons.email_outlined, title: 'Email updates', subtitle: 'Billing, statements, newsletter'),
              _SettingsItem(icon: Icons.sms_outlined, title: 'SMS reminders', subtitle: 'OTP, compliance reminders'),
            ],
            cardColor: cardColor,
            borderColor: borderColor,
          ),
          const SizedBox(height: 20),
          _SettingsCard(
            title: 'Support',
            items: const [
              _SettingsItem(icon: Icons.help_outline, title: 'Help center', subtitle: 'Guides & quick answers'),
              _SettingsItem(icon: Icons.shield_outlined, title: 'Policies', subtitle: 'Privacy, terms & compliance'),
              _SettingsItem(icon: Icons.logout, title: 'Sign out', subtitle: 'Securely logout of this device'),
            ],
            cardColor: cardColor,
            borderColor: borderColor,
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.items, required this.cardColor, required this.borderColor});

  final String title;
  final List<_SettingsItem> items;
  final Color cardColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.45 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i != 0)
              Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: borderColor.withValues(alpha: 0.6),
              ),
            _SettingsTile(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.item});

  final _SettingsItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem {
  const _SettingsItem({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;
}

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard({
    required this.isDarkMode,
    required this.onChanged,
    required this.cardColor,
    required this.borderColor,
    required this.enabled,
  });

  final bool isDarkMode;
  final ValueChanged<bool>? onChanged;
  final Color cardColor;
  final Color borderColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.45 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dark mode', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  enabled ? 'Toggle between light and dark experience' : 'Theme toggle unavailable in this context',
                  style: labelStyle,
                ),
              ],
            ),
          ),
          Switch(
            value: isDarkMode,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
