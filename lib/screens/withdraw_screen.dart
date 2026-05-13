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
            selectedIndex: _selectedMethodIndex.clamp(0, 1),
            onSelect: (index) {
              setState(() => _selectedMethodIndex = index);
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 10),
              minimumSize: const Size(double.infinity, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {},
            child: Text(
              'Confirm Withdrawal',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) - 3,
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
              fontSize: (theme.textTheme.displaySmall?.fontSize ?? 36) - 3,
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) - 3,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: onAmountChanged,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: (theme.textTheme.bodyLarge?.fontSize ?? 16) - 3,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 40, maxHeight: 40),
              prefixIcon: Icon(
                Icons.currency_rupee,
                size: (theme.iconTheme.size ?? 24) - 3,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
              hintText: 'Enter amount',
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                fontSize: (theme.textTheme.bodyLarge?.fontSize ?? 16) - 3,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? const Color(0xFF273548) : const Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
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
    const methods = [
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
    ];

    final idx = selectedIndex.clamp(0, methods.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Method',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) - 3,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 420;
            final gap = narrow ? 8.0 : 10.0;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _MethodCard(
                      data: methods[0],
                      isActive: idx == 0,
                      onTap: () => onSelect(0),
                      compact: narrow,
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: _MethodCard(
                      data: methods[1],
                      isActive: idx == 1,
                      onTap: () => onSelect(1),
                      compact: narrow,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.data,
    required this.isActive,
    required this.onTap,
    this.compact = false,
  });

  final _MethodOptionData data;
  final bool isActive;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final borderColor = isActive ? primary : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));
    final titleStyle = theme.textTheme.titleSmall;
    final subtitleStyle = theme.textTheme.bodySmall;

    final radius = compact ? 12.0 : 14.0;
    final outerRadius = compact ? 14.0 : 16.0;
    final pad = EdgeInsets.fromLTRB(compact ? 8 : 10, compact ? 6 : 10, compact ? 8 : 10, compact ? 8 : 12);
    final radioSize = compact ? 17.0 : 21.0;
    final iconBox = compact ? 28.0 : 36.0;
    final innerIconSize = compact ? 15.0 : 19.0;
    final titleFs = compact
        ? ((titleStyle?.fontSize ?? 14) - 3.5).clamp(11.5, 15.0)
        : ((titleStyle?.fontSize ?? 14) - 3);
    final subtitleFs =
        compact ? ((subtitleStyle?.fontSize ?? 12) - 3).clamp(9.5, 12.0) : ((subtitleStyle?.fontSize ?? 12) - 3);

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: pad,
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [
                  primary.withValues(alpha: isDark ? 0.22 : 0.12),
                  primary.withValues(alpha: isDark ? 0.08 : 0.04),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        color: !isActive
            ? (isDark ? const Color(0xFF0F172A) : Colors.white)
            : null,
        borderRadius: BorderRadius.circular(outerRadius),
        border: Border.all(color: borderColor, width: isActive ? 2 : 1),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: primary.withValues(alpha: 0.12),
                  blurRadius: compact ? 8 : 12,
                  offset: Offset(0, compact ? 3 : 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: SizedBox(
              width: compact ? 20 : 24,
              height: compact ? 20 : 24,
              child: Center(
                child: Icon(
                  isActive ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: radioSize,
                  color: isActive ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 0 : 2),
          Center(
            child: Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: isActive ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Icon(data.icon, color: primary, size: innerIconSize),
            ),
          ),
          SizedBox(height: compact ? 5 : 8),
          Text(
            data.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: titleStyle?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: titleFs,
              height: 1.15,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: subtitleStyle?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
              fontSize: subtitleFs,
              height: 1.2,
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(outerRadius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class _MethodOptionData {
  const _MethodOptionData({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;
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
