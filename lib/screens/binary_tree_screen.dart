import 'package:flutter/material.dart';

import '../models/member_tree.dart';
import '../services/api_client.dart';
import '../state/profile_state.dart';
import '../widgets/safe_network_image.dart';
import 'member_detail_screen.dart';
import 'register_member_screen.dart';

// ---------------------------------------------------------------------------
// Layout constants — all nodes share the exact same dimensions
// ---------------------------------------------------------------------------
const double _nodeWidth = 80;
const double _nodeHeight = 54;
const double _hGap = 8;
const double _vGap = 10;
const double _padding = 12;

// ---------------------------------------------------------------------------
// Internal layout node
// ---------------------------------------------------------------------------
class _LayoutNode {
  final MemberNode member;
  _LayoutNode? left;
  _LayoutNode? right;
  double x = 0; // centre x, global
  double y = 0; // top y, global
  double subtreeW = _nodeWidth;

  _LayoutNode({required this.member});
}

// ---------------------------------------------------------------------------
// Build the layout tree from the flat pathMap  (step 1)
// ---------------------------------------------------------------------------
_LayoutNode _buildLayoutTree(
  MemberNode node,
  Map<String, MemberNode> pathMap,
  int maxDepth,
) {
  final ln = _LayoutNode(member: node);
  final childDepth = node.depth + 1;
  if (childDepth > maxDepth) return ln;

  final lp = '${node.placementPath}.L', rp = '${node.placementPath}.R';
  if (pathMap.containsKey(lp)) ln.left = _buildLayoutTree(pathMap[lp]!, pathMap, maxDepth);
  if (pathMap.containsKey(rp)) ln.right = _buildLayoutTree(pathMap[rp]!, pathMap, maxDepth);
  return ln;
}

// ---------------------------------------------------------------------------
// First pass bottom-up: compute subtree widths (step 2)
// ---------------------------------------------------------------------------
double _calcWidths(_LayoutNode n, int maxDepth) {
  final below = n.member.depth + 1 <= maxDepth;
  final lw = n.left != null ? _calcWidths(n.left!, maxDepth) : 0.0;
  final rw = n.right != null ? _calcWidths(n.right!, maxDepth) : 0.0;

  final spaceL = below && n.left == null ? _nodeWidth : lw;
  final spaceR = below && n.right == null ? _nodeWidth : rw;

  double total = 0;
  if (spaceL > 0 && spaceR > 0) {
    total = spaceL + _hGap + spaceR;
  } else {
    total = spaceL + spaceR;
  }
  n.subtreeW = total > _nodeWidth ? total : _nodeWidth;
  return n.subtreeW;
}

// ---------------------------------------------------------------------------
// Second pass top-down: assign x,y positions (step 3)
// ---------------------------------------------------------------------------
void _assignYs(_LayoutNode n, double y) {
  n.y = y;
  if (n.left != null) _assignYs(n.left!, y + _nodeHeight + _vGap);
  if (n.right != null) _assignYs(n.right!, y + _nodeHeight + _vGap);
}

void _assignXs(_LayoutNode n, int maxDepth) {
  final below = n.member.depth + 1 <= maxDepth;
  final spaceL = below && n.left == null ? _nodeWidth : (n.left?.subtreeW ?? 0);
  final spaceR = below && n.right == null ? _nodeWidth : (n.right?.subtreeW ?? 0);
  final both = spaceL > 0 && spaceR > 0;

  if (both) {
    final span = spaceL + _hGap + spaceR;
    if (n.left != null) {
      n.left!.x = n.x - span / 2 + spaceL / 2;
      _assignXs(n.left!, maxDepth);
    }
    if (n.right != null) {
      n.right!.x = n.x + span / 2 - spaceR / 2;
      _assignXs(n.right!, maxDepth);
    }
  } else {
    if (n.left != null) {
      n.left!.x = n.x;
      _assignXs(n.left!, maxDepth);
    }
    if (n.right != null) {
      n.right!.x = n.x;
      _assignXs(n.right!, maxDepth);
    }
  }
}

// ---------------------------------------------------------------------------
// Collect all rendered positions (real nodes + empty slots)
// ---------------------------------------------------------------------------
class _SlotPos {
  const _SlotPos({required this.x, required this.y, required this.isLeft, required this.parentPath});
  final double x, y;
  final bool isLeft;
  final String parentPath;
}

