import 'package:flutter/material.dart';

import 'binary_tree_screen.dart';
import '../services/api_client.dart';

class RegisterMemberScreen extends StatefulWidget {
  const RegisterMemberScreen({super.key});

  static const routeName = '/register-member';

  @override
  State<RegisterMemberScreen> createState() => _RegisterMemberScreenState();
}

class _RegisterMemberScreenState extends State<RegisterMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _partnerIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedLeg = 'Left';

  @override
  void dispose() {
    _nameController.dispose();
    _partnerIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Show loading indicator
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Creating member...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      await ApiClient.instance.createMember(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password:
            'defaultPassword123', // You might want to add a password field
        sponsorId: _partnerIdController.text.trim(),
        leg: _selectedLeg.toUpperCase(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Member created successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Clear form
      _formKey.currentState?.reset();
      _nameController.clear();
      _partnerIdController.clear();
      _emailController.clear();
      _phoneController.clear();
      _addressController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating member: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF101A22) : const Color(0xFFF6F7F8);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                _RegisterHeader(theme: theme),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    child: _RegisterForm(
                      formKey: _formKey,
                      nameController: _nameController,
                      partnerIdController: _partnerIdController,
                      emailController: _emailController,
                      phoneController: _phoneController,
                      addressController: _addressController,
                      selectedLeg: _selectedLeg,
                      onLegChanged: (value) =>
                          setState(() => _selectedLeg = value),
                      onSubmit: _submitForm,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(bottom: BorderSide(color: borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Register Member',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Add a new partner to your tree',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          _CircleIconButton(
            icon: Icons.help_outline,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    required this.formKey,
    required this.nameController,
    required this.partnerIdController,
    required this.emailController,
    required this.phoneController,
    required this.addressController,
    required this.selectedLeg,
    required this.onLegChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController partnerIdController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final String selectedLeg;
  final ValueChanged<String> onLegChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(title: 'Member Information'),
                const SizedBox(height: 14),
                _TextField(
                  controller: nameController,
                  label: 'Full Name',
                  hint: 'e.g. Aisha Mahajan',
                ),
                const SizedBox(height: 12),
                _TextField(
                  controller: partnerIdController,
                  label: 'Partner ID',
                  hint: 'e.g. NS-20345',
                ),
                const SizedBox(height: 12),
                _TextField(
                  controller: emailController,
                  label: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                  hint: 'name@email.com',
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    final emailRegex = RegExp(
                        r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Invalid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _TextField(
                  controller: phoneController,
                  label: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  hint: '+1 555 010 7890',
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    final phoneRegex = RegExp(r'^\+?[0-9\s()-]{7,}$');
                    if (!phoneRegex.hasMatch(value)) {
                      return 'Invalid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _TextField(
                  controller: addressController,
                  label: 'Address',
                  hint: 'Enter full address',
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                const _SectionTitle(title: 'Placement Details'),
                const SizedBox(height: 14),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Assign to Leg'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedLeg,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                            value: 'Left', child: Text('Left Leg')),
                        DropdownMenuItem(
                            value: 'Right', child: Text('Right Leg')),
                      ],
                      onChanged: (value) {
                        if (value != null) onLegChanged(value);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.of(context)
                      .pushReplacementNamed(BinaryTreeScreen.routeName),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: onSubmit,
                  child: const Text('Add Member'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.validator,
    this.autovalidateMode,
    this.maxLines,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String value)? validator;
  final AutovalidateMode? autovalidateMode;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      autovalidateMode: autovalidateMode,
      maxLines: maxLines ?? 1,
      decoration: InputDecoration(
        hintText: hint ?? label,
      ),
      validator: (raw) {
        final value = raw?.trim() ?? '';
        if (value.isEmpty) {
          return 'Required field';
        }
        if (validator != null) {
          return validator!(value);
        }
        return null;
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      ),
    );
  }
}
