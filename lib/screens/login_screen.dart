import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../services/address_storage_service.dart';
import '../services/api_client.dart';
import '../state/profile_state.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = AppRoutes.login;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Tighter fields + label text 4px smaller than theme defaults.
  InputDecoration _loginFieldDecoration(
    ThemeData theme, {
    required String label,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final bodyLarge = theme.textTheme.bodyLarge;
    final labelLarge = theme.textTheme.labelLarge;
    final labelFont = (bodyLarge?.fontSize ?? 16) - 4;
    final floatingFont = (labelLarge?.fontSize ?? 14) - 4;
    return InputDecoration(
      labelText: label,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 40,
        minHeight: 36,
      ),
      suffixIconConstraints: const BoxConstraints(
        minWidth: 40,
        minHeight: 36,
      ),
      labelStyle: bodyLarge?.copyWith(fontSize: labelFont),
      floatingLabelStyle: labelLarge?.copyWith(fontSize: floatingFont),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final apiClient = ApiClient.instance;
      await apiClient.loginWithCredentials(
          _emailController.text, _passwordController.text);
      final member =
          await apiClient.fetchCurrentMember(autoAuthenticate: false);

      if (!mounted) return;
      ProfileProvider.of(context, listen: false)
          .updateFromMemberPayload(member);

      final pid =
          ProfileProvider.of(context, listen: false).data.partnerId.trim();
      if (pid.isNotEmpty) {
        await AddressStorageService.instance.migrateGuestToUser(pid);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in successfully')),
      );

      Navigator.of(context).pushReplacementNamed(ProfileScreen.routeName);
    } catch (error, stackTrace) {
      debugPrint('Login failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _submitError =
            'Unable to sign in. Please check your credentials and try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_submitError!)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in to Asli desi Kisan'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: theme.brightness == Brightness.dark ? 0 : 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Welcome back',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Access your dashboard, manage members, and track orders.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: theme.textTheme.bodyLarge,
                          decoration: _loginFieldDecoration(
                            theme,
                            label: 'Email address',
                            prefixIcon: const Icon(Icons.mail_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!value.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: theme.textTheme.bodyLarge,
                          decoration: _loginFieldDecoration(
                            theme,
                            label: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 36,
                              ),
                              icon: Icon(_isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(() =>
                                  _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.length < 6
                                  ? 'Password must be at least 6 characters'
                                  : null,
                        ),
                        const SizedBox(height: 32),
                        FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white)),
                                )
                              : const Text('Sign in'),
                        ),
                        if (_submitError != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _submitError!,
                            style: TextStyle(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const HomeScreen()),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.home_outlined),
                          label: const Text('Continue to Home'),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: theme.textTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context)
                                  .pushReplacementNamed(SignupScreen.routeName),
                              child: const Text('Create one'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
