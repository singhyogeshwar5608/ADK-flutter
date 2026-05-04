import 'package:flutter/material.dart';

import '../models/member_summary.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'member_detail_screen.dart';

class MyTeamScreen extends StatefulWidget {
  const MyTeamScreen({super.key});

  static const routeName = '/my-team';

  @override
  State<MyTeamScreen> createState() => _MyTeamScreenState();
}

enum TeamFilter { all, active, pending }

extension TeamFilterLabel on TeamFilter {
  String get label {
    switch (this) {
      case TeamFilter.all:
        return 'All';
      case TeamFilter.active:
        return 'Active';
      case TeamFilter.pending:
        return 'Pending';
    }
  }
}

class _MyTeamScreenState extends State<MyTeamScreen> {
  TeamFilter _selectedFilter = TeamFilter.all;
  List<MemberSummary> _allMembers = [];
  bool _isLoading = true;
  int _newThisWeek = 0;
  int _pendingKyc = 0;
  int _totalActive = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('Loading team members...');
      final members = await ApiClient.instance.fetchTeamMembers(limit: 1000);
      print('Loaded ${members.length} team members');
      print(
          'First member: ${members.isNotEmpty ? members.first.fullName : 'None'}');
      print('Member IDs: ${members.map((m) => m.memberId).take(3).join(', ')}');

