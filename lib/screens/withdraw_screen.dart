import 'package:flutter/material.dart';

class WithdrawScreen extends StatelessWidget {
  const WithdrawScreen({super.key});

  static const routeName = '/withdraw';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF101A22) : const Color(0xFFF6F7F8);

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
                const _WithdrawHeader(),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: const _WithdrawBody(),
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

class _WithdrawHeader extends StatelessWidget {
  const _WithdrawHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final divider = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(bottom: BorderSide(color: divider)),
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
          _CircleIconButton(icon: Icons.arrow_back, onTap: () => Navigator.of(context).maybePop()),
          Expanded(
            child: Text(
              'Withdraw Funds',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          _CircleIconButton(icon: Icons.help_outline, onTap: () {}),
        ],
      ),
    );
  }
}

class _WithdrawBody extends StatefulWidget {
  const _WithdrawBody();

  @override
  State<_WithdrawBody> createState() => _WithdrawBodyState();
}

class _WithdrawBodyState extends State<_WithdrawBody> {
  static const _balanceRaw = '3210.40';
  static const _presetValues = ['100', '250', '500'];

  late final TextEditingController _amountController;
  String? _selectedPresetLabel;
  int _selectedMethodIndex = 0;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _handlePresetTap(String value, {String? labelOverride}) {
    final label = labelOverride ?? value;
    setState(() {
      _selectedPresetLabel = label;
      _amountController
        ..text = value
        ..selection = TextSelection.fromPosition(TextPosition(offset: value.length));
    });
  }

  void _handleAmountChanged(String value) {
    String? chip;
    if (_presetValues.contains(value)) {
      chip = value;
    } else if (value == _balanceRaw) {
      chip = 'MAX';
    }

    setState(() {
      _selectedPresetLabel = chip;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _BalanceSummaryCard(),
          const SizedBox(height: 20),
          _AmountSection(
            controller: _amountController,
            selectedPresetLabel: _selectedPresetLabel,
            onPresetTap: _handlePresetTap,
            onAmountChanged: _handleAmountChanged,
          ),
          const SizedBox(height: 20),
          _MethodSelector(
            selectedIndex: _selectedMethodIndex,
            onSelect: (index) {
              setState(() => _selectedMethodIndex = index);
            },
          ),
          const SizedBox(height: 20),
          const _FeeBreakdown(),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {},
            child: Text(
              'Confirm Withdrawal',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Estimated processing time: 1-3 business days',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceSummaryCard extends StatelessWidget {
  const _BalanceSummaryCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available for Withdrawal',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹3,210.40',
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _InfoChip(icon: Icons.check_circle, label: 'Instant transfer enabled'),
              _InfoChip(icon: Icons.lock_clock, label: 'Last payout 2 days ago'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountSection extends StatelessWidget {
  const _AmountSection({
    required this.controller,
    required this.selectedPresetLabel,
    required this.onPresetTap,
    required this.onAmountChanged,
  });

  final TextEditingController controller;
  final String? selectedPresetLabel;
  final void Function(String value, {String? labelOverride}) onPresetTap;
  final ValueChanged<String> onAmountChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Withdrawal Amount',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: onAmountChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.currency_rupee),
              hintText: 'Enter amount',
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: isDark ? const Color(0xFF273548) : const Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in _WithdrawBodyState._presetValues)
                _PresetAmountChip(
                  label: '₹$preset',
                  isHighlighted: selectedPresetLabel == preset,
                  onTap: () => onPresetTap(preset),
                ),
              _PresetAmountChip(
                label: 'MAX',
                isOutlined: true,
                isHighlighted: selectedPresetLabel == 'MAX',
                onTap: () => onPresetTap(_WithdrawBodyState._balanceRaw, labelOverride: 'MAX'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodSelector extends StatelessWidget {
  const _MethodSelector({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final methods = const [
      _MethodOptionData(
        icon: Icons.account_balance,
        title: 'Bank Transfer',
        subtitle: 'Ends with ••9823',
      ),
      _MethodOptionData(
        icon: Icons.credit_card,
        title: 'Debit Card',
        subtitle: 'Instant payout, 1.5% fee',
      ),
      _MethodOptionData(
        icon: Icons.account_balance_wallet,
        title: 'USDT Wallet',
        subtitle: '0% fee, 30 min settlement',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Method',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            for (var i = 0; i < methods.length; i++)
              _MethodCard(
                data: methods[i],
                isActive: selectedIndex == i,
                onTap: () => onSelect(i),
              ),
          ],
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({required this.data, required this.isActive, required this.onTap});

  final _MethodOptionData data;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isActive
        ? theme.colorScheme.primary
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));

    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isActive ? 2 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(data.icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  data.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isActive ? Icons.radio_button_checked : Icons.radio_button_off,
            color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: card,
    );
  }
}

class _MethodOptionData {
  const _MethodOptionData({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;
}

class _FeeBreakdown extends StatelessWidget {
  const _FeeBreakdown();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget row(String label, String value, {bool emphasized = false}) {
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
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
              color: emphasized ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fee Breakdown',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          row('Requested Amount', '₹500.00'),
          const SizedBox(height: 8),
          row('Processing Fee (1.5%)', '₹7.50'),
          const SizedBox(height: 12),
          Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
          const SizedBox(height: 12),
          row('You will receive', '₹492.50', emphasized: true),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _PresetAmountChip extends StatelessWidget {
  const _PresetAmountChip({
    required this.label,
    this.isHighlighted = false,
    this.isOutlined = false,
    this.onTap,
  });

  final String label;
  final bool isHighlighted;
  final bool isOutlined;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isHighlighted
        ? theme.colorScheme.primary
        : (isOutlined
            ? Colors.transparent
            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)));
    final border = Border.all(
      color: isHighlighted
          ? theme.colorScheme.primary
          : (isDark ? const Color(0xFF273548) : const Color(0xFFE2E8F0)),
      width: isHighlighted ? 2 : 1,
    );
    final textColor = isHighlighted
        ? Colors.white
        : (isOutlined ? theme.colorScheme.onSurface.withValues(alpha: 0.7) : theme.colorScheme.onSurface);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: border,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
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
          child: Icon(icon, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      ),
    );
  }
}
