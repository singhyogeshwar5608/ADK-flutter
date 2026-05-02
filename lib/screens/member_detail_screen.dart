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
        actions: member == null
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () {},
                  tooltip: 'Share profile',
                ),
              ],
      ),
      body: member == null
          ? const Center(child: Text('Member details unavailable.'))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  children: [
                    _ProfileHero(member: member),
                    const SizedBox(height: 20),
                    _MetricsGrid(member: member),
                    const SizedBox(height: 20),
                    _ContactCard(member: member),
                    const SizedBox(height: 20),
                    _FocusAreas(member: member),
                    const SizedBox(height: 20),
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
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
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
                radius: 48,
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
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroChip(icon: Icons.military_tech, label: member.rankLabel),
                  _HeroChip(
                      icon: Icons.calendar_month, label: member.joinedAgo),
                  _HeroChip(icon: Icons.check_circle, label: member.status),
                ],
              ),
              const SizedBox(height: 18),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white70, fontSize: 10, letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
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
    final tiles = [
      _MetricTile(
          label: 'Total BV',
          value: member.totalBv.toString(),
          icon: Icons.stacked_line_chart),
      _MetricTile(
          label: 'Weak Leg', value: member.weakLeg, icon: Icons.alt_route),
      _MetricTile(
          label: 'Location', value: member.location, icon: Icons.location_on),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 480;
        if (isCompact) {
          return Column(
            children: [
              for (int i = 0; i < tiles.length; i++) ...[
                tiles[i],
                if (i != tiles.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: tiles
              .map((tile) => SizedBox(
                    width: (constraints.maxWidth - 12) / 2,
                    child: tile,
                  ))
              .toList(),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile(
      {required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(value,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceOverview extends StatelessWidget {
  const _PerformanceOverview({required this.member});

  final MemberDetailArguments member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlightColor = theme.colorScheme.primary;
    final engagement = (member.teamSize / 200).clamp(0.0, 1.0);
    final engagementLabel = '${(engagement * 100).round()}% active team';

    Widget performanceCard() {
      return _SurfaceCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: highlightColor),
                const SizedBox(width: 8),
                Text('Performance',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'BV Momentum',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 4),
            Text('${member.totalBv} pts',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: highlightColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_outward, color: highlightColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '+${(member.growth * 100).toStringAsFixed(1)}% vs last month',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: highlightColor, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget activityCard() {
      return _SurfaceCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard_customize_outlined, color: highlightColor),
                const SizedBox(width: 8),
                Text('Activity',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(
                    child: _MiniStatTile(
                        label: 'Active days', value: 'Current cycle')),
                SizedBox(width: 8),
                Expanded(
                    child: _MiniStatTile(
                        label: 'Weak leg', value: 'Monitor closely')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _MiniStatTile(
                        label: 'Team size',
                        value: '${member.teamSize} partners')),
                const SizedBox(width: 8),
                Expanded(
                    child: _MiniStatTile(
                        label: 'Weak leg focus', value: member.weakLeg)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Engagement',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: engagement,
                minHeight: 6,
                backgroundColor: theme.dividerColor.withValues(alpha: 0.4),
                valueColor: AlwaysStoppedAnimation<Color>(highlightColor),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              engagementLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: highlightColor, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              performanceCard(),
              const SizedBox(height: 12),
              activityCard(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: performanceCard()),
            const SizedBox(width: 12),
            Expanded(child: activityCard()),
          ],
        );
      },
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

class _MiniStatTile extends StatelessWidget {
  const _MiniStatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.member});

  final MemberDetailArguments member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_mail_outlined,
                  color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Contact & Location',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
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
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ContactRow(icon: Icons.location_pin, label: member.location),
          _ContactRow(icon: Icons.mail_outline, label: member.contactEmail),
          _ContactRow(icon: Icons.phone, label: member.contactPhone),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusAreas extends StatelessWidget {
  const _FocusAreas({required this.member});

  final MemberDetailArguments member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focus = member.focusAreas;

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.center_focus_strong, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Focus Areas',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          if (focus.isEmpty)
            Text('No focus areas have been assigned yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6)))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: focus
                  .map(
                    (area) => Chip(
                      label: Text(area),
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                      labelStyle: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  .toList(),
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

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Team Snapshot',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final isNarrow = constraints.maxWidth < 420;
              final columns = isNarrow ? 1 : 2;
              final tileWidth = isNarrow
                  ? constraints.maxWidth
                  : (constraints.maxWidth - spacing) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: stats
                    .map(
                      (stat) => SizedBox(
                        width: tileWidth,
                        child: _TeamStatPill(data: stat),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          if (priorities.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Immediate priorities',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 8),
            for (final priority in priorities)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(
                        child:
                            Text(priority, style: theme.textTheme.bodyMedium)),
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

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(data.value,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
