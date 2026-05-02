import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static const routeName = '/notifications';

  /// Returns how many notifications are still unread.
  static int unreadCount() =>
      _notifications.where((notification) => notification.unread).length;

  /// Marks every notification as read (opened).
  static void markAllRead() {
    for (final notification in _notifications) {
      notification.unread = false;
    }
  }

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

enum NotificationFilter { all, updates, orders, community }

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationFilter _selectedFilter = NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.of(context).size.width <= 414;
    final items = _filteredNotifications;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune),
            tooltip: 'Notification settings',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, isCompact ? 4 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: isCompact ? 8 : 12),
                Wrap(
                  spacing: isCompact ? 8 : 10,
                  runSpacing: isCompact ? 10 : 14,
                  children: NotificationFilter.values.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return ChoiceChip(
                      label: Text(filter.label),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedFilter = filter),
                      selectedColor: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      labelStyle: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? _EmptyState(theme: theme)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemBuilder: (context, index) {
                      final notification = items[index];
                      return _NotificationTile(notification: notification);
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: items.length,
                  ),
          ),
        ],
      ),
    );
  }

  List<_NotificationItem> get _filteredNotifications {
    if (_selectedFilter == NotificationFilter.all) return _notifications;
    return _notifications.where((item) => item.filter == _selectedFilter).toList();
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final _NotificationItem notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: notification.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(notification.icon, color: notification.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: notification.unread
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        notification.timeLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

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
            Icon(Icons.notifications_off_outlined, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'You are all caught up. New updates will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : const Color(0xFF475569),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem {
  _NotificationItem({
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.icon,
    required this.accent,
    required this.filter,
    this.unread = false,
  });

  final String title;
  final String body;
  final String timeLabel;
  final IconData icon;
  final Color accent;
  final NotificationFilter filter;
  bool unread;
}

final List<_NotificationItem> _notifications = [
  _NotificationItem(
    title: 'Payout processed',
    body: '₹12,450 commission has been credited to your wallet.',
    timeLabel: '2m ago',
    icon: Icons.payments_rounded,
    accent: Color(0xFF22C55E),
    filter: NotificationFilter.orders,
    unread: true,
  ),
  _NotificationItem(
    title: 'New partner joined',
    body: 'Arjun added to your downline. Send a welcome note!',
    timeLabel: '45m ago',
    icon: Icons.group_add_outlined,
    accent: Color(0xFF6366F1),
    filter: NotificationFilter.community,
    unread: true,
  ),
  _NotificationItem(
    title: 'Order #90412 shipped',
    body: 'Nordic Air Purifier is on the way to Priya.',
    timeLabel: 'Yesterday',
    icon: Icons.local_shipping_outlined,
    accent: Color(0xFF0EA5E9),
    filter: NotificationFilter.orders,
  ),
  _NotificationItem(
    title: 'Team AMA tomorrow',
    body: 'Join the leadership AMA at 6PM IST in your dashboard.',
    timeLabel: '2d ago',
    icon: Icons.campaign_outlined,
    accent: Color(0xFFF97316),
    filter: NotificationFilter.updates,
  ),
];

extension on NotificationFilter {
  String get label {
    switch (this) {
      case NotificationFilter.all:
        return 'All';
      case NotificationFilter.updates:
        return 'Updates';
      case NotificationFilter.orders:
        return 'Orders';
      case NotificationFilter.community:
        return 'Community';
    }
  }
}
