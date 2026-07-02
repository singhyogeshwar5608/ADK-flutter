import '../utils/media_url.dart';

class MemberSummary {
  const MemberSummary({
    required this.id,
    required this.memberId,
    required this.fullName,
    this.email,
    this.status,
    this.profileImage,
    this.qrCodeUrl,
    this.teamSize,
    this.activeTeam,
    this.inactiveTeam,
    this.totalBv,
    this.totalTeamBV,
    this.bvLeftLeg,
    this.bvRightLeg,
    this.weakLeg,
    this.location,
    this.contactPhone,
    this.walletBalance,
    this.createdAt,
    this.type,
  });

  final String id;
  final String memberId;
  final String fullName;
  final String? email;
  final String? status;
  final String? profileImage;
  final String? qrCodeUrl;
  final int? teamSize;
  final int? activeTeam;
  final int? inactiveTeam;
  final double? totalBv;
  final double? totalTeamBV;
  final double? bvLeftLeg;
  final double? bvRightLeg;
  final String? weakLeg;
  final String? location;
  final String? contactPhone;
  final String? walletBalance;
  final String? createdAt;
  final String? type;

  factory MemberSummary.fromJson(Map<String, dynamic> json) {
    final fullName = json['fullName'] ?? json['name'];
    return MemberSummary(
      id: json['id']?.toString() ?? '',
      memberId: json['memberId']?.toString() ?? '',
      fullName: fullName?.toString() ?? json['memberId']?.toString() ?? '',
      email: json['email']?.toString(),
      status: json['status']?.toString(),
      profileImage: _normProfile(json['profileImage']?.toString()),
      qrCodeUrl: _normProfile(json['qrCodeUrl']?.toString()),
      teamSize: json['stats']?['teamSize'] as int? ?? json['teamSize'] as int?,
      activeTeam: json['stats']?['activeTeam'] as int?,
      inactiveTeam: json['stats']?['inactiveTeam'] as int?,
      totalBv: (json['totalBv'] as num?)?.toDouble(),
      totalTeamBV: (json['stats']?['totalTeamBV'] as num?)?.toDouble(),
      bvLeftLeg: (json['bvLeftLeg'] as num?)?.toDouble(),
      bvRightLeg: (json['bvRightLeg'] as num?)?.toDouble(),
      weakLeg: json['weakLeg']?.toString(),
      location: json['address']?.toString() ?? json['location']?.toString(),
      contactPhone:
          json['phone']?.toString() ?? json['contactPhone']?.toString(),
      walletBalance: json['wallet']?['balance']?.toString() ??
          json['walletBalance']?.toString(),
      createdAt: json['createdAt']?.toString(),
      type: json['type']?.toString(),
    );
  }

  static String? _normProfile(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    return normalizeMediaUrl(url);
  }
}
