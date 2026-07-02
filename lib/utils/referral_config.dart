import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Signup page base (no trailing `/`).
String referralSignupBaseUrl() {
  return dotenv.env['REFERRAL_SIGNUP_BASE_URL'] ??
      'https://master.d1yeg5lmbstgw1.amplifyapp.com/members/signup';
}
