class MemberNode {
  const MemberNode({
    required this.id,
    required this.memberId,
    required this.fullName,
    required this.role,
    required this.type,
    required this.status,
    required this.placementPath,
    required this.depth,
    this.leg,
    this.profileImage,
    this.qrCodeUrl,
    this.sponsorId,
    this.email,
    this.phone,
    this.address,
    this.walletBalance = 0,
    this.walletTotalEarned = 0,
    this.bvTotal = 0,
    this.bvLeftLeg = 0,
    this.bvRightLeg = 0,
    this.teamSize = 0,
    this.activeTeam = 0,
    this.inactiveTeam = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String memberId;
  final String fullName;
  final String role;
  final String type;
  final String status;
  final String placementPath;
  final int depth;
  final String? leg;
  final String? profileImage;
  final String? qrCodeUrl;
  final String? sponsorId;
  final String? email;
  final String? phone;
  final String? address;
  final double walletBalance;
  final double walletTotalEarned;
  final double bvTotal;
  final double bvLeftLeg;
  final double bvRightLeg;
  final int teamSize;
  final int activeTeam;
  final int inactiveTeam;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory MemberNode.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    final wallet = json['wallet'] as Map<String, dynamic>?;
    final bv = json['bv'] as Map<String, dynamic>?;
    final stats = json['stats'] as Map<String, dynamic>?;

    return MemberNode(
      id: (json['id'] ?? '').toString(),
      memberId: (json['memberId'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      type: (json['type'] ?? 'USER').toString(),
      status: (json['status'] ?? '').toString(),
      placementPath: (json['placementPath'] ?? '').toString(),
      depth: (json['depth'] as num?)?.toInt() ?? 0,
      leg: json['leg'] as String?,
      profileImage: json['profileImage'] as String?,
      qrCodeUrl: json['qrCodeUrl'] as String?,
      sponsorId: json['sponsorId'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      walletBalance: (wallet?['balance'] as num?)?.toDouble() ?? 0,
      walletTotalEarned: (wallet?['totalEarned'] as num?)?.toDouble() ?? 0,
      bvTotal: (bv?['total'] as num?)?.toDouble() ?? 0,
      bvLeftLeg: (bv?['leftLeg'] as num?)?.toDouble() ?? 0,
      bvRightLeg: (bv?['rightLeg'] as num?)?.toDouble() ?? 0,
      teamSize: (stats?['teamSize'] as num?)?.toInt() ?? 0,
      activeTeam: (stats?['activeTeam'] as num?)?.toInt() ?? 0,
      inactiveTeam: (stats?['inactiveTeam'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}

class MemberTree {
  const MemberTree({
    required this.root,
    required this.nodes,
    required this.depthLimit,
  });

  final MemberNode root;
  final List<MemberNode> nodes;
  final int depthLimit;

  factory MemberTree.fromJson(Map<String, dynamic> json) {
    final root = MemberNode.fromJson(json['root'] as Map<String, dynamic>);
    final nodes = (json['nodes'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MemberNode.fromJson)
        .toList();

    final depthLimitValue = json['meta']?['depthLimit'];
    int depthLimit = 3;
    if (depthLimitValue is num) {
      depthLimit = depthLimitValue.toInt();
    } else if (depthLimitValue is String) {
      depthLimit = int.tryParse(depthLimitValue) ?? 3;
    }

    // Remove duplicate root if backend includes it in nodes list
    final seenPaths = <String>{root.placementPath};
    final uniqueNodes = [root, ...nodes.where((n) => seenPaths.add(n.placementPath))];

    return MemberTree(
      root: root,
      nodes: uniqueNodes,
      depthLimit: depthLimit,
    );
  }

  Map<String, MemberNode> toPathMap() {
    return {for (final node in nodes) node.placementPath: node};
  }

  /// Returns nodes grouped by depth, normalized so root is depth 0.
  Map<int, List<MemberNode>> groupedByDepth() {
    final minDepth = root.depth;
    final levels = <int, List<MemberNode>>{};

    for (final node in nodes) {
      final level = node.depth - minDepth;
      levels.putIfAbsent(level, () => []).add(node);
    }

    return levels;
  }
}
