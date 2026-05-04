import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/bv_transactions_panel.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  static const routeName = '/transactions';

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
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BVTransactionsPanel(),
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