void _collectSlots(_LayoutNode n, int maxDepth, List<_SlotPos> out) {
  final below = n.member.depth + 1 <= maxDepth;
  if (!below) {
    if (n.left != null) _collectSlots(n.left!, maxDepth, out);
    if (n.right != null) _collectSlots(n.right!, maxDepth, out);
    return;
  }

  final hasLeft = n.left != null;
  final hasRight = n.right != null;
  final childY = n.y + _nodeHeight + _vGap;

  final leftW = hasLeft ? n.left!.subtreeW : _nodeWidth;
  final rightW = hasRight ? n.right!.subtreeW : _nodeWidth;
  final both = leftW > 0 && rightW > 0;
  final span = both ? leftW + _hGap + rightW : (leftW > 0 ? leftW : (rightW > 0 ? rightW : 0));

  if (!hasLeft) {
    final sx = both ? n.x - span / 2 + leftW / 2 : n.x;
    out.add(_SlotPos(x: sx, y: childY, isLeft: true, parentPath: n.member.placementPath));
  }
  if (!hasRight) {
    final sx = both ? n.x + span / 2 - rightW / 2 : n.x;
    out.add(_SlotPos(x: sx, y: childY, isLeft: false, parentPath: n.member.placementPath));
  }

  if (n.left != null) _collectSlots(n.left!, maxDepth, out);
  if (n.right != null) _collectSlots(n.right!, maxDepth, out);
}

// What we need to render: real node at each layout node.
// The layout is a single level – we collect everything into a flat list.
Map<String, _LayoutNode> _flatten(_LayoutNode root) {
  final out = <String, _LayoutNode>{};
  void walk(_LayoutNode n) {
    out[n.member.placementPath] = n;
    if (n.left != null) walk(n.left!);
    if (n.right != null) walk(n.right!);
  }
  walk(root);
  return out;
}

// ===========================================================================
// Screen
// ===========================================================================

class BinaryTreeScreen extends StatefulWidget {
  const BinaryTreeScreen({super.key, this.memberId, this.depthLimit = 10});

  static const routeName = '/binary-tree';

  final String? memberId;
  final int depthLimit;

  @override
  State<BinaryTreeScreen> createState() => _BinaryTreeScreenState();
}

