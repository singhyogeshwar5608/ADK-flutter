import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../utils/referral_config.dart';
import '../state/profile_state.dart';
import '../services/api_client.dart';
import '../services/cloudinary_service.dart';
import 'binary_tree_screen.dart';
import 'my_team_screen.dart';
import 'login_screen.dart';
import 'profile_edit_screen.dart';
import 'my_referral_screen.dart';
import 'wallet_screen.dart';

/// Height of income grid tiles; total income row and quick-action cells match this.
const double _kProfileIncomeTileHeight = 78;

/// Referral leg selectors share this tap height.
const double _kReferralShareRowMinHeight = 38;

/// Copy / WhatsApp controls: compact row (avoids wrapping on narrow layouts).
const double _kReferralShareActionBarHeight = 34;
const double _kReferralShareActionFontSize = 11;
const double _kReferralShareActionIconSize = 14;

/// Selected left/right leg tint (aqua/cyan — readable white labels on top).
const Color _referralLegSelectedBg = Color(0xFF06B6D4);
const Color _referralLegSelectedBorder = Color(0xFF0891B2);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final profileState = ProfileProvider.of(context);

    return ListenableBuilder(
      listenable: profileState,
      builder: (context, _) {
        if (profileState.isLoading && !profileState.isAuthenticated) {
          return Scaffold(
            backgroundColor: background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!profileState.isAuthenticated) {
          return Scaffold(
            backgroundColor: background,
            appBar: AppBar(title: const Text('Profile')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_person_outlined,
                        size: 56,
                        color: theme.colorScheme.primary.withValues(alpha: 0.85),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sign in to load your profile, income, and KYC from the server.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                      ),
                      if (profileState.error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          profileState.error!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => Navigator.of(context)
                            .pushNamed(LoginScreen.routeName),
                        child: const Text('Sign in'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: background,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => profileState.refresh(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final sidePadding =
                      _responsiveSidePadding(constraints.maxWidth);
                  final contentWidth =
                      (constraints.maxWidth - (sidePadding * 2))
                          .clamp(320.0, constraints.maxWidth);
                  const verticalGap = 4.0;
                  const heroToSummaryGap = 2.0;

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                        sidePadding, 12, sidePadding, 28 + verticalGap),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (profileState.isLoading)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: LinearProgressIndicator(minHeight: 3),
                          ),
                        _ProfileHeroSection(availableWidth: contentWidth),
                        SizedBox(height: heroToSummaryGap.toDouble()),
                        const _ProfileIncomeDashboard(),
                        const SizedBox(height: 20),
                        _ProfileRewardsBvKycSection(
                          referralInitialLeg:
                              profileState.data.placementLeg ?? 'LEFT',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

ImageProvider _buildImageProvider(String path) {
  if (path.startsWith('http')) {
    return NetworkImage(path);
  }
  return FileImage(File(path));
}

/// Income grid + total card (matches new profile design).
class _ProfileIncomeDashboard extends StatelessWidget {
  const _ProfileIncomeDashboard();

  static const _teal = Color(0xFF0D9488);
  static const _purple = Color(0xFF7C3AED);
  static const _green = Color(0xFF16A34A);
  static const _amber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final profile = ProfileProvider.of(context).data;
    final sponsor = profile.mlmSponsorIncome ?? profile.directIncome ?? 0;
    final matching = profile.matchingIncome ?? 0;
    final selfPurchase = profile.selfPurchaseIncome ?? 0;
    final selfRepurchase = profile.selfRepurchaseIncome ?? 0;
    final repurchaseMatching = profile.repurchaseMatchingIncome ?? 0;
    final sponsorAward = profile.sponsorAwardKitIncome ?? 0;

    final tiles = <({String title, double amount, Color valueColor})>[
      (title: 'SELF PURCHASE INCOME', amount: selfPurchase, valueColor: _teal),
      (title: 'SPONSOR INCOME', amount: sponsor, valueColor: _purple),
      (title: 'MATCHING INCOME', amount: matching, valueColor: _green),
      (title: 'SELF RE-PURCHASE INCOME', amount: selfRepurchase, valueColor: _teal),
      (
        title: 'RE-PURCHASE MATCHING INCOME',
        amount: repurchaseMatching,
        valueColor: _green
      ),
      (
        title: 'SPONSOR AWARD KIT RE-PURCHASE INCOME',
        amount: sponsorAward,
        valueColor: _amber
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 8.0;
            const columns = 3;
            /// Same for every tile so long titles do not stretch one row taller.
            final w = (constraints.maxWidth - spacing * (columns - 1)) /
                columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final t in tiles)
                  SizedBox(
                    width: w,
                    height: _kProfileIncomeTileHeight,
                    child: _IncomeCategoryCard(
                      title: t.title,
                      amount: t.amount,
                      valueColor: t.valueColor,
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        _TotalIncomeSummaryCard(total: profile.totalIncome),
      ],
    );
  }
}

class _IncomeCategoryCard extends StatelessWidget {
  const _IncomeCategoryCard({
    required this.title,
    required this.amount,
    required this.valueColor,
  });

  final String title;
  final double amount;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelBase =
        theme.textTheme.labelSmall?.fontSize ?? 11; // −2px vs typical labelSmall
    final labelSize = (labelBase - 2).clamp(8.0, 24.0);
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorderColor(context)),
        boxShadow: _softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: labelSize,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  height: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(amount),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: valueColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalIncomeSummaryCard extends StatelessWidget {
  const _TotalIncomeSummaryCard({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const teal = Color(0xFF0D9488);
    final labelBase =
        theme.textTheme.labelSmall?.fontSize ?? 11;
    final labelSize = (labelBase - 2).clamp(8.0, 24.0);
    return Container(
      height: _kProfileIncomeTileHeight,
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorderColor(context)),
        boxShadow: _softShadow(context),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'TOTAL INCOME',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: labelSize,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(total),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: teal,
              fontSize: 13,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Family Tour reward, BV status, matching pairs, KYC (matches reference layout).
class _ProfileRewardsBvKycSection extends StatelessWidget {
  const _ProfileRewardsBvKycSection({required this.referralInitialLeg});

  final String referralInitialLeg;

  static const _cardRadius = 20.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FamilyTourRewardCard(cardRadius: _cardRadius),
        const SizedBox(height: 22),
        const _BvStatusBlock(cardRadius: _cardRadius),
        const SizedBox(height: 16),
        const _MatchingPairsHighlightCard(cardRadius: _cardRadius),
        const SizedBox(height: 22),
        const _KycDocumentsSectionTitle(),
        const _KycDocumentsBlock(cardRadius: _cardRadius),
        const SizedBox(height: 16),
        const _AadharKycCard(cardRadius: _cardRadius),
        const SizedBox(height: 16),
        const _PanKycCard(cardRadius: _cardRadius),
        const SizedBox(height: 16),
        const _ProfileQRCodeSection(),
        const SizedBox(height: 24),
        const _ProfileQuickActionsSection(),
        const SizedBox(height: 24),
        _ReferralLinkCard(initialLeg: referralInitialLeg),
        const SizedBox(height: 20),
        const _SupportAssistanceCard(),
      ],
    );
  }
}

class _FamilyTourRewardCard extends StatelessWidget {
  const _FamilyTourRewardCard({required this.cardRadius});

  final double cardRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ProfileProvider.of(context).data;
    final directIdsCount = profile.followers; // This contains the direct referrals count
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: _cardBorderColor(context)),
        boxShadow: _softShadow(context),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: Color(0xFFF97316),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Family Tour Reward',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Complete 30 direct IDs in 3 months to get Family Tour.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                          height: 1.45,
                          fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) - 2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: directIdsCount >= 30 
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : const Color(0xFFF97316).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: directIdsCount >= 30 
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF97316),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$directIdsCount/30',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: directIdsCount >= 30 
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF97316),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (directIdsCount / 30).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: directIdsCount >= 30 
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF97316),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  directIdsCount >= 30 
                      ? '🎉 Congratulations! You have completed the requirement!'
                      : 'You have ${directIdsCount} direct IDs. Need ${30 - directIdsCount} more.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: directIdsCount >= 30 
                        ? const Color(0xFF10B981)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) - 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BvStatusBlock extends StatelessWidget {
  const _BvStatusBlock({required this.cardRadius});

  final double cardRadius;

  static String _strongLegLabel(double left, double right) {
    if (left >= right) return 'Strong Left Leg';
    return 'Strong Right Leg';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ProfileProvider.of(context).data;
    final left = profile.leftLegBv ?? 0;
    final right = profile.rightLegBv ?? 0;
    final leftLabel = left == left.roundToDouble()
        ? left.toInt().toString()
        : left.toStringAsFixed(1);
    final rightLabel = right == right.roundToDouble()
        ? right.toInt().toString()
        : right.toStringAsFixed(1);
    final divider = theme.brightness == Brightness.dark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    const teal = Color(0xFF0D9488);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Volume (BV) Status',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
          decoration: BoxDecoration(
            color: _surfaceColor(context),
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(color: _cardBorderColor(context)),
            boxShadow: _softShadow(context),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LEFT LEG',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    'RIGHT LEG',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    leftLabel,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _BvBalanceTrack(left: left, right: right),
                    ),
                  ),
                  Text(
                    rightLabel,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: divider),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Balance Status',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _strongLegLabel(left, right),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: teal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: teal.withValues(alpha: 0.85),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BvBalanceTrack extends StatelessWidget {
  const _BvBalanceTrack({required this.left, required this.right});

  final double left;
  final double right;

  @override
  Widget build(BuildContext context) {
    const trackGrey = Color(0xFFE5E7EB);
    const fillTeal = Color(0xFF0D9488);
    final total = left + right;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final ratio = total <= 0 ? 0.5 : (left / total).clamp(0.0, 1.0);
        final splitX = w * ratio;
        final knobLeft = (splitX - 6).clamp(0.0, w - 12);

        return SizedBox(
          height: 14,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 5,
                  width: w,
                  decoration: BoxDecoration(
                    color: trackGrey,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              if (total > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 5,
                    width: splitX.clamp(0.0, w),
                    decoration: BoxDecoration(
                      color: fillTeal,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              Positioned(
                left: knobLeft,
                top: 1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: trackGrey, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MatchingPairsHighlightCard extends StatelessWidget {
  const _MatchingPairsHighlightCard({required this.cardRadius});

  final double cardRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ProfileProvider.of(context).data;
    final left = profile.leftLegBv ?? 0;
    final right = profile.rightLegBv ?? 0;
    String fmt(double v) =>
        v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
    const teal = Color(0xFF0D9488);

    final pairsValueBase = theme.textTheme.titleLarge?.fontSize ?? 22;
    final pairsValueSize = (pairsValueBase - 4).clamp(12.0, 28.0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: _cardBorderColor(context)),
        boxShadow: _softShadow(context),
      ),
      child: Column(
        children: [
          Text(
            'MATCHING PAIRS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${fmt(left)} Left / ${fmt(right)} Right',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: pairsValueSize,
              fontWeight: FontWeight.w800,
              color: teal,
            ),
          ),
        ],
      ),
    );
  }
}

class _KycDocumentsBlock extends StatelessWidget {
  const _KycDocumentsBlock({required this.cardRadius});

  final double cardRadius;

  static const _blue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final profile = ProfileProvider.of(context).data;
    return _ColoredDocumentKycCard(
      cardRadius: cardRadius,
      title: 'Bank Account',
      subtitle: profile.isBankKycComplete ? 'Details on file' : 'Not uploaded',
      docType: _KycDocType.bank,
      currentNumber: profile.bankAccountNumber,
      currentImageUrl: profile.bankAccountImageUrl,
      leadingIcon: Icons.account_balance_rounded,
      iconBackground: const Color(0xFFE0F2FE),
      iconColor: _blue,
      outlineColor: const Color(0xFF38BDF8),
      fillColor: _blue,
    );
  }
}

class _KycDocumentsSectionTitle extends StatelessWidget {
  const _KycDocumentsSectionTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KYC Documents',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _AadharKycCard extends StatelessWidget {
  const _AadharKycCard({required this.cardRadius});

  final double cardRadius;

  static const _teal = Color(0xFF0D9488);

  @override
  Widget build(BuildContext context) {
    final profile = ProfileProvider.of(context).data;
    return _ColoredDocumentKycCard(
      cardRadius: cardRadius,
      title: 'Aadhar Card',
      subtitle: profile.isAadharKycComplete ? 'Details on file' : 'Not uploaded',
      docType: _KycDocType.aadhar,
      currentNumber: profile.aadharNumber,
      currentImageUrl: profile.aadharImageUrl,
      leadingIcon: Icons.credit_card_rounded,
      iconBackground: const Color(0xFFD1FAE5),
      iconColor: _teal,
      outlineColor: _teal,
      fillColor: _teal,
    );
  }
}

class _PanKycCard extends StatelessWidget {
  const _PanKycCard({required this.cardRadius});

  final double cardRadius;

  static const _orange = Color(0xFFF97316);
  static const _orangeDeep = Color(0xFFEA580C);

  @override
  Widget build(BuildContext context) {
    final profile = ProfileProvider.of(context).data;
    return _ColoredDocumentKycCard(
      cardRadius: cardRadius,
      title: 'PAN Card',
      subtitle: profile.isPanKycComplete ? 'Details on file' : 'Not uploaded',
      docType: _KycDocType.pan,
      currentNumber: profile.panNumber,
      currentImageUrl: profile.panImageUrl,
      leadingIcon: Icons.badge_rounded,
      iconBackground: const Color(0xFFFEF9C3),
      iconColor: _orange,
      outlineColor: _orange,
      fillColor: _orangeDeep,
    );
  }
}

enum _KycDocType { bank, aadhar, pan }

class _ColoredDocumentKycCard extends StatelessWidget {
  const _ColoredDocumentKycCard({
    required this.cardRadius,
    required this.title,
    required this.subtitle,
    required this.docType,
    required this.currentNumber,
    required this.currentImageUrl,
    required this.leadingIcon,
    required this.iconBackground,
    required this.iconColor,
    required this.outlineColor,
    required this.fillColor,
  });

  final double cardRadius;
  final String title;
  final String subtitle;
  final _KycDocType docType;
  final String? currentNumber;
  final String? currentImageUrl;
  final IconData leadingIcon;
  final Color iconBackground;
  final Color iconColor;
  final Color outlineColor;
  final Color fillColor;

  void _showUploadProgress(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Uploading image...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveNumber(BuildContext context) async {
    final initial = (currentNumber ?? '').trim();
    final controller = TextEditingController(text: initial);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final titleSize =
            ((theme.textTheme.titleLarge?.fontSize ?? 22) - 4).clamp(12.0, 28.0);
        final placeholderSize =
            ((theme.textTheme.bodyMedium?.fontSize ?? 14) - 3).clamp(10.0, 22.0);
        final buttonSize =
            ((theme.textTheme.labelLarge?.fontSize ?? 14) - 2).clamp(10.0, 20.0);
        return AlertDialog(
          title: Text(
            'Add $title Number',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Enter $title number',
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                fontSize: placeholderSize,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(62, 32),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: buttonSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(56, 32),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(
                controller.text.trim(),
              ),
              child: Text(
                'Save',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: buttonSize,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (value == null) return;
    final normalized = value.trim();
    if (normalized.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid document number')),
      );
      return;
    }

    try {
      final profileState = ProfileProvider.of(context, listen: false);
      late final Map<String, dynamic> member;
      switch (docType) {
        case _KycDocType.bank:
          member = await ApiClient.instance.updateKyc(
            bankAccountNumber: normalized,
          );
          break;
        case _KycDocType.aadhar:
          member = await ApiClient.instance.updateKyc(aadharNumber: normalized);
          break;
        case _KycDocType.pan:
          member = await ApiClient.instance.updateKyc(panNumber: normalized);
          break;
      }
      profileState.updateFromMemberPayload(member);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title number saved')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save number: $e')),
      );
    }
  }

  Future<void> _uploadDocImage(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 88,
    );
    if (picked == null) return;

    if (!context.mounted) return;
    _showUploadProgress(context);

    try {
      final upload = kIsWeb
          ? await CloudinaryService.instance.uploadImage(
              bytes: await picked.readAsBytes(),
              filename: picked.name,
            )
          : await CloudinaryService.instance.uploadImage(
              file: File(picked.path),
              filename: picked.name,
            );

      final profileState = ProfileProvider.of(context, listen: false);
      late final Map<String, dynamic> member;
      switch (docType) {
        case _KycDocType.bank:
          member =
              await ApiClient.instance.updateKyc(bankAccountImage: upload.url);
          break;
        case _KycDocType.aadhar:
          member = await ApiClient.instance.updateKyc(aadharImage: upload.url);
          break;
        case _KycDocType.pan:
          member = await ApiClient.instance.updateKyc(panImage: upload.url);
          break;
      }
      profileState.updateFromMemberPayload(member);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title image uploaded')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNumber = (currentNumber ?? '').trim().isNotEmpty;
    final hasImage = (currentImageUrl ?? '').trim().isNotEmpty;
    final resolvedImageUrl = (currentImageUrl ?? '').trim();
    const cardBg = Colors.white;
    const headingColor = Color(0xFF0F172A);
    const subtitleColor = Color(0xFF64748B);
    const uploadedNumberColor = Color(0xFF0D9488);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: _softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(leadingIcon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: headingColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasNumber)
                      Text(
                        currentNumber!.trim(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: uploadedNumberColor,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subtitleColor,
                        ),
                      ),
                  ],
                ),
              ),
              if (hasImage)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
            ],
          ),
          if (hasImage) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 5,
                child: Image.network(
                  resolvedImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFE2E8F0),
                    alignment: Alignment.center,
                    child: Text(
                      'Image unavailable',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: subtitleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _saveNumber(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: outlineColor,
                    side: BorderSide(color: outlineColor, width: 1.2),
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 6),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: _surfaceColor(context),
                  ),
                  icon: Icon(Icons.add, size: 18, color: outlineColor),
                  label: Text(
                    hasNumber ? 'Edit Number' : 'Add Number',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: outlineColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _uploadDocImage(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: fillColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 6),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: Text(
                    hasImage ? 'Change Image' : 'Upload Image',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileQuickActionsSection extends StatelessWidget {
  const _ProfileQuickActionsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ProfileProvider.of(context).data;
    final partnerId = profile.partnerId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.groups_rounded,
                iconColor: const Color(0xFF2B9DEE),
                iconBackground: const Color(0xFFE0F2FF),
                label: 'My Team',
                onTap: () =>
                    Navigator.of(context).pushNamed(MyTeamScreen.routeName),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.account_tree_rounded,
                iconColor: const Color(0xFF6366F1),
                iconBackground: const Color(0xFFE0E7FF),
                label: 'Binary Tree',
                onTap: () => Navigator.of(context).pushNamed(
                  BinaryTreeScreen.routeName,
                  arguments: partnerId,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF059669),
                iconBackground: const Color(0xFFDCFCE7),
                label: 'Wallet',
                onTap: () =>
                    Navigator.of(context).pushNamed(WalletScreen.routeName),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.share_rounded,
                iconColor: const Color(0xFFF97316),
                iconBackground: const Color(0xFFFFEDD5),
                label: 'Referral',
                onTap: () =>
                    Navigator.of(context).pushNamed(MyReferralScreen.routeName),
              ),
            ),
            const Expanded(child: SizedBox()),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(12);
    final labelBase = theme.textTheme.labelLarge?.fontSize ?? 14;
    final labelSize = (labelBase - 3).clamp(9.0, 20.0);
    return SizedBox(
      height: _kProfileIncomeTileHeight,
      child: Material(
        color: _surfaceColor(context),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: _cardBorderColor(context)),
        ),
        shadowColor: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: _surfaceColor(context),
              boxShadow: _softShadow(context),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferralLinkCard extends StatefulWidget {
  const _ReferralLinkCard({required this.initialLeg});

  /// `LEFT` or `RIGHT` from member record (default referral leg).
  final String initialLeg;

  @override
  State<_ReferralLinkCard> createState() => _ReferralLinkCardState();
}

class _ReferralLinkCardState extends State<_ReferralLinkCard> {
  late String _leg;
  String? _serverLinkLeft;
  String? _serverLinkRight;

  @override
  void initState() {
    super.initState();
    _leg = widget.initialLeg.toUpperCase() == 'RIGHT' ? 'RIGHT' : 'LEFT';
    _loadServerReferralLinks();
  }

  Future<void> _loadServerReferralLinks() async {
    final links = await ApiClient.instance.fetchReferralLinks();
    if (!mounted) return;
    setState(() {
      _serverLinkLeft = links?.left;
      _serverLinkRight = links?.right;
    });
  }

  String _buildLink(String partnerId) {
    var base = referralSignupBaseUrl();
    if (base.isEmpty) {
      final fromServer = _serverLinkLeft ?? _serverLinkRight;
      if (fromServer != null && fromServer.isNotEmpty) {
        final u = Uri.tryParse(fromServer);
        if (u != null && u.hasScheme) {
          base = Uri(
            scheme: u.scheme,
            host: u.host,
            port: u.hasPort ? u.port : null,
            path: u.path.isEmpty ? '/' : u.path,
          ).toString();
        }
      }
    }
    if (base.isEmpty) return '';
    final ref = Uri.encodeQueryComponent(partnerId);
    final leg = Uri.encodeQueryComponent(_leg);
    return '$base?ref=$ref&leg=$leg';
  }

  String _linkForDisplay(String partnerId) {
    final server =
        _leg == 'RIGHT' ? _serverLinkRight : _serverLinkLeft;
    if (server != null && server.isNotEmpty) return server;
    return _buildLink(partnerId);
  }

  String _describeSignupOrigin() {
    final sample = _serverLinkLeft ?? _serverLinkRight;
    if (sample != null && sample.isNotEmpty) {
      final u = Uri.tryParse(sample);
      if (u != null && u.hasScheme && u.host.isNotEmpty) {
        return u.origin;
      }
    }
    final b = referralSignupBaseUrl();
    if (b.isNotEmpty) {
      final u = Uri.tryParse(b);
      if (u != null && u.hasScheme && u.host.isNotEmpty) {
        return u.origin;
      }
    }
    return 'your signup site';
  }

  Future<void> _copyLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied')),
    );
  }

  Future<void> _shareWhatsApp(String link) async {
    final body = Uri.encodeComponent('Join me on ADK: $link');
    final uri = Uri.parse('https://wa.me/?text=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ProfileProvider.of(context).data;
    final partnerId = profile.partnerId;
    final link = _linkForDisplay(partnerId);
    const linkBoxBg = Color(0xFFE0F2FE);
    const waGreen = Color(0xFF25D366);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorderColor(context)),
        boxShadow: _softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.share_rounded, color: Color(0xFF2563EB), size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your Referral Link',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Choose which leg new members should join under you. Share link uses '
            '${_describeSignupOrigin()} — on a phone with the app installed it '
            'should open the ADK app.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _LegSelectorTile(
                  label: 'Left leg',
                  icon: Icons.keyboard_double_arrow_right_rounded,
                  selected: _leg == 'LEFT',
                  selectedBackground: _referralLegSelectedBg,
                  selectedBorder: _referralLegSelectedBorder,
                  onTap: () => setState(() => _leg = 'LEFT'),
                  labelFontSize: (theme.textTheme.titleSmall?.fontSize ?? 14) - 3,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LegSelectorTile(
                  label: 'Right leg',
                  icon: Icons.keyboard_double_arrow_right_rounded,
                  selected: _leg == 'RIGHT',
                  selectedBackground: _referralLegSelectedBg,
                  selectedBorder: _referralLegSelectedBorder,
                  onTap: () => setState(() => _leg = 'RIGHT'),
                  labelFontSize: (theme.textTheme.titleSmall?.fontSize ?? 14) - 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: linkBoxBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectableText(
                  link.isEmpty
                      ? 'Set REFERRAL_SIGNUP_BASE_URL in assets/dotenv (or use --dart-define) and ensure you are signed in, then reopen this screen.'
                      : link,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: link.isEmpty
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.55)
                        : const Color(0xFF1E3A5F),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: _kReferralShareActionBarHeight,
                        child: OutlinedButton.icon(
                          onPressed:
                              link.isEmpty ? null : () => _copyLink(link),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            backgroundColor: theme.colorScheme.surface,
                            side: BorderSide(
                              color: Colors.black.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(
                            Icons.copy_rounded,
                            size: _kReferralShareActionIconSize,
                          ),
                          label: const Text(
                            'Copy',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: _kReferralShareActionFontSize,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: _kReferralShareActionBarHeight,
                        child: Tooltip(
                          message: 'Share on WhatsApp',
                          child: FilledButton.icon(
                            onPressed: link.isEmpty
                                ? null
                                : () => _shareWhatsApp(link),
                            style: FilledButton.styleFrom(
                              backgroundColor: waGreen,
                              foregroundColor: Colors.white,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(
                              Icons.share_rounded,
                              size: _kReferralShareActionIconSize,
                            ),
                            label: const Text(
                              'WhatsApp',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: _kReferralShareActionFontSize,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegSelectorTile extends StatelessWidget {
  const _LegSelectorTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedBackground,
    required this.selectedBorder,
    required this.onTap,
    required this.labelFontSize,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedBackground;
  final Color selectedBorder;
  final VoidCallback onTap;
  final double labelFontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const borderIdle = Color(0xFFE2E8F0);
    final idleBg = theme.colorScheme.surface;
    final fg = selected ? Colors.white : Colors.black87;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? selectedBackground : idleBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? selectedBorder : borderIdle,
              width: 1.2,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: _kReferralShareRowMinHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, color: fg, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: fg,
                        fontSize: labelFontSize.clamp(10.0, 20.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportAssistanceCard extends StatelessWidget {
  const _SupportAssistanceCard();

  static const _supportPhone = '8307599904';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const callBlue = Color(0xFF2563EB);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorderColor(context)),
        boxShadow: _softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.headset_mic_rounded, color: callBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need assistance?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "We're online 24/7 to help with payouts, teams or compliance questions.",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () async {
              final uri = Uri(scheme: 'tel', path: _supportPhone);
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please call: $_supportPhone'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please call: $_supportPhone'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: callBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.phone_forwarded_rounded),
            label: const Text(
              'Request a call',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroSection extends StatelessWidget {
  const _ProfileHeroSection({required this.availableWidth});

  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final isCompact = availableWidth < 420;
    final headerHeight = isCompact ? 260.0 : 320.0;
    final totalHeight = headerHeight;
    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
                height: headerHeight,
                child:
                    _ProfileHeader(isCompact: isCompact, height: headerHeight)),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.isCompact, required this.height});

  final bool isCompact;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ProfileProvider.of(context).data;
    final hasPhoto = profile.photoUrl.trim().isNotEmpty;
    final ImageProvider? avatarImage =
        hasPhoto ? _buildImageProvider(profile.photoUrl) : null;

    final avatarRadius = isCompact ? 50.0 : 54.0;
    final pillPadding = EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16, vertical: isCompact ? 6 : 8);

    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: height - (isCompact ? 20 : 30),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF0F3D2E),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _HeaderIconButton(
                        icon: Icons.arrow_back,
                        onPressed: () => Navigator.of(context).maybePop(),
                        foregroundColor: Colors.white,
                      ),
                      const Spacer(),
                      _HeaderIconButton(
                        icon: Icons.edit_outlined,
                        onPressed: () => Navigator.of(context)
                            .pushNamed(ProfileEditScreen.routeName),
                        foregroundColor: Colors.white,
                      ),
                    ],
                  ),
                  SizedBox(height: isCompact ? 16 : 24),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _ProfileAvatar(
                          radius: avatarRadius,
                          image: avatarImage,
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                profile.name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: isCompact ? 20 : 22,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Partner ID · ${profile.partnerId}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: isCompact ? 10 : 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (profile.email.isNotEmpty) ...[
                                _buildContactInfo(
                                  context,
                                  Icons.email_outlined,
                                  profile.email,
                                  isCompact,
                                ),
                                const SizedBox(height: 2),
                              ],
                              if (profile.phone.isNotEmpty) ...[
                                _buildContactInfo(
                                  context,
                                  Icons.phone_outlined,
                                  profile.phone,
                                  isCompact,
                                ),
                                const SizedBox(height: 2),
                              ],
                              if (_getFullAddress(profile).isNotEmpty) ...[
                                _buildContactInfo(
                                  context,
                                  Icons.location_on_outlined,
                                  _getFullAddress(profile),
                                  isCompact,
                                ),
                                const SizedBox(height: 4),
                              ],
                              Container(
                                padding: pillPadding,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488),
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.emoji_events_rounded,
                                        color: Colors.white, size: 15),
                                    const SizedBox(width: 6),
                                    Text(
                                      profile.membershipTier,
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: isCompact ? 10 : 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(
      BuildContext context, IconData icon, String text, bool isCompact) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.7),
          size: isCompact ? 12 : 14,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: isCompact ? 9 : 10,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  String _getFullAddress(ProfileData profile) {
    final parts = <String>[];
    if (profile.address.isNotEmpty) parts.add(profile.address);
    if (profile.city.isNotEmpty) parts.add(profile.city);
    if (profile.state.isNotEmpty) parts.add(profile.state);
    return parts.join(', ');
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.radius, required this.image});

  final double radius;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.5 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFE8DCC8),
        backgroundImage: image,
        child: image == null
            ? Icon(
                Icons.person_rounded,
                size: radius * 1.1,
                color: Colors.white.withValues(alpha: 0.95),
              )
            : null,
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton(
      {required this.icon,
      required this.onPressed,
      required this.foregroundColor});

  final IconData icon;
  final VoidCallback onPressed;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.18),
        foregroundColor: foregroundColor,
        minimumSize: const Size(40, 40),
        padding: EdgeInsets.zero,
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

class _ProfileQRCodeSection extends StatelessWidget {
  const _ProfileQRCodeSection();

  Future<void> _pickAndUpload(BuildContext context) async {
    final profileState = ProfileProvider.of(context, listen: false);
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // Show loading
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final bytes = await image.readAsBytes();
      final uploadResult = await CloudinaryService.instance.uploadImage(
        bytes: bytes,
        filename: image.name,
      );
      await profileState.updateQrCode(uploadResult.url);
      if (context.mounted) Navigator.pop(context); // Close loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR Code updated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Close loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload QR Code: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ProfileProvider.of(context).data;
    final qrCodeUrl = profile.qrCodeUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorderColor(context)),
        boxShadow: _softShadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: qrCodeUrl == null ? () => _pickAndUpload(context) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment QR Code',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          qrCodeUrl != null
                              ? 'Tap to update your payment QR'
                              : 'Upload for easier payments',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (qrCodeUrl != null)
                    IconButton.filledTonal(
                      onPressed: () => _pickAndUpload(context),
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
              if (qrCodeUrl != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        qrCodeUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        },
                        errorBuilder: (context, error, stack) => const Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

double _responsiveSidePadding(double width) {
  if (width >= 1400) return (width - 960) / 2;
  if (width >= 1100) return 96;
  if (width >= 900) return 72;
  if (width >= 720) return 56;
  if (width >= 520) return 32;
  return 16;
}

Color _surfaceColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? const Color(0xFF0F172A)
      : Colors.white;
}

Color _cardBorderColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.12)
      : const Color(0xFFE2E8F0);
}

List<BoxShadow> _softShadow(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return [
    BoxShadow(
      color: isDark
          ? Colors.black.withValues(alpha: 0.45)
          : Colors.black.withValues(alpha: 0.08),
      blurRadius: 26,
      offset: const Offset(0, 16),
    ),
  ];
}

final NumberFormat _currencyFormatter =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

String _formatCurrency(double value) => _currencyFormatter.format(value);
