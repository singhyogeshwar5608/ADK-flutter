import 'package:flutter/widgets.dart';

import '../services/api_client.dart';
import '../utils/media_url.dart';

class ProfileData {
  const ProfileData({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.partnerId,
    required this.membershipTier,
    required this.photoUrl,
    required this.followers,
    required this.following,
    required this.level,
    required this.totalIncome,
    required this.incomeGoal,
    required this.monthlyGrowthPercent,
    this.photoPublicId,
    this.walletBalance,
    this.leftLegBv,
    this.rightLegBv,
    this.totalMatchedBv,
    this.directIncome,
    this.matchingIncome,
    this.weeklyIncome,
    this.bankAccountNumber,
    this.bankAccountImageUrl,
    this.aadharNumber,
    this.aadharImageUrl,
    this.panNumber,
    this.panImageUrl,
    this.selfPurchaseIncome,
    this.selfRepurchaseIncome,
    this.mlmSponsorIncome,
    this.repurchaseMatchingIncome,
    this.sponsorAwardKitIncome,
    this.placementLeg,
  });

  final String name;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String partnerId;
  final String membershipTier;
  final String photoUrl;
  final int followers;
  final int following;
  final String level;
  final double totalIncome;
  final double incomeGoal;
  final double monthlyGrowthPercent;
  final String? photoPublicId;
  final double? walletBalance;
  final double? leftLegBv;
  final double? rightLegBv;
  final double? totalMatchedBv;
  final double? directIncome;
  final double? matchingIncome;
  final double? weeklyIncome;
  final String? bankAccountNumber;
  final String? bankAccountImageUrl;
  final String? aadharNumber;
  final String? aadharImageUrl;
  final String? panNumber;
  final String? panImageUrl;
  /// From `income.selfPurchase` (auth/me).
  final double? selfPurchaseIncome;
  /// From `income.selfRepurchaseIncome`.
  final double? selfRepurchaseIncome;
  /// From `income.sponsorIncome` (transaction-based sponsor).
  final double? mlmSponsorIncome;
  /// From `income.repurchaseMatchingIncome`.
  final double? repurchaseMatchingIncome;
  /// From `income.sponsorAwardKitRepurchaseIncome`.
  final double? sponsorAwardKitIncome;
  /// Member tree leg `LEFT` / `RIGHT` for referral defaults.
  final String? placementLeg;

  bool get isBankKycComplete {
    final n = bankAccountNumber?.trim() ?? '';
    final u = bankAccountImageUrl?.trim() ?? '';
    return n.isNotEmpty && u.isNotEmpty;
  }

  bool get isAadharKycComplete {
    final n = aadharNumber?.trim() ?? '';
    final u = aadharImageUrl?.trim() ?? '';
    return n.isNotEmpty && u.isNotEmpty;
  }

  bool get isPanKycComplete {
    final n = panNumber?.trim() ?? '';
    final u = panImageUrl?.trim() ?? '';
    return n.isNotEmpty && u.isNotEmpty;
  }

