import 'package:flutter/material.dart';

import '../models/member_tree.dart';
import '../services/api_client.dart';
import '../widgets/safe_network_image.dart';
import 'member_detail_screen.dart';
import 'register_member_screen.dart';

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
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _currentRoot = widget.memberId ?? 'root';
    print(
        'BinaryTreeScreen: Initialized with memberId: ${widget.memberId}, _currentRoot: $_currentRoot');
    _future = _loadTree();

    // Add listener to track scale changes from user interactions
    _transformationController.addListener(() {
      if (!mounted) return;
      final matrix = _transformationController.value;
      final scale = matrix.getMaxScaleOnAxis();
      if (!scale.isNaN && scale != _currentScale) {
        setState(() {
          _currentScale = scale.clamp(0.1, 3.0);
        });
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      _currentScale = (_currentScale * 1.5).clamp(0.1, 3.0);
      if (_currentScale.isNaN) _currentScale = 1.0;
      _transformationController.value = Matrix4.identity()
        ..scale(_currentScale);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentScale = (_currentScale / 1.5).clamp(0.1, 3.0);
      if (_currentScale.isNaN) _currentScale = 1.0;
      _transformationController.value = Matrix4.identity()
        ..scale(_currentScale);
    });
  }

  void _resetZoom() {
    setState(() {
      _currentScale = 1.0;
      _transformationController.value = Matrix4.identity();
    });
  }

  Future<MemberTree> _loadTree() async {
    print(
        '🌳 Loading binary tree for member: $_currentRoot, depth: ${widget.depthLimit}');
    try {
      final tree = await ApiClient.instance.fetchMemberTree(
        memberId: _currentRoot,
        depth: widget.depthLimit,
      );
      print('✅ Tree loaded successfully: ${tree.nodes.length} nodes');
      print('Root: ${tree.root.fullName}, Depth limit: ${tree.depthLimit}');
      return tree;
    } catch (e, stack) {
      print('❌ Error loading tree: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadTree();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF101A22) : const Color(0xFFF6F7F8);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              child: Text(
                'Binary Tree',
                style: theme.textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(_currentScale.isNaN ? 100 : (_currentScale * 100).toInt())}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: _zoomOut,
            tooltip: 'Zoom Out',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: _zoomIn,
            tooltip: 'Zoom In',
          ),
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
              return _TreeError(
                  onRetry: _refresh, error: 'Unable to load tree data.');
            }
            return RefreshIndicator(
                onRefresh: _refresh,
                child: _TreeContent(
                    tree: tree,
                    transformationController: _transformationController));
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tree content
// ---------------------------------------------------------------------------

class _TreeContent extends StatelessWidget {
  const _TreeContent(
      {required this.tree, required this.transformationController});
  final MemberTree tree;
  final TransformationController transformationController;

