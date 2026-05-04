import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../state/profile_state.dart';

/// BV transaction history (shared by [WalletScreen] and [TransactionsScreen]).
class BVTransactionsPanel extends StatefulWidget {
  const BVTransactionsPanel({super.key, this.embeddedInWallet = false});

  /// When true, uses tighter padding and typography for narrow layouts.
  final bool embeddedInWallet;

  @override
  State<BVTransactionsPanel> createState() => _BVTransactionsPanelState();
}

class _BVTransactionsPanelState extends State<BVTransactionsPanel> {
  bool _isLoading = true;
  List<_BVTransactionItemData> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadBVTransactions();
  }

  Future<void> _loadBVTransactions() async {
    try {
      final profile = ProfileProvider.of(context, listen: false).data;
      final apiClient = ApiClient.instance;
      final response = await apiClient.getBVTransactions(profile.partnerId);
      final List<dynamic> data = response['data'] ?? [];
      final transactions =
          data.map((item) => _mapBVTransactionToItemData(item)).toList();
      if (!mounted) return;
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _transactions = [];
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

    final amountText = '+${amount.toStringAsFixed(2)} BV';
    const color = Colors.green;

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
    final w = MediaQuery.sizeOf(context).width;
    final compact = widget.embeddedInWallet || w < 420;
    final outerPad = compact ? 10.0 : 16.0;
    final titleFs =
        compact ? ((theme.textTheme.titleMedium?.fontSize ?? 16) - 1).clamp(13.0, 18.0) : null;

    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.all(outerPad),
        child: const Center(child: CircularProgressIndicator()),
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
      padding: EdgeInsets.all(outerPad),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF0F172A)
            : Colors.white,
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BV Transactions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: titleFs,
            ),
          ),
          SizedBox(height: compact ? 10 : 16),
          for (final transaction in transactions) ...[
            _BVTransactionItem(data: transaction, compact: compact),
            if (transaction != transactions.last)
              Divider(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.08)),
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
  const _BVTransactionItem({required this.data, required this.compact});

  final _BVTransactionItemData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final box = compact ? 36.0 : 40.0;
    final iconSz = compact ? 18.0 : 20.0;
    final titleStyle = compact
        ? theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: ((theme.textTheme.bodySmall?.fontSize ?? 12) - 0.5)
                .clamp(11.0, 14.0),
            height: 1.2,
          )
        : theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);
    final subStyle = compact
        ? theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 10.5,
            height: 1.2,
          )
        : theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          );
    final amtStyle = compact
        ? theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: data.color,
            fontSize: 11.5,
          )
        : theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: data.color,
          );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 8 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: box,
            height: box,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(compact ? 10 : 12),
            ),
            child: Icon(data.icon, color: data.color, size: iconSz),
          ),
          SizedBox(width: compact ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: subStyle,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            data.amount,
            textAlign: TextAlign.end,
            style: amtStyle,
          ),
        ],
      ),
    );
  }
}