  ProfileData copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? partnerId,
    String? membershipTier,
    String? photoUrl,
    int? followers,
    int? following,
    String? level,
    double? totalIncome,
    double? incomeGoal,
    double? monthlyGrowthPercent,
    String? photoPublicId,
    double? walletBalance,
    double? leftLegBv,
    double? rightLegBv,
    double? totalMatchedBv,
    double? directIncome,
    double? matchingIncome,
    double? weeklyIncome,
    String? bankAccountNumber,
    String? bankAccountImageUrl,
    String? aadharNumber,
    String? aadharImageUrl,
    String? panNumber,
    String? panImageUrl,
    double? selfPurchaseIncome,
    double? selfRepurchaseIncome,
    double? mlmSponsorIncome,
    double? repurchaseMatchingIncome,
    double? sponsorAwardKitIncome,
    String? placementLeg,
  }) {
    return ProfileData(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      partnerId: partnerId ?? this.partnerId,
      membershipTier: membershipTier ?? this.membershipTier,
      photoUrl: photoUrl ?? this.photoUrl,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      level: level ?? this.level,
      totalIncome: totalIncome ?? this.totalIncome,
      incomeGoal: incomeGoal ?? this.incomeGoal,
      monthlyGrowthPercent: monthlyGrowthPercent ?? this.monthlyGrowthPercent,
      photoPublicId: photoPublicId ?? this.photoPublicId,
      walletBalance: walletBalance ?? this.walletBalance,
      leftLegBv: leftLegBv ?? this.leftLegBv,
      rightLegBv: rightLegBv ?? this.rightLegBv,
      totalMatchedBv: totalMatchedBv ?? this.totalMatchedBv,
      directIncome: directIncome ?? this.directIncome,
      matchingIncome: matchingIncome ?? this.matchingIncome,
      weeklyIncome: weeklyIncome ?? this.weeklyIncome,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankAccountImageUrl: bankAccountImageUrl ?? this.bankAccountImageUrl,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      aadharImageUrl: aadharImageUrl ?? this.aadharImageUrl,
      panNumber: panNumber ?? this.panNumber,
      panImageUrl: panImageUrl ?? this.panImageUrl,
      selfPurchaseIncome: selfPurchaseIncome ?? this.selfPurchaseIncome,
      selfRepurchaseIncome: selfRepurchaseIncome ?? this.selfRepurchaseIncome,
      mlmSponsorIncome: mlmSponsorIncome ?? this.mlmSponsorIncome,
      repurchaseMatchingIncome:
          repurchaseMatchingIncome ?? this.repurchaseMatchingIncome,
      sponsorAwardKitIncome:
          sponsorAwardKitIncome ?? this.sponsorAwardKitIncome,
      placementLeg: placementLeg ?? this.placementLeg,
    );
  }
}

class ProfileState extends ChangeNotifier {
  ProfileState() {
    _init();
  }

  final ApiClient _apiClient = ApiClient.instance;
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;
  bool _isAuthenticated = false;
  ProfileData _data = _guestProfile;