class _BinaryTreeScreenState extends State<BinaryTreeScreen> {
  late Future<MemberTree> _future;
  late String _currentRoot;
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _currentRoot = widget.memberId ?? _resolveMemberId();
    _future = _loadTree();
    _transformationController.addListener(() {
      if (!mounted) return;
      final s = _transformationController.value.getMaxScaleOnAxis();
      if (!s.isNaN && s != _currentScale) {
        setState(() => _currentScale = s.clamp(0.1, 3.0));
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    _currentScale = (_currentScale * 1.5).clamp(0.1, 3.0);
    if (_currentScale.isNaN) _currentScale = 1.0;
    _transformationController.value = Matrix4.identity()..scale(_currentScale);
  }

  void _zoomOut() {
    _currentScale = (_currentScale / 1.5).clamp(0.1, 3.0);
    if (_currentScale.isNaN) _currentScale = 1.0;
    _transformationController.value = Matrix4.identity()..scale(_currentScale);
  }

  void _resetZoom() {
    _currentScale = 1.0;
    _transformationController.value = Matrix4.identity();
  }

  Future<MemberTree> _loadTree() async {
    try {
      return await ApiClient.instance.fetchMemberTree(
        memberId: _currentRoot,
        depth: widget.depthLimit,
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<void> _refresh() async {
    setState(() => _future = _loadTree());
    await _future;
  }

  String _resolveMemberId() {
    try {
      final pid = ProfileProvider.of(context, listen: false).data.partnerId.trim();
      if (pid.isNotEmpty) return pid;
    } catch (_) {}
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF101A22) : const Color(0xFFF6F7F8);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Row(
          children: [
            Flexible(
              child: Text('Binary Tree',
                  style: theme.textTheme.titleLarge, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                '${(_currentScale.isNaN ? 100 : (_currentScale * 100).toInt())}%',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.primaryColor, fontWeight: FontWeight.w600, fontSize: 10),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: _zoomOut,
              tooltip: 'Zoom Out'),
          IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: _zoomIn,
              tooltip: 'Zoom In'),
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
              tooltip: 'Refresh tree'),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<MemberTree>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _TreeError(onRetry: _refresh, error: snapshot.error);
            }
            final tree = snapshot.data;
            if (tree == null) {
              return _TreeError(onRetry: _refresh, error: 'Unable to load tree data.');
            }
            return Column(
              children: [
                const _TreeInfoBanner(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 0.1,
                      maxScale: 3.0,
                      boundaryMargin: const EdgeInsets.all(200),
                      constrained: false,
                      child: _TreeCanvas(tree: tree),
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

// ---------------------------------------------------------------------------
// Info banner
// ---------------------------------------------------------------------------
class _TreeInfoBanner extends StatelessWidget {
  const _TreeInfoBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Tap a member to view details'.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Tree canvas — coordinate-based layout
// ===========================================================================

class _TreeCanvas extends StatelessWidget {
  const _TreeCanvas({required this.tree});
  final MemberTree tree;

  @override
  Widget build(BuildContext context) {
    final pathMap = tree.toPathMap();
    final maxDepth = tree.root.depth + tree.depthLimit;

    // ---- compute layout ---------------------------------------------------
    final layoutRoot = _buildLayoutTree(tree.root, pathMap, maxDepth);
    _calcWidths(layoutRoot, maxDepth);
    _assignYs(layoutRoot, 0);
    layoutRoot.x = 0;
    _assignXs(layoutRoot, maxDepth);

    final allNodes = _flatten(layoutRoot);
    final slots = <_SlotPos>[];
    _collectSlots(layoutRoot, maxDepth, slots);

    // Include any orphaned nodes (members in pathMap not reached by recursive walk)
    for (final entry in pathMap.entries) {
      if (!allNodes.containsKey(entry.key)) {
        final orphan = _LayoutNode(member: entry.value);
        orphan.x = 0;
        orphan.y = orphan.member.depth * (_nodeHeight + _vGap);
        allNodes[entry.key] = orphan;
      }
    }

    // ---- bounding box -----------------------------------------------------
    double bMin = double.infinity, bMax = double.negativeInfinity;
    for (final n in allNodes.values) {
      final l = n.x - _nodeWidth / 2, r = n.x + _nodeWidth / 2;
      if (l < bMin) bMin = l;
      if (r > bMax) bMax = r;
    }
    for (final s in slots) {
      final l = s.x - _nodeWidth / 2, r = s.x + _nodeWidth / 2;
      if (l < bMin) bMin = l;
      if (r > bMax) bMax = r;
    }
    double bMaxY = 0;
    for (final n in allNodes.values) {
      final ny = n.y + _nodeHeight;
      if (ny > bMaxY) bMaxY = ny;
    }
    for (final s in slots) {
      final sy = s.y + _nodeHeight;
      if (sy > bMaxY) bMaxY = sy;
    }
    final totalW = bMax - bMin + _nodeWidth + _padding * 2;
    final treeH = bMaxY + _padding;

    return SizedBox(
      width: totalW.clamp(300, double.infinity),
      height: treeH.clamp(200, double.infinity),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // connector lines
          Positioned.fill(
            child: CustomPaint(
              painter: _TreeConnectorPainter(
                nodes: allNodes,
                slots: slots,
                offsetX: -bMin + _padding,
                offsetY: _padding / 2,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
            ),
          ),
          // real nodes
          for (final ln in allNodes.values)
            Positioned(
              left: ln.x - bMin - _nodeWidth / 2 + _padding,
              top: ln.y + _padding / 2,
              child: _MemberNodeCard(node: ln.member),
            ),
          // empty slots
          for (final s in slots)
            Positioned(
              left: s.x - bMin - _nodeWidth / 2 + _padding,
              top: s.y + _padding / 2,
              child: _EmptySlot(isLeft: s.isLeft, sponsorId: pathMap[s.parentPath]?.memberId ?? ''),
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Connector-line painter
// ===========================================================================

class _TreeConnectorPainter extends CustomPainter {
  _TreeConnectorPainter({
    required this.nodes,
    required this.slots,
    required this.offsetX,
    required this.offsetY,
    required this.color,
  });

  final Map<String, _LayoutNode> nodes;
  final List<_SlotPos> slots;
  final double offsetX, offsetY;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void drawLine(double x1, double y1, double x2, double y2) {
      canvas.drawLine(Offset(x1 + offsetX, y1 + offsetY), Offset(x2 + offsetX, y2 + offsetY), paint);
    }

    void drawConnector(double px, double pBot, double cx, double cTop) {
      final midY = pBot + (cTop - pBot) / 2;
      drawLine(px, pBot, px, midY);
      drawLine(px, midY, cx, midY);
      drawLine(cx, midY, cx, cTop);
    }

    for (final ln in nodes.values) {
      final pBot = ln.y + _nodeHeight;
      if (ln.left != null) drawConnector(ln.x, pBot, ln.left!.x, ln.left!.y);
      if (ln.right != null) drawConnector(ln.x, pBot, ln.right!.x, ln.right!.y);
    }

    for (final s in slots) {
      final parent = nodes[s.parentPath];
      if (parent == null) continue;
      drawConnector(parent.x, parent.y + _nodeHeight, s.x, s.y);
    }
  }

  @override
  bool shouldRepaint(covariant _TreeConnectorPainter old) =>
      old.nodes != nodes || old.slots != slots || old.color != color;
}

// ===========================================================================
// Fixed-size member card  (144 × 106)
// ===========================================================================

class _MemberNodeCard extends StatelessWidget {
  const _MemberNodeCard({required this.node});
  final MemberNode node;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = node.status.toLowerCase();

    final statusUpper = status.toUpperCase();

    Color bgColor;
    Color borderColor;
    String statusLabel;
    if (statusUpper == 'ACTIVE' || statusUpper == 'APPROVED') {
      bgColor = const Color(0xFF16A34A);
      borderColor = const Color(0xFF15803D);
      statusLabel = 'Active';
    } else if (statusUpper == 'PENDING') {
      bgColor = const Color(0xFFCA8A04);
      borderColor = const Color(0xFFA16207);
      statusLabel = 'Pending';
    } else {
      bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
      borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
      statusLabel = status;
    }

    return SizedBox(
      width: _nodeWidth,
      height: _nodeHeight,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _openMemberDetail(context, node),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor, width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipOval(
                  child: node.profileImage?.isNotEmpty == true
                      ? SafeNetworkImage(
                          src: node.profileImage!,
                          width: 14,
                          height: 14,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _initials(node.fullName),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 6),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 1),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                      decoration: BoxDecoration(
                        color: node.type == 'LEADER'
                            ? const Color(0xFFD97706)
                            : const Color(0xFF9333EA),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        node.type == 'LEADER' ? 'Leader' : 'User',
                        style: const TextStyle(
                          fontSize: 5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  node.memberId ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 5,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  node.fullName.isEmpty ? 'Unnamed' : node.fullName,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 6,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 2).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ===========================================================================
// Empty slot — exactly the same dimensions as a real node
// ===========================================================================

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.isLeft, required this.sponsorId});
  final bool isLeft;
  final String sponsorId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return SizedBox(
      width: _nodeWidth,
      height: _nodeHeight,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => Navigator.of(context).pushNamed(
            RegisterMemberScreen.routeName,
            arguments: {
              'sponsorId': sponsorId,
              'leg': isLeft ? 'LEFT' : 'RIGHT',
            },
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.35), width: 0.5),
              color: color.withValues(alpha: 0.04),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_alt_1, color: color.withValues(alpha: 0.6), size: 12),
                const SizedBox(height: 1),
                Text(
                  isLeft ? 'L' : 'R',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: 6,
                    height: 1,
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

// ===========================================================================
// Error state
// ===========================================================================

class _TreeError extends StatelessWidget {
  const _TreeError({required this.onRetry, this.error});
  final VoidCallback onRetry;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text('Unable to load binary tree.',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                child: Text(error?.toString() ?? 'Unknown error',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 10),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Navigation helper
// ===========================================================================

void _openMemberDetail(BuildContext context, MemberNode node) {
  final joined = node.createdAt;
  final joinedAgo = joined == null
      ? 'Recently joined'
      : '${DateTime.now().difference(joined).inDays} days ago';
  final weakLeg = node.bvLeftLeg >= node.bvRightLeg ? 'Right' : 'Left';

  Navigator.of(context).pushNamed(
    MemberDetailScreen.routeName,
    arguments: MemberDetailArguments(
      memberId: node.memberId,
      name: node.fullName,
      role: node.type == 'LEADER' ? 'Leader' : 'User',
      rankLabel: node.type == 'LEADER' ? 'LEADER' : 'USER',
      rankColor: node.leg?.toUpperCase() == 'RIGHT'
          ? const Color(0xFF10B981)
          : const Color(0xFF2B9DEE),
      avatarUrl: node.profileImage ?? '',
      status: node.status,
      totalBv: node.bvTotal.round(),
      teamSize: node.teamSize,
      activeTeam: node.activeTeam,
      inactiveTeam: node.inactiveTeam,
      weakLeg: weakLeg,
      location: node.address?.isNotEmpty == true ? node.address! : 'Not specified',
      contactEmail: node.email ?? 'n/a',
      contactPhone: node.phone ?? 'n/a',
      joinedAgo: joinedAgo,
      growth: 0.18,
      focusAreas: const ['Growth', 'Training'],
      qrCodeUrl: node.qrCodeUrl,
    ),
  );
}