  @override
  Widget build(BuildContext context) {
    final pathMap = tree.toPathMap();
    final maxDepth = tree.root.depth + tree.depthLimit;

    print('🌳 TreeContent building...');
    print('   Root: ${tree.root.fullName} (${tree.root.placementPath})');
    print('   Total nodes: ${tree.nodes.length}');
    print('   PathMap keys: ${pathMap.keys.join(', ')}');
    print(
        '   Max depth: $maxDepth (root depth: ${tree.root.depth} + limit: ${tree.depthLimit})');

    return Column(
      children: [
        const _TreeInfoBanner(),
        Expanded(
          child: InteractiveViewer(
            transformationController: transformationController,
            minScale: 0.1,
            maxScale: 3.0,
            boundaryMargin: const EdgeInsets.all(100),
            constrained: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(50),
                child: _TreeNodeWidget(
                  node: tree.root,
                  pathMap: pathMap,
                  depth: tree.root.depth,
                  maxDepth: maxDepth,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recursive tree node
// ---------------------------------------------------------------------------

class _TreeNodeWidget extends StatelessWidget {
  const _TreeNodeWidget({
    required this.node,
    required this.pathMap,
    required this.depth,
    required this.maxDepth,
  });

  final MemberNode node;
  final Map<String, MemberNode> pathMap;
  final int depth;
  final int maxDepth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final childDepth = depth + 1;
    final canExpand = childDepth <= maxDepth;
    final leftPath = '${node.placementPath}.L';
    final rightPath = '${node.placementPath}.R';
    final leftNode = pathMap[leftPath];
    final rightNode = pathMap[rightPath];

    print('🌳 Building node: ${node.fullName} (${node.placementPath})');
    print('   Looking for left: $leftPath -> ${leftNode?.fullName ?? 'null'}');
    print(
        '   Looking for right: $rightPath -> ${rightNode?.fullName ?? 'null'}');
    print('   Total nodes in map: ${pathMap.length}');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MemberNodeCard(node: node),
        if (canExpand) ...[
          const SizedBox(height: 24),
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Diagonal connectors
              Positioned(
                top: -24,
                left: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(320, 30),
                  painter: _DiagonalConnectorsPainter(
                    color: theme.dividerColor.withValues(alpha: 0.7),
                    hasLeft: true,
                    hasRight: true,
                  ),
                ),
              ),
              // Children nodes
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (leftNode != null)
                      _TreeNodeWidget(
                          node: leftNode,
                          pathMap: pathMap,
                          depth: childDepth,
                          maxDepth: maxDepth)
                    else
                      _EmptySlot(leg: 'Left'),
                    const SizedBox(width: 40),
                    if (rightNode != null)
                      _TreeNodeWidget(
                          node: rightNode,
                          pathMap: pathMap,
                          depth: childDepth,
                          maxDepth: maxDepth)
                    else
                      _EmptySlot(leg: 'Right'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DiagonalConnectorsPainter extends CustomPainter {
  const _DiagonalConnectorsPainter({
    required this.color,
    required this.hasLeft,
    required this.hasRight,
  });
  final Color color;
  final bool hasLeft;
  final bool hasRight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final startY = 0.0;
    final endY = size.height;

    // Draw diagonal line to left child
    if (hasLeft) {
      final path = Path();
      path.moveTo(centerX, startY);
      path.lineTo(centerX - 60, endY);
      canvas.drawPath(path, paint);
    }

    // Draw diagonal line to right child
    if (hasRight) {
      final path = Path();
      path.moveTo(centerX, startY);
      path.lineTo(centerX + 60, endY);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Member card (rendered from API data)
// ---------------------------------------------------------------------------

class _MemberNodeCard extends StatelessWidget {
  const _MemberNodeCard({required this.node});
  final MemberNode node;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = node.status?.toLowerCase() == 'active';
    final borderColor = isActive
        ? const Color(0xFF10B981).withValues(alpha: 0.7)
        : const Color(0xFFE11D48).withValues(alpha: 0.7);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openMemberDetail(context, node),
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF1E293B),
                      const Color(0xFF0F172A),
                      const Color(0xFF020617)
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFF8FAFC),
                      const Color(0xFFF1F5F9)
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              ClipOval(
                child: node.profileImage?.isNotEmpty == true
                    ? SafeNetworkImage(
                        src: node.profileImage!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(node.fullName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                node.memberId ?? '',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                node.fullName.isEmpty ? 'Unnamed' : node.fullName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 2).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// Empty slot (register new member)
// ---------------------------------------------------------------------------

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.leg});
  final String leg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () =>
          Navigator.of(context).pushNamed(RegisterMemberScreen.routeName),
      child: Container(
        width: 70,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          color: color.withValues(alpha: 0.05),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_alt_1, color: color, size: 16),
            const SizedBox(height: 2),
            Text('Open $leg',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: color, fontWeight: FontWeight.w700, fontSize: 6)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats panel at the bottom
// ---------------------------------------------------------------------------

class _TreeStatsPanel extends StatelessWidget {
  const _TreeStatsPanel({required this.tree});
  final MemberTree tree;

  @override
  Widget build(BuildContext context) {
    final leftCount =
        tree.nodes.where((n) => n.leg?.toUpperCase() == 'LEFT').length;
    final rightCount =
        tree.nodes.where((n) => n.leg?.toUpperCase() == 'RIGHT').length;
    final totalBv = tree.nodes.fold<double>(0, (s, n) => s + n.bvTotal);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
            top: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.4))),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 1,
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _SummaryTile(
                      label: 'Total',
                      value: tree.nodes.length.toString(),
                      color: Colors.indigo))),
          Expanded(
              flex: 1,
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _SummaryTile(
                      label: 'Left',
                      value: leftCount.toString(),
                      color: const Color(0xFF2B9DEE)))),
          Expanded(
              flex: 1,
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _SummaryTile(
                      label: 'Right',
                      value: rightCount.toString(),
                      color: const Color(0xFF10B981)))),
          Expanded(
              flex: 1,
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _SummaryTile(
                      label: 'BV',
                      value: totalBv.toStringAsFixed(0),
                      color: Colors.orange))),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.08)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                  color: color, letterSpacing: 1, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Detail navigation helper
// ---------------------------------------------------------------------------

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
      role: node.role.isEmpty ? 'Partner' : node.role,
      rankLabel: node.role.isEmpty ? 'MEMBER' : node.role.toUpperCase(),
      rankColor: node.leg?.toUpperCase() == 'RIGHT'
          ? const Color(0xFF10B981)
          : const Color(0xFF2B9DEE),
      avatarUrl: node.profileImage ?? '',
      status: node.status,
      totalBv: node.bvTotal.round(),
      teamSize: node.teamSize,
      weakLeg: weakLeg,
      location: 'Not specified',
      contactEmail: node.email ?? 'n/a',
      contactPhone: node.phone ?? 'n/a',
      joinedAgo: joinedAgo,
      growth: 0.18,
      focusAreas: const ['Growth', 'Training'],
    ),
  );
}