  ProfileData get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      final member =
          await _apiClient.fetchCurrentMember(autoAuthenticate: false);
      _error = null;
      updateFromMemberPayload(member);
    } on StateError {
      resetToGuest();
    } catch (error, stack) {
      _error = error.toString();
      debugPrint('Failed to load profile: $error');
      debugPrintStack(stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void update(ProfileData data) {
    _data = data;
    notifyListeners();
  }

  void updateFields({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? partnerId,
    String? membershipTier,
    String? photoUrl,
    String? photoPublicId,
    int? followers,
    int? following,
    String? level,
    double? totalIncome,
    double? incomeGoal,
    double? monthlyGrowthPercent,
    double? walletBalance,
    double? leftLegBv,
    double? rightLegBv,
    double? totalMatchedBv,
    double? directIncome,
    double? matchingIncome,
    double? weeklyIncome,
    String? bankAccountNumber,
    String? bankAccountImageUrl,
    String? aadharNumber,
    String? aadharImageUrl,
    String? panNumber,
    String? panImageUrl,
    double? selfPurchaseIncome,
    double? selfRepurchaseIncome,
    double? mlmSponsorIncome,
    double? repurchaseMatchingIncome,
    double? sponsorAwardKitIncome,
    String? placementLeg,
  }) {
    _data = _data.copyWith(
      name: name,
      email: email,
      phone: phone,
      address: address,
      city: city,
      state: state,
      partnerId: partnerId,
      membershipTier: membershipTier,
      photoUrl: photoUrl,
      photoPublicId: photoPublicId,
      followers: followers,
      following: following,
      level: level,
      totalIncome: totalIncome,
      incomeGoal: incomeGoal,
      monthlyGrowthPercent: monthlyGrowthPercent,
      walletBalance: walletBalance,
      leftLegBv: leftLegBv,
      rightLegBv: rightLegBv,
      totalMatchedBv: totalMatchedBv,
      directIncome: directIncome,
      matchingIncome: matchingIncome,
      weeklyIncome: weeklyIncome,
      bankAccountNumber: bankAccountNumber,
      bankAccountImageUrl: bankAccountImageUrl,
      aadharNumber: aadharNumber,
      aadharImageUrl: aadharImageUrl,
      panNumber: panNumber,
      panImageUrl: panImageUrl,
      selfPurchaseIncome: selfPurchaseIncome,
      selfRepurchaseIncome: selfRepurchaseIncome,
      mlmSponsorIncome: mlmSponsorIncome,
      repurchaseMatchingIncome: repurchaseMatchingIncome,
      sponsorAwardKitIncome: sponsorAwardKitIncome,
      placementLeg: placementLeg,
    );
    notifyListeners();
  }

  /// Maps Laravel `auth/me` payload (`toArray` snake_case + camelCase extras).
  void updateFromMemberPayload(Map<String, dynamic> member) {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    String? str(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    Map<String, dynamic> kycFromMember(Map<String, dynamic> m) {
      final nested = m['kyc'];
      if (nested is Map<String, dynamic>) return nested;
      return {
        'bankAccount': {
          'number': m['bank_account_number'],
          'image': m['bank_account_image'],
        },
        'aadharCard': {
          'number': m['aadhar_number'],
          'image': m['aadhar_image'],
        },
        'panCard': {
          'number': m['pan_number'],
          'image': m['pan_image'],
        },
      };
    }

    String? docNum(Map<String, dynamic>? doc) {
      if (doc == null) return null;
      return str(doc['number']);
    }

    String? docImg(Map<String, dynamic>? doc) {
      if (doc == null) return null;
      final raw = doc['image'] as String?;
      if (raw == null || raw.trim().isEmpty) return null;
      return normalizeMediaUrl(raw.trim());
    }

    final wallet = member['wallet'];
    final matchingPairs =
        member['matchingPairs'] ?? member['matching_pairs'];
    final income = member['income'];
    final kyc = kycFromMember(member);

    String? bankNum;
    String? bankImgUrl;
    String? aadharNum;
    String? aadharImgUrl;
    String? panNum;
    String? panImgUrl;

    final bank = kyc['bankAccount'] ?? kyc['bank_account'];
    if (bank is Map<String, dynamic>) {
      bankNum = docNum(bank);
      bankImgUrl = docImg(bank);
    }
    final aadhar = kyc['aadharCard'] ?? kyc['aadhar_card'];
    if (aadhar is Map<String, dynamic>) {
      aadharNum = docNum(aadhar);
      aadharImgUrl = docImg(aadhar);
    }
    final pan = kyc['panCard'] ?? kyc['pan_card'];
    if (pan is Map<String, dynamic>) {
      panNum = docNum(pan);
      panImgUrl = docImg(pan);
    }

    double? leftBv = matchingPairs is Map<String, dynamic>
        ? toDouble(matchingPairs['leftLeg'] ?? matchingPairs['left_leg'])
        : null;
    double? rightBv = matchingPairs is Map<String, dynamic>
        ? toDouble(matchingPairs['rightLeg'] ?? matchingPairs['right_leg'])
        : null;
    final totalMatchedBv = matchingPairs is Map<String, dynamic>
        ? toDouble(
            matchingPairs['totalMatched'] ?? matchingPairs['total_matched'],
          )
        : null;
    if (member['bv'] is Map<String, dynamic>) {
      final bv = member['bv'] as Map<String, dynamic>;
      leftBv ??= toDouble(bv['leftLeg'] ?? bv['left_leg']);
      rightBv ??= toDouble(bv['rightLeg'] ?? bv['right_leg']);
    }

    _isAuthenticated = true;

    final rawPhoto = str(member['profileImage'] ?? member['profile_image']);
    final photoUrl = rawPhoto != null ? normalizeMediaUrl(rawPhoto) : '';

    final stats = member['stats'];
    final directRefs = stats is Map<String, dynamic>
        ? toInt(stats['directRefs'] ?? stats['direct_refs'])
        : null;
    final teamSize = stats is Map<String, dynamic>
        ? toInt(stats['teamSize'] ?? stats['team_size'])
        : null;

    double? incD(String camel, [String? snake]) {
      if (income is! Map<String, dynamic>) return null;
      final m = income;
      return toDouble(m[camel]) ?? (snake != null ? toDouble(m[snake]) : null);
    }

    final role = str(member['role']) ?? 'Member';
    final placement = str(member['leg'])?.toUpperCase();
    final totalEarned = wallet is Map<String, dynamic>
        ? (toDouble((wallet as Map)['totalEarned'] ??
                (wallet as Map)['total_earned']) ??
            0.0)
        : 0.0;

    updateFields(
      name: str(member['fullName'] ?? member['full_name']) ?? '',
      email: str(member['email']) ?? '',
      phone: str(member['phone']) ?? '',
      address: str(member['address']) ?? '',
      city: str(member['city']) ?? '',
      state: str(member['state']) ?? '',
      partnerId: str(member['memberId'] ?? member['member_id']) ?? '',
      membershipTier: role,
      level: role,
      photoUrl: photoUrl,
      photoPublicId:
          str(member['profilePublicId'] ?? member['profile_public_id']),
      followers: directRefs ?? 0,
      following: teamSize ?? 0,
      totalIncome: totalEarned,
      incomeGoal: wallet is Map<String, dynamic>
          ? toDouble((wallet as Map)['incomeGoal'] ??
              (wallet as Map)['income_goal'])
          : null,
      monthlyGrowthPercent: wallet is Map<String, dynamic>
          ? toDouble((wallet as Map)['monthlyGrowth'] ??
              (wallet as Map)['monthly_growth'])
          : null,
      walletBalance: wallet is Map<String, dynamic>
          ? toDouble((wallet as Map)['balance'])
          : null,
      leftLegBv: leftBv,
      rightLegBv: rightBv,
      totalMatchedBv: totalMatchedBv,
      directIncome: incD('direct'),
      matchingIncome: incD('matching'),
      weeklyIncome: incD('weekly'),
      selfPurchaseIncome: incD('selfPurchase', 'self_purchase'),
      selfRepurchaseIncome:
          incD('selfRepurchaseIncome', 'self_repurchase_income'),
      mlmSponsorIncome: incD('sponsorIncome', 'sponsor_income'),
      repurchaseMatchingIncome:
          incD('repurchaseMatchingIncome', 'repurchase_matching_income'),
      sponsorAwardKitIncome: incD(
        'sponsorAwardKitRepurchaseIncome',
        'sponsor_award_kit_repurchase_income',
      ),
      bankAccountNumber: bankNum,
      bankAccountImageUrl: bankImgUrl,
      aadharNumber: aadharNum,
      aadharImageUrl: aadharImgUrl,
      panNumber: panNum,
      panImageUrl: panImgUrl,
      placementLeg: placement,
    );
  }

  void resetToGuest() {
    _isAuthenticated = false;
    _error = null;
    _data = _guestProfile;
    notifyListeners();
  }
}

/// Shown when there is no valid session (no fake demo user).
const ProfileData _guestProfile = ProfileData(
  name: '',
  email: '',
  phone: '',
  address: '',
  city: '',
  state: '',
  partnerId: '',
  membershipTier: 'Guest',
  photoUrl: '',
  followers: 0,
  following: 0,
  level: '',
  totalIncome: 0,
  incomeGoal: 0,
  monthlyGrowthPercent: 0,
  photoPublicId: null,
);

class ProfileProvider extends InheritedNotifier<ProfileState> {
  const ProfileProvider({
    super.key,
    required ProfileState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ProfileState of(BuildContext context, {bool listen = true}) {
    if (listen) {
      final provider =
          context.dependOnInheritedWidgetOfExactType<ProfileProvider>();
      assert(provider != null, 'No ProfileProvider found in context');
      return provider!.notifier!;
    }
    final element =
        context.getElementForInheritedWidgetOfExactType<ProfileProvider>();
    assert(element != null, 'No ProfileProvider found in context');
    final provider = element!.widget as ProfileProvider;
    return provider.notifier!;
  }
}
