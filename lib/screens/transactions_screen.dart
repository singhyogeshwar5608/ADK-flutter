import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../state/profile_state.dart';
import '../services/api_client.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  static const routeName = '/transactions';

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: background,
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
                _TransactionsHeader(theme: theme),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                        horizontalPadding, 20, horizontalPadding, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _BVTransactionSection(),
                      ],
                    ),
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

class _TransactionsHeader extends StatelessWidget {
  const _TransactionsHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF0F172A)
            : Colors.white,
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
              'Transaction history',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          _CircleIconButton(icon: Icons.download_outlined, onTap: () {}),
        ],
      ),
    );
  }
}

class _BVTransactionSection extends StatefulWidget {
  const _BVTransactionSection();

  @override
  State<_BVTransactionSection> createState() => _BVTransactionSectionState();
}

class _BVTransactionSectionState extends State<_BVTransactionSection> {
  bool _isLoading = true;
  List<_BVTransactionItemData> _transactions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBVTransactions();
  }

  Future<void> _loadBVTransactions() async {
    try {
      final profile = ProfileProvider.of(context, listen: false).data;
      final apiClient = ApiClient.instance;

      // Fetch BV transactions
      final response = await apiClient.getBVTransactions(profile.partnerId);

      final List<dynamic> data = response['data'] ?? [];

      final transactions =
          data.map((item) => _mapBVTransactionToItemData(item)).toList();

      setState(() {
        _transactions = transactions; // Show all BV transactions
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = null; // Don't show error, just show empty state
        _transactions = []; // Clear transactions on error
      });
    }
  }

  _BVTransactionItemData _mapBVTransactionToItemData(
      Map<String, dynamic> item) {
    final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
    final direction = item['direction'] as String? ?? 'SELF';
    final sourceType = item['source_type'] as String? ?? 'Unknown';
    final createdAt = item['created_at'] as String? ?? '';
    final meta = item['meta'] as Map<String, dynamic>? ?? {};

    String description = 'BV Purchase';
    if (sourceType == 'PURCHASE') {
      description = 'BV Purchase - ${meta['product_name'] ?? 'Product'}';
    } else if (sourceType == 'BONUS') {
      description = 'BV Bonus - ${meta['bonus_type'] ?? 'Bonus'}';
    } else if (sourceType == 'ADJUSTMENT') {
      description = 'BV Adjustment - ${meta['reason'] ?? 'Manual'}';
    }

    final dateTime = createdAt.isNotEmpty
        ? DateTime.tryParse(createdAt) ?? DateTime.now()
        : DateTime.now();

    final formattedDate =
        '${dateTime.day.toString().padLeft(2, '0')} ${_monthName(dateTime.month)} ${dateTime.year}';
    final formattedTime =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    String amountText = '+${amount.toStringAsFixed(2)} BV';
    Color color = Colors.green;

    return _BVTransactionItemData(
      title: description,
      subtitle: 'Direction: $direction | $formattedDate',
      amount: amountText,
      icon: _getBVIcon(direction),
      color: color,
      date: formattedDate,
      time: formattedTime,
      sourceType: sourceType,
      meta: meta,
    );
  }

  IconData _getBVIcon(String direction) {
    switch (direction) {
      case 'LEFT':
        return Icons.arrow_left;
      case 'RIGHT':
        return Icons.arrow_right;
      default:
        return Icons.add_circle;
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Unable to load BV transactions',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      );
    }

    final transactions = _transactions.isEmpty
        ? [
            _BVTransactionItemData(
              title: 'No BV transactions available',
              subtitle: 'Your BV transaction history will appear here',
              amount: '0 BV',
              icon: Icons.account_balance_wallet,
              color: Colors.grey,
              date: '',
              time: '',
              sourceType: '',
              meta: {},
            ),
          ]
        : _transactions;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF0F172A)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'BV Transactions',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final transaction in transactions) ...[
            _BVTransactionItem(data: transaction),
            if (transaction != transactions.last)
              Divider(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
          ],
        ],
      ),
    );
  }
}

class _BVTransactionItemData {
  const _BVTransactionItemData({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.color,
    required this.date,
    required this.time,
    required this.sourceType,
    required this.meta,
  });

  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final Color color;
  final String date;
  final String time;
  final String sourceType;
  final Map<String, dynamic> meta;
}

class _BVTransactionItem extends StatelessWidget {
  const _BVTransactionItem({required this.data});

  final _BVTransactionItemData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            data.amount,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: data.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

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
          child: Icon(icon),
        ),
      ),
    );
  }
}