      // Fetch team stats
      try {
        final teamStats = await ApiClient.instance.fetchTeamStats();
        print('Team stats: $teamStats');
        setState(() {
          _allMembers = members;
          _newThisWeek = teamStats['newThisWeek'] ?? 0;
          _pendingKyc = teamStats['pendingKyc'] ?? 0;
          _totalActive = teamStats['totalActive'] ?? 0;
          print(
              'Updated state - New this week: $_newThisWeek, Pending KYC: $_pendingKyc, Total Active: $_totalActive');
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading team stats: $e');
        // Calculate fallback values from members list
        final startOfWeek =
            DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
        final activeMembers =
            members.where((m) => m.status == 'ACTIVE').toList();
        final newThisWeekFallback = activeMembers.where((m) {
          if (m.createdAt == null || m.createdAt!.isEmpty) return false;
          final createdAt = DateTime.tryParse(m.createdAt!);
          return createdAt != null && createdAt.isAfter(startOfWeek);
        }).length;
        // Count members who haven't made purchases (assuming wallet balance indicates purchases)
        final pendingKycFallback = members
            .where((m) => m.status == 'ACTIVE')
            .where((m) => m.walletBalance == '0.00' || m.walletBalance == '0')
            .length;

        setState(() {
          _allMembers = members;
          _newThisWeek = newThisWeekFallback;
          _pendingKyc = pendingKycFallback;
          _totalActive = activeMembers.length;
          print(
              'Fallback case - New this week: $_newThisWeek, Pending KYC: $_pendingKyc, Total Active: $_totalActive');
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading members: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<MemberSummary> get _filteredMembers {
    if (_selectedFilter == TeamFilter.all) return _allMembers;

    switch (_selectedFilter) {
      case TeamFilter.active:
        // Filter members with ACTIVE status
        final activeMembers =
            _allMembers.where((m) => m.status == 'ACTIVE').toList();
        print('Active filter: Found ${activeMembers.length} active members');
        return activeMembers;
      case TeamFilter.pending:
        // Filter members who are pending (not ACTIVE status - includes SUSPENDED, PENDING, etc)
        final pendingMembers = _allMembers
            .where((m) =>
                m.status != 'ACTIVE' &&
                m.status != null &&
                m.status!.isNotEmpty)
            .toList();
        print('Pending filter: Found ${pendingMembers.length} pending members');
        print(
            'All member statuses: ${_allMembers.map((m) => '${m.memberId}: ${m.status}').join(', ')}');
        return pendingMembers;
      default:
        return _allMembers;
    }
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
            final padding = constraints.maxWidth >= 1024
                ? 64.0
                : constraints.maxWidth >= 768
                    ? 48.0
                    : constraints.maxWidth >= 540
                        ? 32.0
                        : 16.0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _MyTeamHeader(),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: _MyTeamBody(
                      selectedFilter: _selectedFilter,
                      onFilterChanged: (value) =>
                          setState(() => _selectedFilter = value),
                      members: _filteredMembers,
                      isLoading: _isLoading,
                      error: _error,
                      allMembers: _allMembers,
                      onRefresh: _loadMembers,
                      newThisWeek: _newThisWeek,
                      pendingKyc: _pendingKyc,
                      totalActive: _totalActive,
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

class _MyTeamHeader extends StatelessWidget {
  const _MyTeamHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final border = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(bottom: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: theme.colorScheme.onSurface,
            splashRadius: 24,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              'My Team',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _MyTeamBody extends StatelessWidget {
  _MyTeamBody({
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.members,
    this.isLoading = false,
    this.error,
    this.allMembers = const [],
    this.onRefresh,
    required this.newThisWeek,
    required this.pendingKyc,
    required this.totalActive,
  });

  final TeamFilter selectedFilter;
  final ValueChanged<TeamFilter> onFilterChanged;
  final List<MemberSummary> members;
  final bool isLoading;
  final String? error;
  final List<MemberSummary> allMembers;
  final VoidCallback? onRefresh;
  final int newThisWeek;
  final int pendingKyc;
  final int totalActive;

  static const double _monthlyGrowth = 0.128; // 12.8%

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Error: $error',
                  textAlign: TextAlign.center,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRefresh,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh?.call(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TeamOverviewCard(
              monthlyGrowth: _monthlyGrowth,
              totalMembers: allMembers.length,
              activeMembers: totalActive,
              newThisWeek: newThisWeek,
            ),
            const SizedBox(height: 20),
            _TeamStatsGrid(
              activeMembers: totalActive,
              newThisWeek: newThisWeek,
              pendingKyc: pendingKyc,
            ),
            const SizedBox(height: 24),
            Text('Segments',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _FilterWrap(selected: selectedFilter, onSelected: onFilterChanged),
            const SizedBox(height: 24),
            Text('Team Members (${members.length})',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (members.isEmpty)
              _EmptyMembersState(selectedFilter: selectedFilter)
            else ...[
              for (final member in members) ...[
                _TeamMemberTile(
                  member: member,
                  onTap: () => Navigator.of(context).pushNamed(
                    MemberDetailScreen.routeName,
                    arguments: _mapMemberToDetailArgs(member),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }

  MemberDetailArguments _mapMemberToDetailArgs(MemberSummary member) {
    // Determine weak leg based on BV values
    String weakLeg = 'Balanced';
    if (member.bvLeftLeg != null && member.bvRightLeg != null) {
      if (member.bvLeftLeg! < member.bvRightLeg!) {
        weakLeg = 'Left';
      } else if (member.bvRightLeg! < member.bvLeftLeg!) {
        weakLeg = 'Right';
      }
    } else if (member.weakLeg != null) {
      weakLeg = member.weakLeg!;
    }

    return MemberDetailArguments(
      memberId: member.memberId,
      name: member.fullName,
      role: 'Member',
      rankLabel: 'MEMBER',
      rankColor: const Color(0xFF2B9DEE),
      avatarUrl: member.profileImage ?? '',
      status: member.status?.toLowerCase() ?? 'active',
      totalBv: member.totalTeamBV?.toInt() ?? 0,
      teamSize: member.teamSize ?? 0,
      weakLeg: weakLeg,
      location: member.location ?? 'Not specified',
      contactEmail: member.email ?? 'n/a',
      contactPhone: member.contactPhone ?? 'n/a',
      joinedAgo: 'Recently',
      growth: 0.0,
      focusAreas: const ['Growth', 'Training'],
    );
  }
}

class _TeamOverviewCard extends StatelessWidget {
  _TeamOverviewCard({
    required this.monthlyGrowth,
    required this.totalMembers,
    required this.activeMembers,
    required this.newThisWeek,
  });

  final double monthlyGrowth;
  final int totalMembers;
  final int activeMembers;
  final int newThisWeek;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final growthPercent = (monthlyGrowth * 100).toStringAsFixed(1);

    final hasNewMembers = newThisWeek >= 0;
    final arrowIcon = hasNewMembers
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    final arrowColor =
        hasNewMembers ? const Color(0xFF10B981) : const Color(0xFFE11D48);
    final newUsersLabel = '${newThisWeek.abs()} users';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
        child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: SizedBox(
          height: 152,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Team',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  letterSpacing: 0.8,
                  fontSize: ((theme.textTheme.labelSmall?.fontSize ?? 11) - 4)
                      .clamp(8.0, 20.0),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$totalMembers members',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: ((theme.textTheme.headlineSmall?.fontSize ?? 24) - 4)
                        .clamp(16.0, 30.0),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: _OverviewStatCard(
                          label: 'Active',
                          value: '$activeMembers',
                          dense: true)),
                  const SizedBox(width: 6),
                  Expanded(
                      child: _OverviewStatCard(
                          label: 'Leaders', value: '0', dense: true)),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                        child: _OverviewChip(
                            icon: Icons.bolt,
                            label: '$growthPercent% growth',
                            dense: true)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _NewMembersTile(
                        arrowIcon: arrowIcon,
                        arrowColor: arrowColor,
                        label: newUsersLabel,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewMembersTile extends StatelessWidget {
  const _NewMembersTile(
      {required this.arrowIcon,
      required this.arrowColor,
      required this.label,
      required this.theme});

  final IconData arrowIcon;
  final Color arrowColor;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(arrowIcon, size: 15, color: arrowColor),
              const SizedBox(width: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'New members',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStatCard extends StatelessWidget {
  const _OverviewStatCard(
      {required this.label, required this.value, this.dense = false});

  final String label;
  final String value;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 12, vertical: dense ? 6 : 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 0.5,
                  fontSize: ((Theme.of(context).textTheme.labelSmall?.fontSize ??
                              11) -
                          2)
                      .clamp(8.0, 14.0),
                ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (dense
                    ? Theme.of(context).textTheme.titleSmall
                    : Theme.of(context).textTheme.titleMedium)
                ?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: dense ? 16 : 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamStatsGrid extends StatelessWidget {
  _TeamStatsGrid({
    required this.activeMembers,
    required this.newThisWeek,
    required this.pendingKyc,
  });

  final int activeMembers;
  final int newThisWeek;
  final int pendingKyc;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.people_alt,
            label: 'Active Members',
            value: activeMembers.toString(),
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.person_add,
            label: 'New This Week',
            value: newThisWeek.toString(),
            color: const Color(0xFF2B9DEE),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.pending_actions,
            label: 'Pending KYC',
            value: pendingKyc.toString(),
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      constraints: const BoxConstraints(minHeight: 0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: ((theme.textTheme.labelSmall?.fontSize ?? 11) - 1.5)
                  .clamp(9.0, 13.0),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: ((theme.textTheme.titleMedium?.fontSize ?? 16) - 2)
                  .clamp(13.0, 20.0),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterWrap extends StatelessWidget {
  const _FilterWrap({required this.selected, required this.onSelected});

  final TeamFilter selected;
  final ValueChanged<TeamFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipFont =
        ((theme.textTheme.labelLarge?.fontSize ?? 14) - 2).clamp(11.0, 16.0);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: TeamFilter.values.map((filter) {
        final isSelected = selected == filter;
        return FilterChip(
          label: Text(
            filter.label,
            style: TextStyle(
              fontSize: chipFont,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          selected: isSelected,
          onSelected: (value) => onSelected(filter),
          backgroundColor: theme.colorScheme.surface,
          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          labelStyle: TextStyle(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          side: BorderSide(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
          ),
        );
      }).toList(),
    );
  }
}

class _TeamMemberTile extends StatelessWidget {
  const _TeamMemberTile({required this.member, this.onTap});

  final MemberSummary member;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bvNum = member.totalTeamBV ?? member.totalBv;
    final bvValue = bvNum != null ? '${bvNum.toStringAsFixed(0)} BV' : '0 BV';
    String weakLeg = 'Balanced';
    if (member.bvLeftLeg != null && member.bvRightLeg != null) {
      if (member.bvLeftLeg! < member.bvRightLeg!) {
        weakLeg = 'Left';
      } else if (member.bvRightLeg! < member.bvLeftLeg!) {
        weakLeg = 'Right';
      }
    } else if (member.weakLeg != null && member.weakLeg!.isNotEmpty) {
      weakLeg = member.weakLeg!;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              member.fullName.isNotEmpty
                  ? member.fullName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  member.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: ((theme.textTheme.titleSmall?.fontSize ?? 14) - 1)
                        .clamp(12.0, 18.0),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.email ?? 'member@example.com',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    fontSize: ((theme.textTheme.bodySmall?.fontSize ?? 12) - 1)
                        .clamp(10.0, 14.0),
                  ),
                ),
                const SizedBox(height: 6),
                _StatBadge(
                  icon: Icons.stacked_line_chart,
                  label: bvValue,
                ),
                if (onTap != null) ...[
                  const SizedBox(height: 4),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onTap,
                    child: Text(
                      'View member',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: ((theme.textTheme.labelMedium?.fontSize ?? 12) -
                                1)
                            .clamp(10.0, 14.0),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Weak leg',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                weakLeg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyMembersState extends StatelessWidget {
  const _EmptyMembersState({required this.selectedFilter});

  final TeamFilter selectedFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'No members in ${selectedFilter.label}',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Invite partners or adjust filters to see more teammates.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewChip extends StatelessWidget {
  const _OverviewChip(
      {required this.icon, required this.label, this.dense = false});

  final IconData icon;
  final String label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10, vertical: dense ? 6 : 8);
    final iconSize = dense ? 15.0 : 18.0;
    final spacing = dense ? 3.0 : 4.0;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: Colors.white),
          SizedBox(height: spacing),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
