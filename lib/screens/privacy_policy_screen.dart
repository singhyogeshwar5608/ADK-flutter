import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const routeName = '/privacy-policy';

  static const Color _headingBlue = Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bodyColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    TextStyle heading() => TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: isDark ? _headingBlue : const Color(0xFF0284C7),
          height: 1.35,
        );

    TextStyle body() => TextStyle(
          fontSize: 13,
          height: 1.55,
          color: bodyColor,
        );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
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
              'Last updated: April 2026',
              style: TextStyle(fontSize: 13, color: mutedColor),
            ),
            const SizedBox(height: 20),
            Text('1. Introduction', style: heading()),
            const SizedBox(height: 8),
            Text(
              'ADK Partner ("we", "us") respects your privacy. This policy explains how we handle information when you use our mobile application and related services.',
              style: body(),
            ),
            const SizedBox(height: 20),
            Text('2. Information we collect', style: heading()),
            const SizedBox(height: 8),
            Text(
              '• Account details you provide (such as name, email, phone) when you register or update your profile.\n'
              '• Order, wallet, and transaction data necessary to operate the partner and e-commerce features.\n'
              '• Device and technical data (such as app version, diagnostics) to improve stability and security.\n'
              '• Content you upload where the app allows (for example images for KYC or media), as described in-app.',
              style: body(),
            ),
            const SizedBox(height: 20),
            Text('3. How we use information', style: heading()),
            const SizedBox(height: 8),
            Text(
              'We use your information to provide and improve the service, process orders and payments, communicate with you about your account, comply with law, and prevent fraud or abuse.',
              style: body(),
            ),
            const SizedBox(height: 20),
            Text('4. Payments', style: heading()),
            const SizedBox(height: 8),
            Text(
              'Payments may be processed by third-party providers (for example Razorpay). Their privacy practices apply to payment data they process on our behalf. We do not store full card details on our servers when the payment partner handles them.',
              style: body(),
            ),
            const SizedBox(height: 20),
            Text('5. Data retention & security', style: heading()),
            const SizedBox(height: 8),
            Text(
              'We retain data only as long as needed for the purposes above or as required by law. We use reasonable technical and organisational measures to protect your information.',
              style: body(),
            ),
            const SizedBox(height: 20),
            Text('6. Your choices', style: heading()),
            const SizedBox(height: 8),
            Text(
              'Where applicable, you may access or update certain profile information in the app. You may contact us to ask questions about this policy or to exercise rights available under applicable law.',
              style: body(),
            ),
            const SizedBox(height: 20),
            Text('7. Account deletion & other information', style: heading()),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                style: body(),
                children: [
                  const TextSpan(
                    text:
                        'For account deletion requests, questions about your data, or other privacy-related information, please contact us at ',
                  ),
                  TextSpan(
                    text: 'adk99904@gmail.com',
                    style: body().copyWith(
                      color: AppColors.mlmGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(
                    text:
                        '. Include your registered email or phone so we can verify your identity. We will process requests in line with applicable law and our internal procedures.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('8. Changes', style: heading()),
            const SizedBox(height: 8),
            Text(
              'We may update this policy from time to time. Continued use of the app after changes constitutes acceptance of the updated policy where permitted by law. Material updates may be highlighted in-app or on our website.',
              style: body(),
            ),
          ],
        ),
      ),
    );
  }
}
