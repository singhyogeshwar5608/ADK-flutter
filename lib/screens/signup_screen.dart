import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/member_summary.dart';
import '../routes/app_routes.dart';
import '../services/api_client.dart';
import '../services/cloudinary_service.dart';
import '../state/profile_state.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  static const routeName = AppRoutes.signup;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
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
  bool _showSponsorSelector = false;
  bool _isLoadingSponsors = false;
  bool _isSubmitting = false;
  String? _sponsorError;
  String? _selectedSponsorId;
  String _selectedLeg = 'LEFT';
  String? _submitError;
  List<MemberSummary> _sponsorOptions = const [];
  File? _localPhoto;
  Uint8List? _localPhotoBytes;
  String? _localPhotoName;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (!(form?.validate() ?? false) || !_agreedToTerms) {
      if (!_agreedToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please accept the terms first.')));
      }
      return;
    }

    if (_selectedSponsorId == null) {
      setState(() {
        _showSponsorSelector = true;
        _sponsorError = 'Sponsor ID is required';
      });
      _loadSponsors();
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      String? profileImageUrl;
      if (_localPhoto != null || _localPhotoBytes != null) {
        final uploadResult = await CloudinaryService.instance.uploadImage(
          file: kIsWeb ? null : _localPhoto,
          bytes: _localPhotoBytes,
          filename: _localPhotoName,
        );
        profileImageUrl = uploadResult.url;
      }

      final apiClient = ApiClient.instance;
      await apiClient.registerMember(
        fullName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        sponsorId: _selectedSponsorId,
        leg: _selectedSponsorId != null ? _selectedLeg : null,
        profileImage: profileImageUrl,
      );

      await apiClient.loginWithCredentials(
        _emailController.text,
        _passwordController.text,
      );
      final member =
          await apiClient.fetchCurrentMember(autoAuthenticate: false);

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
      setState(() {
        _submitError = 'Unable to create account. Please try again.';
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

  Future<void> _loadSponsors() async {
    setState(() {
      _showSponsorSelector = true;
      _sponsorError = null;
    });

    if (_sponsorOptions.isNotEmpty || _isLoadingSponsors) {
      return;
    }

    setState(() {
      _isLoadingSponsors = true;
    });

    try {
      final members = await ApiClient.instance.fetchPublicMembers();
      if (!mounted) return;
      setState(() {
        _sponsorOptions = members;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sponsorError = 'Unable to load sponsors. Please try again.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingSponsors = false;
      });
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
    if (_localPhotoBytes != null) {
      return MemoryImage(_localPhotoBytes!);
    }
    if (_localPhoto != null) {
      return FileImage(_localPhoto!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create your Asli desi Kisan account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: FractionallySizedBox(
              widthFactor: 0.98,
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
                          'Join the network',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Create an account to track commissions, orders, and your team performance.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: _photoProvider(),
                                child: _photoProvider() == null
                                    ? const Icon(Icons.person_outline, size: 48)
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _pickPhoto,
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: const Text('Add profile photo'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Name is required'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            final emailPattern = RegExp(
                                r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
                            if (email.isEmpty) {
                              return 'Email is required';
                            }
                            if (!emailPattern.hasMatch(email)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          keyboardType: TextInputType.streetAddress,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            prefixIcon: Icon(Icons.location_on_outlined),
                            hintText: 'Enter your full address',
                          ),
                          validator: (value) {
                            final address = value?.trim() ?? '';
                            if (address.isEmpty) {
                              return 'Address is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(() =>
                                  _isPasswordVisible = !_isPasswordVisible),
                            ),
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm password',
                            prefixIcon: Icon(Icons.lock_reset_outlined),
                          ),
                          validator: (value) {
                            final confirmation = value?.trim() ?? '';
                            if (confirmation.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (confirmation !=
                                _passwordController.text.trim()) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _loadSponsors,
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Select sponsor (required)'),
                        ),
                        if (_showSponsorSelector) ...[
                          const SizedBox(height: 12),
                          if (_isLoadingSponsors)
                            const Center(child: CircularProgressIndicator())
                          else if (_sponsorError != null)
                            Text(
                              _sponsorError!,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: colorScheme.error),
                            )
                          else ...[
                            DropdownButtonFormField<String>(
                              value: _selectedSponsorId,
                              decoration: const InputDecoration(
                                labelText: 'Select sponsor',
                                prefixIcon: Icon(Icons.group_add_outlined),
                              ),
                              isExpanded: true,
                              items: _sponsorOptions
                                  .map((member) => DropdownMenuItem(
                                        value: member.memberId,
                                        child: Text(
                                            '${member.fullName} (${member.memberId})'),
                                      ))
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedSponsorId = value),
                            ),
                            const SizedBox(height: 12),
                            if (_selectedSponsorId != null)
                              Wrap(
                                spacing: 12,
                                children: [
                                  ChoiceChip(
                                    label: const Text('Left leg'),
                                    selected: _selectedLeg == 'LEFT',
                                    onSelected: (_) =>
                                        setState(() => _selectedLeg = 'LEFT'),
                                  ),
                                  ChoiceChip(
                                    label: const Text('Right leg'),
                                    selected: _selectedLeg == 'RIGHT',
                                    onSelected: (_) =>
                                        setState(() => _selectedLeg = 'RIGHT'),
                                  ),
                                ],
                              ),
                          ],
                        ],
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          value: _agreedToTerms,
                          onChanged: (value) =>
                              setState(() => _agreedToTerms = value ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                              'I agree to the Terms of Service and Privacy Policy'),
                        ),
                        const SizedBox(height: 8),
                        if (_submitError != null) ...[
                          Text(
                            _submitError!,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.error),
                          ),
                          const SizedBox(height: 8),
                        ],
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
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Create account'),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            Text(
                              'Already registered?',
                              style: theme.textTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context)
                                  .pushReplacementNamed(LoginScreen.routeName),
                              child: const Text('Sign in'),
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
