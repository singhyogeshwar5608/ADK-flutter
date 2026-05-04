/// Non-web: no URL query (use route [arguments] only).
class ReferralSignupQuery {
  const ReferralSignupQuery({this.referralCode, this.leg});

  final String? referralCode;
  final String? leg;
}

ReferralSignupQuery parseReferralSignupFromUrl() => const ReferralSignupQuery();
