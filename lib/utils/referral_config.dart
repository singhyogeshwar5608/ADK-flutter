import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Signup page base (no trailing `/`). Prefer `REFERRAL_SIGNUP_BASE_URL` in `assets/dotenv` or `--dart-define`.
String referralSignupBaseUrl() {
  const fromDefine = String.fromEnvironment(
    'REFERRAL_SIGNUP_BASE_URL',
    defaultValue: '',
  );
  final defineTrim = fromDefine.trim();
  if (defineTrim.isNotEmpty) {
    return defineTrim.replaceAll(RegExp(r'/+$'), '');
  }
  final v = dotenv.env['REFERRAL_SIGNUP_BASE_URL']?.trim();
  if (v != null && v.isNotEmpty) {
    return v.replaceAll(RegExp(r'/+$'), '');
  }
  return '';
}
