import 'package:flutter/material.dart';

class MemberDetailArguments {
  const MemberDetailArguments({
    required this.memberId,
    required this.name,
    required this.role,
    required this.rankLabel,
    required this.rankColor,
    required this.avatarUrl,
    required this.status,
    required this.totalBv,
    required this.teamSize,
    required this.weakLeg,
    required this.location,
    required this.contactEmail,
    required this.contactPhone,
    required this.joinedAgo,
    required this.growth,
    required this.focusAreas,
  });

  final String memberId;
  final String name;
  final String role;
  final String rankLabel;
  final Color rankColor;
  final String avatarUrl;
  final String status;
  final int totalBv;
  final int teamSize;
  final String weakLeg;
  final String location;
  final String contactEmail;
  final String contactPhone;
  final String joinedAgo;
  final double growth;
  final List<String> focusAreas;
}

class MemberDetailScreen extends StatelessWidget {
  const MemberDetailScreen({super.key});

  static const routeName = '/member-detail';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final member = args is MemberDetailArguments ? args : null;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(member?.name ?? 'Member details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: member == null
          ? const Center(child: Text('Member details unavailable.'))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  children: [
                    _ProfileHero(member: member),
                    const SizedBox(height: 16),
                    _MetricsGrid(member: member),
                    const SizedBox(height: 16),
                    _ContactCard(member: member),
                    const SizedBox(height: 16),
                    _TeamSnapshot(member: member),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.member});

  final MemberDetailArguments member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                member.rankColor.withValues(alpha: 0.92),
                member.rankColor.withValues(alpha: 0.65)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: member.rankColor.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage: member.avatarUrl.isNotEmpty
                    ? NetworkImage(member.avatarUrl)
                    : null,
                backgroundColor: member.avatarUrl.isNotEmpty
                    ? Colors.transparent
                    : theme.colorScheme.primary.withValues(alpha: 0.2),
                child: member.avatarUrl.isEmpty
                    ? Text(
                        member.name.isNotEmpty
                            ? member.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                member.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                member.role,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  member.memberId,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  _HeroChip(icon: Icons.military_tech, label: member.rankLabel),
                  _HeroChip(
                      icon: Icons.calendar_month, label: member.joinedAgo),
                  _HeroChip(icon: Icons.check_circle, label: member.status),
                ],
              ),
              const SizedBox(height: 12),
              _HeroStat(label: 'Team Size', value: member.teamSize.toString()),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 8,
              letterSpacing: 0.7,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.member});

  final MemberDetailArguments member;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Total BV',
                value: member.totalBv.toString(),
                icon: Icons.stacked_line_chart,
                compact: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricTile(
                label: 'Weak Leg',
                value: member.weakLeg,
                icon: Icons.alt_route,
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _MetricTile(
          label: 'Location',
          value: member.location,
          icon: Icons.location_on,
          compact: true,
          isLocation: true,
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.compact = false,
    this.isLocation = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool compact;
  final bool isLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pad = compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
        : const EdgeInsets.all(18);
    final iconBoxPad = compact ? 7.0 : 10.0;
    final iconSize = compact ? 16.0 : 20.0;
    final gapAfterIcon = compact ? 10.0 : 16.0;
    final labelGap = compact ? 3.0 : 6.0;

    final labelFs =
        ((theme.textTheme.labelSmall?.fontSize ?? 11) - 2).clamp(8.0, 20.0);
    final valueFs =
        ((theme.textTheme.titleMedium?.fontSize ?? 16) - 2).clamp(11.0, 24.0);
    final locFs =
        ((theme.textTheme.bodyMedium?.fontSize ?? 14) - 3).clamp(10.0, 22.0);

    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: compact ? 10 : 16,
            offset: Offset(0, compact ? 5 : 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(iconBoxPad),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(compact ? 11 : 14),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: iconSize),
          ),
          SizedBox(width: gapAfterIcon),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    letterSpacing: 0.6,
                    fontSize: labelFs,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: labelGap),
                Text(
                  value,
                  maxLines: isLocation ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: isLocation
                      ? theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: locFs,
                          height: 1.25,
                        )
                      : theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: valueFs,
                          height: 1.15,
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

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard(
      {required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.member});

  final MemberDetailArguments member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleFs =
        ((theme.textTheme.titleSmall?.fontSize ?? 14) - 2).clamp(11.0, 20.0);
    final bodyFs =
        ((theme.textTheme.bodyMedium?.fontSize ?? 14) - 2).clamp(11.0, 20.0);

    return _SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_mail_outlined,
                  color: theme.colorScheme.primary, size: 18),
              const SizedBox(width: 6),
              Text('Contact & Location',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: titleFs,
                  )),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  member.status,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ((theme.textTheme.labelSmall?.fontSize ?? 12) - 2)
                            .clamp(9.0, 16.0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ContactRow(
              icon: Icons.location_on_outlined,
              label: member.location,
              bodyFontSize: bodyFs),
          _ContactRow(icon: Icons.mail_outline, label: member.contactEmail, bodyFontSize: bodyFs),
          _ContactRow(icon: Icons.phone, label: member.contactPhone, bodyFontSize: bodyFs),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.bodyFontSize,
  });

  final IconData icon;
  final String label;
  final double bodyFontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: bodyFontSize,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamSnapshot extends StatelessWidget {
  const _TeamSnapshot({required this.member});

  final MemberDetailArguments member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = [
      _TeamStatData(
          icon: Icons.groups, label: 'Team Size', value: '${member.teamSize}'),
      _TeamStatData(
          icon: Icons.trending_up,
          label: 'Total BV',
          value: member.totalBv.toString()),
      _TeamStatData(
          icon: Icons.alt_route, label: 'Weak Leg', value: member.weakLeg),
    ];
    final priorities = member.focusAreas
        .take(3)
        .map((area) => 'Advance "$area" initiatives')
        .toList();

    final snapshotTitleFs =
        ((theme.textTheme.titleSmall?.fontSize ?? 14) - 2).clamp(11.0, 20.0);
    final priorityBodyFs =
        ((theme.textTheme.bodyMedium?.fontSize ?? 14) - 3).clamp(10.0, 22.0);

    return _SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_outlined,
                  color: theme.colorScheme.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'Team Snapshot',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: snapshotTitleFs,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: _TeamStatPill(data: stats[i])),
              ],
            ],
          ),
          if (priorities.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Immediate priorities',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: ((theme.textTheme.labelSmall?.fontSize ?? 11) - 2)
                    .clamp(8.0, 16.0),
              ),
            ),
            const SizedBox(height: 6),
            for (final priority in priorities)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        priority,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: priorityBodyFs,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TeamStatData {
  const _TeamStatData(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;
}

class _TeamStatPill extends StatelessWidget {
  const _TeamStatPill({required this.data});

  final _TeamStatData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final labelFs =
        ((theme.textTheme.labelSmall?.fontSize ?? 11) - 2).clamp(8.0, 18.0);
    final valueFs =
        ((theme.textTheme.titleMedium?.fontSize ?? 16) - 2).clamp(11.0, 22.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(data.icon, color: theme.colorScheme.primary, size: 17),
          const SizedBox(height: 6),
          Text(
            data.label.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 0.45,
              fontWeight: FontWeight.w700,
              fontSize: labelFs,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: valueFs,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
