import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../services/api_client.dart';
import '../state/profile_state.dart';
import '../theme/app_theme.dart';
import '../utils/referral_config.dart';
import '../utils/share_referral.dart';

/// Dedicated referral hub (always uses [AppTheme.lightTheme]).
class MyReferralScreen extends StatefulWidget {
  const MyReferralScreen({super.key});

  static const routeName = '/my-referral';

  @override
  State<MyReferralScreen> createState() => _MyReferralScreenState();
}

class _MyReferralScreenState extends State<MyReferralScreen> {
  late String _leg;
  String? _serverLinkLeft;
  String? _serverLinkRight;

  @override
  void initState() {
    super.initState();
    _leg = 'LEFT';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final placement =
          ProfileProvider.of(context, listen: false).data.placementLeg;
      if (placement != null && placement.toUpperCase() == 'RIGHT') {
        setState(() => _leg = 'RIGHT');
      }
      _loadServerReferralLinks();
    });
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
    final base = referralSignupBaseUrl();
    if (base.isEmpty) return '';
    final ref = Uri.encodeQueryComponent(partnerId);
    final leg = Uri.encodeQueryComponent(_leg);
    return '$base?ref=$ref&leg=$leg';
  }

  String _linkForDisplay(String partnerId) {
    return _buildLink(partnerId);
  }

  Future<void> _copyLink(String link) async {
    if (link.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied')),
    );
  }

  Future<void> _shareLink(String link) async {
    if (link.isEmpty) return;
    const title = 'ADK referral';
    final text = 'Join me on ADK: $link';

    if (kIsWeb) {
      final shared = await shareReferralNativeWeb(
        title: title,
        text: text,
        url: link,
      );
      if (shared) return;
      await Clipboard.setData(ClipboardData(text: link));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Web Share is not available here — your referral link was copied.',
          ),
        ),
      );
      return;
    }

    await Share.share(text, subject: title);
  }

  static const _legIcon = Icons.keyboard_double_arrow_right_rounded;

  @override
  Widget build(BuildContext context) {
    final profileState = ProfileProvider.of(context);
    return Theme(
      data: AppTheme.lightTheme,
      child: ListenableBuilder(
        listenable: profileState,
        builder: (context, _) {
          final theme = Theme.of(context);
          final profile = profileState.data;
          final partnerId = profile.partnerId.trim();
          final link = partnerId.isEmpty ? '' : _linkForDisplay(partnerId);
          final direct = profile.followers;
          final total = profile.following;

          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              foregroundColor: theme.colorScheme.onSurface,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                'My Referral',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              centerTitle: true,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: const Color(0xFFE2E8F0),
                ),
              ),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    children: [
                      _ReferralLinkPanel(
                        leg: _leg,
                        link: link,
                        onLegChanged: (v) => setState(() => _leg = v),
                        onCopy: () => _copyLink(link),
                        legIcon: _legIcon,
                      ),
                      const SizedBox(height: 16),
                      _ReferralCodePanel(code: partnerId),
                      const SizedBox(height: 16),
                      _ReferralStatsPanel(
                        direct: direct,
                        total: total,
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SafeArea(
                    top: false,
                    child: FilledButton.icon(
                      onPressed:
                          link.isEmpty ? null : () => _shareLink(link),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 22),
                      label: const Text(
                        'Share Referral Link',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReferralLinkPanel extends StatelessWidget {
  const _ReferralLinkPanel({
    required this.leg,
    required this.link,
    required this.onLegChanged,
    required this.onCopy,
    required this.legIcon,
  });

  final String leg;
  final String link;
  final ValueChanged<String> onLegChanged;
  final VoidCallback onCopy;
  final IconData legIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your Referral Link',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick left or right leg — the link includes leg=LEFT or leg=RIGHT '
            'for new signups.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: [
              ButtonSegment<String>(
                value: 'LEFT',
                label: const Text('Left leg'),
                icon: Icon(legIcon, size: 18),
              ),
              ButtonSegment<String>(
                value: 'RIGHT',
                label: const Text('Right leg'),
                icon: Icon(legIcon, size: 18),
              ),
            ],
            selected: {leg},
            onSelectionChanged: (s) {
              if (s.isNotEmpty) onLegChanged(s.first);
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.white,
              selectedBackgroundColor: const Color(0xFF22C55E),
              selectedForegroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    link.isEmpty ? '—' : link,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                      height: 1.35,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: link.isEmpty ? null : onCopy,
                  icon: const Icon(Icons.copy_rounded, color: Color(0xFF475569)),
                  tooltip: 'Copy',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Share this link with friends to earn rewards!',
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralCodePanel extends StatelessWidget {
  const _ReferralCodePanel({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = code.isEmpty ? '—' : code;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your Referral Code',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.code_rounded, color: Color(0xFF2563EB), size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    display,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2563EB),
                      letterSpacing: 0.3,
                    ),
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

class _ReferralStatsPanel extends StatelessWidget {
  const _ReferralStatsPanel({
    required this.direct,
    required this.total,
  });

  final int direct;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const green = Color(0xFF22C55E);
    const blue = Color(0xFF2563EB);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Referral Statistics',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.person_add_alt_1_rounded,
                  value: '$direct',
                  label: 'Direct Referrals',
                  accent: green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.groups_rounded,
                  value: '$total',
                  label: 'Total Referrals',
                  accent: blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: accent, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
