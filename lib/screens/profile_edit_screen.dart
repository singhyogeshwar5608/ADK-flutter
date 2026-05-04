import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../state/profile_state.dart';
import '../services/api_client.dart';
import '../services/cloudinary_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  static const routeName = '/profile-edit';

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final ProfileState _profileState;
  late String _photoUrl;
  String? _photoPublicId;
  File? _localPhoto;
  Uint8List? _localPhotoBytes;
  String? _localPhotoName;
  bool _isSaving = false;
  String? _error;
  static const double _fieldTextReduction = 3;

  @override
  void initState() {
    super.initState();
    _profileState = ProfileProvider.of(context, listen: false);
    final profile = _profileState.data;
    _nameController = TextEditingController(text: profile.name);
    _emailController = TextEditingController(text: profile.email);
    _phoneController = TextEditingController(text: profile.phone);
    _addressController = TextEditingController(text: profile.address);
    _photoUrl = profile.photoUrl;
    _photoPublicId = profile.photoPublicId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Edit profile'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: _handleSave,
            icon: const Icon(Icons.check_circle_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.06)),
                ),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.shield_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Update your details to keep account info accurate.',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.72),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _PhotoPickerSection(
                        photoProvider: _currentPhotoProvider(),
                        onPick: _pickPhoto,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildSectionHeader('Basic info'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        label: 'Full name',
                        controller: _nameController,
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Email address',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Phone number',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                      ),
                      const SizedBox(height: 28),
                      _buildSectionHeader('Address'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        label: 'Address',
                        controller: _addressController,
                        prefixIcon: Icons.home_outlined,
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _handleSave,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(_isSaving ? 'Saving...' : 'Save changes'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: theme.textTheme.labelLarge?.copyWith(
                            fontSize:
                                (theme.textTheme.labelLarge?.fontSize ?? 14) - 1,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
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

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) - 2,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? prefixIcon,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    final labelSize =
        (theme.textTheme.labelLarge?.fontSize ?? 14) - _fieldTextReduction;
    final inputSize =
        (theme.textTheme.bodyLarge?.fontSize ?? 16) - _fieldTextReduction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: labelSize.clamp(9.0, 18.0),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: inputSize.clamp(10.0, 20.0),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: prefixIcon == null
                ? null
                : Icon(
                    prefixIcon,
                    color: theme.colorScheme.primary,
                    size: 17,
                  ),
            hintText: 'Enter $label'.toLowerCase(),
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              fontSize: inputSize.clamp(10.0, 20.0),
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            prefixIconConstraints:
                const BoxConstraints(minHeight: 34, minWidth: 34),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      String photoUrl = _photoUrl;
      String? publicId = _photoPublicId;

      if (_localPhoto != null) {
        final result = await CloudinaryService.instance.uploadImage(
          file: _localPhoto!,
          filename: _localPhotoName,
        );
        photoUrl = result.url;
        publicId = result.publicId;
      } else if (_localPhotoBytes != null) {
        final result = await CloudinaryService.instance.uploadImage(
          bytes: _localPhotoBytes!,
          filename: _localPhotoName,
        );
        photoUrl = result.url;
        publicId = result.publicId;
      }
      String? _nonEmpty(String value) =>
          value.trim().isEmpty ? null : value.trim();

      final updatedMember = await ApiClient.instance.updateProfile(
        fullName: _nonEmpty(_nameController.text),
        email: _nonEmpty(_emailController.text),
        phone: _nonEmpty(_phoneController.text),
        address: _nonEmpty(_addressController.text),
        profileImage: _nonEmpty(photoUrl),
      );

      _profileState.updateFromMemberPayload(updatedMember);
      _photoUrl = updatedMember['profileImage'] as String? ?? photoUrl;
      photoUrl = _photoUrl;

      _profileState.updateFields(photoPublicId: publicId);

      if (!mounted) return;
      setState(() {
        _photoUrl = photoUrl;
        _photoPublicId = publicId;
        _localPhoto = null;
        _localPhotoBytes = null;
        _localPhotoName = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      String errorMessage = e.toString();

      // Check for specific Cloudinary errors
      if (errorMessage.contains('Missing Cloudinary configuration')) {
        errorMessage =
            'Cloudinary configuration missing. Please contact admin.';
      } else if (errorMessage.contains('Upload failed')) {
        errorMessage = 'Image upload failed. Please try again.';
      } else if (errorMessage.contains('No image provided')) {
        errorMessage = 'Please select an image first.';
      }

      setState(() {
        _error = errorMessage;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
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
        _error = null;
      });
    } else {
      setState(() {
        _localPhoto = File(picked.path);
        _localPhotoBytes = null;
        _localPhotoName = picked.name;
        _error = null;
      });
    }
  }

  ImageProvider _currentPhotoProvider() {
    if (_localPhotoBytes != null) {
      return MemoryImage(_localPhotoBytes!);
    }
    if (_localPhoto != null) {
      return FileImage(_localPhoto!);
    }
    if (_photoUrl.isEmpty) {
      return const NetworkImage(
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBkGg5hb6MSFFq_WMlPLhfreQ0dvqR4miXizxkvnruDwFGXSIBoGhVn93JSL55IqweqUeTowePDogpC9WRqPEfYRx4LmwcjWFD7BFb2tHkmwO0RwEtpqFJbDWKSnIVDYEO--avoyYYwgNNVZVL8hobUs6W21fNMGjWrW3ePK1ESmmyAq42-8EL09SeI_3A1fP8SXWhYKnzV1NkWWOiSnrsOGTnqs8QH656E585bK-NbnseGjKWC16jRzU-F0TERUnfbG59gTF4FlwA',
      );
    }
    if (_photoUrl.startsWith('http')) {
      return NetworkImage(_photoUrl);
    }
    return FileImage(File(_photoUrl));
  }
}

class _PhotoPickerSection extends StatelessWidget {
  const _PhotoPickerSection(
      {required this.photoProvider, required this.onPick});

  final ImageProvider photoProvider;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleSize = (theme.textTheme.titleMedium?.fontSize ?? 16) - 2;
    final captionSize = (theme.textTheme.bodySmall?.fontSize ?? 12) - 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Profile photo',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700, fontSize: titleSize)),
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: CircleAvatar(radius: 40, backgroundImage: photoProvider),
            ),
            Material(
              color: theme.colorScheme.primary,
              shape: const CircleBorder(),
              child: IconButton(
                icon:
                    const Icon(Icons.camera_alt, color: Colors.white, size: 17),
                onPressed: onPick,
                constraints: const BoxConstraints(minHeight: 34, minWidth: 34),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Upload a clear profile picture',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: captionSize.clamp(9.0, 16.0),
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: onPick,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Change photo',
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: ((theme.textTheme.labelMedium?.fontSize ?? 12) - 2)
                  .clamp(9.0, 16.0),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
