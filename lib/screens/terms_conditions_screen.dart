import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const routeName = '/terms-conditions';

  static const Color _headingBlue = Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bodyColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    TextStyle heading() => TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: isDark ? _headingBlue : const Color(0xFF0284C7),
          height: 1.35,
        );

    TextStyle body() => TextStyle(
          fontSize: 15,
          height: 1.55,
          color: bodyColor,
        );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last updated: April 2024',
              style: TextStyle(fontSize: 13, color: mutedColor),
            ),
            const SizedBox(height: 20),
            Text('1. Agreement', style: heading()),
            const SizedBox(height: 8),
            Text(
              'By downloading or using the NetShop / ADK Partner application, you agree to these Terms & Conditions. If you do not agree, do not use the app.',
              style: body(),
            ),
            const SizedBox(height: 20),
            Text('2. Eligibility & account', style: heading()),
            const SizedBox(height: 8),
            Text(
              'You must provide accurate registration information and keep your credentials secure. You are responsible for activity under your account. We may suspend or terminate accounts that violate these terms or applicable law.',
              style: body(),
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                style: body(),
                children: [
                  const TextSpan(
                    text:
                        'To request account closure or deletion, or for other account-related information, email ',
                  ),
                  TextSpan(
                    text: 'adk99904@gmail.com',
                    style: body().copyWith(
                      color: AppColors.mlmGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(
                    text: ' from your registered email where possible.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('3. Services', style: heading()),
            const SizedBox(height: 8),
            Text(
              'The app provides partner and e-commerce related features as described in-app. Features may change; we do not guarantee uninterrupted or error-free operation.',
              style: body(),
            ),
            const SizedBox(height: 20),
            Text('4. Orders, wallet & payments', style: heading()),
            const SizedBox(height: 8),
            Text(
              'Orders, wallet top-ups, withdrawals, and commissions are subject to rules shown in the app and on our platforms. Third-party payment providers handle certain transactions; their terms may also apply.',
              style: body(),
            ),
            const SizedBox(height: 20),
            Text('5. Prohibited conduct', style: heading()),
            const SizedBox(height: 8),
            Text(
              'You must not misuse the app, attempt unauthorised access, interfere with other users, upload unlawful content, or use the service for fraud or illegal activity.',
              style: body(),
            ),
            const SizedBox(height: 20),
            Text('6. Intellectual property', style: heading()),
            const SizedBox(height: 8),
            Text(
              "App design, branding, and content provided by us remain our property or our licensors'. You may not copy or redistribute them except as allowed by law or express permission.",
              style: body(),
            ),
            const SizedBox(height: 20),
            Text('7. Disclaimer & limitation', style: heading()),
            const SizedBox(height: 8),
            Text(
              'The app is provided "as available". To the maximum extent permitted by law, we are not liable for indirect or consequential losses. Some jurisdictions do not allow certain limitations; in those cases our liability is limited to the fullest extent permitted.',
              style: body(),
            ),
            const SizedBox(height: 20),
            Text('8. Changes', style: heading()),
            const SizedBox(height: 8),
            Text(
              'We may update these terms. Material changes may be communicated in-app or on our website. Continued use after changes constitutes acceptance.',
              style: body(),
            ),
            const SizedBox(height: 20),
            Text('9. Contact', style: heading()),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                style: body(),
                children: [
                  const TextSpan(
                    text:
                        'For account deletion, terms-related questions, or complaints, contact us at ',
                  ),
                  TextSpan(
                    text: 'support@aslidesikisan.com',
                    style: body().copyWith(
                      color: AppColors.mlmGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(
                    text:
                        ' or adk99904@gmail.com from your registered email where possible.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
