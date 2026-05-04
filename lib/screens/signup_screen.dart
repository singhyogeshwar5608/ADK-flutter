import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../routes/app_routes.dart';
import '../services/api_client.dart';
import '../services/cloudinary_service.dart';
import '../state/profile_state.dart';
import '../theme/app_theme.dart';
import '../utils/referral_signup_params.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';

/// Optional deep-link / push args (mobile). Web uses `?ref=` from [parseReferralSignupFromUrl].
class SignupRouteArgs {
  const SignupRouteArgs({this.referralCode, this.leg});

  final String? referralCode;
  final String? leg;
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  static const routeName = AppRoutes.signup;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

/// Light signup palette (aligned with [AppTheme.lightTheme]).
abstract final class _SignupLight {
  static const Color fill = Color(0xFFE2E8F0);
  static const Color iconBg = Color(0xFFD0DAE8);
  static const Color border = Color(0xFFCBD5E1);
  static const Color subtitle = Color(0xFF64748B);
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _agreedToTerms = false;
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;
  bool _isSubmitting = false;
  bool _referralResolved = false;
  String? _referralCode;
  String _selectedLeg = 'LEFT';
  String? _submitError;
  File? _localPhoto;
  Uint8List? _localPhotoBytes;
  String? _localPhotoName;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_referralResolved) return;
    _referralResolved = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is SignupRouteArgs) {
      final c = args.referralCode?.trim();
      if (c != null && c.isNotEmpty) _referralCode = c;
      final l = args.leg?.trim().toUpperCase();
      if (l == 'LEFT' || l == 'RIGHT') _selectedLeg = l!;
    }

    if (kIsWeb) {
      final q = parseReferralSignupFromUrl();
      _referralCode ??= q.referralCode?.trim().isNotEmpty == true
          ? q.referralCode!.trim()
          : _referralCode;
      final l = q.leg?.trim().toUpperCase();
      if (l == 'LEFT' || l == 'RIGHT') _selectedLeg = l!;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  static const String _referralRequiredMsg =
      'Sign up is only allowed through your sponsor invite link (it includes ?ref=). Open that link and try again.';

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (!(form?.validate() ?? false)) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms first.')),
      );
      return;
    }

    final code = _referralCode?.trim();
    if (code == null || code.isEmpty) {
      if (!mounted) return;
      setState(() => _submitError = _referralRequiredMsg);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(_referralRequiredMsg),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      String? profileImageUrl;
      if (_localPhoto != null || _localPhotoBytes != null) {
        final uploadResult = await CloudinaryService.instance
            .uploadImage(
              file: kIsWeb ? null : _localPhoto,
              bytes: _localPhotoBytes,
              filename: _localPhotoName,
            )
            .timeout(
              const Duration(seconds: 90),
              onTimeout: () => throw TimeoutException(
                'Photo upload timed out. Try again without a photo or check your connection.',
              ),
            );
        profileImageUrl = uploadResult.url;
      }

      final apiClient = ApiClient.instance;
      await apiClient
          .registerMember(
            fullName: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            referralCode: code,
            phone: _phoneController.text,
            address: _addressController.text,
            leg: _selectedLeg,
            profileImage: profileImageUrl,
          )
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () => throw TimeoutException(
              'Registration timed out. Check your connection and try again.',
            ),
          );

      await apiClient
          .loginWithCredentials(
            _emailController.text,
            _passwordController.text,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException(
              'Sign-in after registration timed out. Try signing in manually.',
            ),
          );
      final member = await apiClient
          .fetchCurrentMember(autoAuthenticate: false)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException(
              'Could not load your profile. Try signing in again.',
            ),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully.')),
      );
      ProfileProvider.of(context, listen: false)
          .updateFromMemberPayload(member);
      setState(() {
        _localPhoto = null;
        _localPhotoBytes = null;
        _localPhotoName = null;
      });
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (error, stack) {
      debugPrint('Signup failed: $error');
      debugPrintStack(stackTrace: stack);
      if (!mounted) return;
      final String friendly;
      if (error is TimeoutException) {
        friendly = error.message ??
            'Request timed out. Check your connection and try again.';
      } else {
        final msg = error.toString();
        friendly = msg.contains('referral') || msg.contains('Referral')
            ? 'Invalid or expired sponsor / referral ID. Confirm the code from your sponsor.'
            : 'Unable to create account. Check your details and try again.';
      }
      setState(() => _submitError = friendly);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendly)));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _pickPhoto() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _localPhotoBytes = bytes;
        _localPhoto = null;
        _localPhotoName = picked.name;
      });
    } else {
      setState(() {
        _localPhoto = File(picked.path);
        _localPhotoBytes = null;
        _localPhotoName = picked.name;
      });
    }
  }

  ImageProvider? _photoProvider() {
    if (_localPhotoBytes != null) return MemoryImage(_localPhotoBytes!);
    if (_localPhoto != null) return FileImage(_localPhoto!);
    return null;
  }

  /// Read-only sponsor/referral ID from invite link only; shown above placement leg.
  Widget _referralBanner(ColorScheme cs) {
    final code = _referralCode?.trim();
    if (code != null && code.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _SignupLight.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.link_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sponsor ID',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _SignupLight.subtitle,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    code,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pulled from your invite link.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _SignupLight.subtitle,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _referralRequiredMsg,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = AppTheme.lightTheme.colorScheme;

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Create account'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Create Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _SignupLight.subtitle,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join the network',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Create an account to track commissions, orders, and your team performance.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: _SignupLight.subtitle,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _AvatarBlock(
                        image: _photoProvider(),
                        onAddPhoto: _pickPhoto,
                      ),
                      const SizedBox(height: 28),
                      _SignupTextField(
                        controller: _nameController,
                        label: 'Full name',
                        icon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _SignupTextField(
                        controller: _emailController,
                        label: 'Email address',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          final emailPattern = RegExp(
                            r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
                          );
                          if (email.isEmpty) return 'Email is required';
                          if (!emailPattern.hasMatch(email)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _SignupTextField(
                        controller: _phoneController,
                        label: 'Phone number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (value) {
                          final phone = value?.trim() ?? '';
                          if (phone.isEmpty) {
                            return 'Phone number is required';
                          }
                          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
                            return 'Enter a valid 10-digit mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _SignupTextField(
                        controller: _addressController,
                        label: 'Address',
                        icon: Icons.location_on_outlined,
                        keyboardType: TextInputType.streetAddress,
                        maxLines: 2,
                        validator: (value) => value == null ||
                                value.trim().isEmpty
                            ? 'Address is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _SignupTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: !_isPasswordVisible,
                        suffix: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: _SignupLight.subtitle,
                            size: 19,
                          ),
                          onPressed: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        validator: (value) {
                          final password = value?.trim() ?? '';
                          if (password.isEmpty) {
                            return 'Password is required';
                          }
                          if (password.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _SignupTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm password',
                        icon: Icons.lock_clock_outlined,
                        obscureText: !_isConfirmVisible,
                        suffix: IconButton(
                          icon: Icon(
                            _isConfirmVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: _SignupLight.subtitle,
                            size: 19,
                          ),
                          onPressed: () => setState(
                              () => _isConfirmVisible = !_isConfirmVisible),
                        ),
                        validator: (value) {
                          final c = value?.trim() ?? '';
                          if (c.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (c != _passwordController.text.trim()) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 26),
                      _referralBanner(cs),
                      const SizedBox(height: 16),
                      Text(
                        'Select placement leg',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose left or right binary leg. Defaults to LEFT.',
                        style: TextStyle(
                          fontSize: 13,
                          color: _SignupLight.subtitle,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _LegChoiceCard(
                              label: 'LEFT',
                              sub: _selectedLeg == 'LEFT'
                                  ? 'Selected'
                                  : 'Tap to select',
                              icon: Icons
                                  .keyboard_double_arrow_left_rounded,
                              selected: _selectedLeg == 'LEFT',
                              glow: _selectedLeg == 'LEFT',
                              onTap: () =>
                                  setState(() => _selectedLeg = 'LEFT'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _LegChoiceCard(
                              label: 'RIGHT',
                              sub: _selectedLeg == 'RIGHT'
                                  ? 'Selected'
                                  : 'Tap to select',
                              icon:
                                  Icons.keyboard_double_arrow_right_rounded,
                              selected: _selectedLeg == 'RIGHT',
                              glow: _selectedLeg == 'RIGHT',
                              onTap: () =>
                                  setState(() => _selectedLeg = 'RIGHT'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            onChanged: (v) => setState(
                                () => _agreedToTerms = v ?? false),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 0,
                                runSpacing: 0,
                                children: [
                                  Text(
                                    'I agree to the ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: cs.onSurface,
                                      height: 1.35,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.of(context)
                                        .pushNamed(
                                      TermsConditionsScreen.routeName,
                                    ),
                                    child: Text(
                                      'Terms of Service',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    ' and ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.of(context)
                                        .pushNamed(
                                      PrivacyPolicyScreen.routeName,
                                    ),
                                    child: Text(
                                      'Privacy Policy',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_submitError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _submitError!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade700,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            disabledBackgroundColor:
                                AppColors.primary.withValues(alpha: 0.45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Create account',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already registered?',
                            style: TextStyle(
                              fontSize: 14,
                              color: _SignupLight.subtitle,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context)
                                .pushReplacementNamed(
                                    LoginScreen.routeName),
                            child: const Text(
                              'Sign in',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
    );
  }
}

class _AvatarBlock extends StatelessWidget {
  const _AvatarBlock({required this.image, required this.onAddPhoto});

  final ImageProvider? image;
  final VoidCallback onAddPhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 54,
            backgroundColor: AppColors.primary,
            backgroundImage: image,
            child: image == null
                ? const Icon(Icons.person_rounded,
                    size: 56, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: onAddPhoto,
          icon: Icon(Icons.photo_camera_rounded,
              size: 20, color: AppColors.primary),
          label: Text(
            'Add profile photo',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SignupTextField extends StatelessWidget {
  const _SignupTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(
        color: cs.onSurface,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: _SignupLight.fill,
        hintText: label,
        hintStyle: TextStyle(
          color: _SignupLight.subtitle.withValues(alpha: 0.75),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 5, top: 1, bottom: 1, right: 3),
          child: Container(
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _SignupLight.iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                color: const Color(0xFF475569), size: 20),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 52, maxHeight: 40),
        suffixIcon: suffix,
        suffixIconConstraints: suffix != null
            ? const BoxConstraints(minWidth: 48, maxHeight: 48)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: _SignupLight.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: _SignupLight.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.2),
        ),
        errorStyle: TextStyle(fontSize: 11, color: Colors.red.shade700),
      ),
      validator: validator,
    );
  }
}

class _LegChoiceCard extends StatelessWidget {
  const _LegChoiceCard({
    required this.label,
    required this.sub,
    required this.icon,
    required this.selected,
    required this.glow,
    required this.onTap,
  });

  final String label;
  final String sub;
  final IconData icon;
  final bool selected;
  final bool glow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color:
                selected ? AppColors.primary : Colors.white,
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : _SignupLight.border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: glow
                ? [
                    BoxShadow(
                      color:
                          AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sub,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white.withValues(alpha: 0.92)
                            : _SignupLight.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                icon,
                color: selected
                    ? Colors.white
                    : _SignupLight.subtitle,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
