import 'package:flutter/material.dart';

const _kWalletBalanceDisplay = r'$3,210.40';
const _kWalletBalanceRaw = '3210.40';

class AddFundsScreen extends StatelessWidget {
  const AddFundsScreen({super.key});

  static const routeName = '/add-funds';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                const _AddFundsHeader(),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: const _AddFundsBody(),
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

class _AddFundsHeader extends StatelessWidget {
  const _AddFundsHeader();

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
          _CircleIconButton(icon: Icons.arrow_back, onTap: () => Navigator.of(context).maybePop()),
          Expanded(
            child: Text(
              'Add Funds',
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

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
      ),
    );
  }
}

class _AddFundsBody extends StatefulWidget {
  const _AddFundsBody();

  @override
  State<_AddFundsBody> createState() => _AddFundsBodyState();
}

class _AddFundsBodyState extends State<_AddFundsBody> {
  static const _presetValues = ['50', '100', '250', '500'];

  late final TextEditingController _amountController;
  String? _highlightedPreset;
  int _selectedMethodIndex = 0;

  @override
  void initState() {
    super.initState();
    _highlightedPreset = _presetValues[1];
    _amountController = TextEditingController(text: _presetValues[1]);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _handlePresetSelection(String presetValue, {String? labelOverride}) {
    final label = labelOverride ?? presetValue;
    setState(() {
      _highlightedPreset = label;
      _amountController
        ..text = presetValue
        ..selection = TextSelection.fromPosition(TextPosition(offset: presetValue.length));
    });
  }

  void _handleAmountChanged(String value) {
    String? label;
    if (_presetValues.contains(value)) {
      label = value;
    } else if (value == _kWalletBalanceRaw) {
      label = 'MAX';
    }

    setState(() {
      _highlightedPreset = label;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _WalletTopUpCard(balanceText: _kWalletBalanceDisplay),
          const SizedBox(height: 20),
          _AmountEntryCard(
            presets: _presetValues,
            controller: _amountController,
            highlightedPreset: _highlightedPreset,
            onPresetSelected: _handlePresetSelection,
            onAmountChanged: _handleAmountChanged,
          ),
          const SizedBox(height: 20),
          _PaymentOptionsSection(
            selectedIndex: _selectedMethodIndex,
            onOptionTap: (index) {
              setState(() => _selectedMethodIndex = index);
            },
          ),
          const SizedBox(height: 20),
          const _PromoCodeCard(),
          const SizedBox(height: 28),
          const _ConfirmButton(),
        ],
      ),
    );
  }
}

class _WalletTopUpCard extends StatelessWidget {
  const _WalletTopUpCard({required this.balanceText});

  final String balanceText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            'Current Wallet Balance',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            balanceText,
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _WalletMetaChip(icon: Icons.credit_score, label: 'Auto top-up enabled'),
              _WalletMetaChip(icon: Icons.lock_clock, label: 'Next release in 4 days'),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletMetaChip extends StatelessWidget {
  const _WalletMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AmountEntryCard extends StatelessWidget {
  const _AmountEntryCard({
    required this.presets,
    required this.controller,
    required this.highlightedPreset,
    required this.onPresetSelected,
    required this.onAmountChanged,
  });

  final List<String> presets;
  final TextEditingController controller;
  final String? highlightedPreset;
  final void Function(String presetValue, {String? labelOverride}) onPresetSelected;
  final ValueChanged<String> onAmountChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Amount',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: onAmountChanged,
            decoration: InputDecoration(
              prefixText: '\$',
              hintText: '500.00',
              filled: true,
              fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFD7DFE7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: isDark ? const Color(0xFF273244) : const Color(0xFFD7DFE7)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.4),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Quick Presets',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final preset in presets)
                _PresetChip(
                  label: '\$$preset',
                  isHighlighted: highlightedPreset == preset,
                  onTap: () => onPresetSelected(preset),
                ),
              _PresetChip(
                label: 'MAX',
                isOutlined: true,
                isHighlighted: highlightedPreset == 'MAX',
                onTap: () => onPresetSelected(_kWalletBalanceRaw, labelOverride: 'MAX'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
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
    final background = isHighlighted
        ? theme.colorScheme.primary
        : (isOutlined ? Colors.transparent : theme.colorScheme.primary.withValues(alpha: 0.08));
    final border = isOutlined
        ? Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.2))
        : Border.all(color: Colors.transparent);
    final baseTextColor = isHighlighted ? Colors.white : theme.colorScheme.onSurface;
    final textColor = isOutlined && !isHighlighted
        ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
        : baseTextColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: border,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PaymentOptionsSection extends StatelessWidget {
  const _PaymentOptionsSection({required this.selectedIndex, required this.onOptionTap});

  final int selectedIndex;
  final ValueChanged<int> onOptionTap;

  static const _options = [
    _PaymentOptionData(
      icon: Icons.account_balance,
      title: 'Bank Transfer',
      subtitle: '1-2 business days',
      accent: Color(0xFF1D4ED8),
    ),
    _PaymentOptionData(
      icon: Icons.credit_card,
      title: 'Credit / Debit Card',
      subtitle: 'Instant processing',
      accent: Color(0xFFEA580C),
    ),
    _PaymentOptionData(
      icon: Icons.currency_bitcoin,
      title: 'USDT / Crypto',
      subtitle: 'Best for global payouts',
      accent: Color(0xFF059669),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Funding Method',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _options.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == _options.length - 1 ? 0 : 12),
            child: _PaymentOptionCard(
              data: _options[i],
              isSelected: i == selectedIndex,
              onTap: () => onOptionTap(i),
            ),
          ),
      ],
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  const _PaymentOptionCard({required this.data, required this.isSelected, required this.onTap});

  final _PaymentOptionData data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final card = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isSelected ? theme.colorScheme.primary : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: data.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(data.icon, color: data.accent),
          ),
          const SizedBox(width: 16),
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
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: card,
    );
  }
}

class _PaymentOptionData {
  const _PaymentOptionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
}

class _PromoCodeCard extends StatelessWidget {
  const _PromoCodeCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.confirmation_number, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apply Promo Code',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Top-up at least \$500 to unlock 5% bonus',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('Apply')),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: const Text('Confirm & Add Funds'),
    );
  }
}
