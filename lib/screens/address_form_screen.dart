import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/stored_address.dart';
import '../services/address_storage_service.dart';
import '../services/api_client.dart';
import '../services/pin_code_service.dart';
import '../services/pincode_api_service.dart';
import '../theme/app_theme.dart';
import '../state/profile_state.dart';

class AddressFormRouteArgs {
  const AddressFormRouteArgs({
    this.existing,
    required this.userId,
    this.showSaveCheckbox = false,
  });

  final StoredAddress? existing;
  /// `null` = guest bucket.
  final String? userId;

  /// When true (e.g. opened from customer flow), user can submit without persisting.
  final bool showSaveCheckbox;
}

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key});

  static const routeName = '/address-form';

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _phone;
  late TextEditingController _line;
  late TextEditingController _city;
  late TextEditingController _state;
  late TextEditingController _pin;
  late TextEditingController _email;
  /// Controllers allocated after [didChangeDependencies] reads route args.
  bool _controllersCreated = false;
  
  /// PIN code change handler
  void _onPinCodeChanged(String value) {
    print('=== PIN CODE DEBUG ===');
    print('PIN Code entered: $value');
    print('PIN Code length: ${value.length}');
    
    if (value.length == 6) {
      print('Looking up PIN code: $value');
      
      // Try API first, fallback to local service
      _fetchPincodeDataFromApi(value);
    } else {
      print('PIN code not 6 digits yet, waiting...');
    }
    print('====================');
  }
  
  /// Fetch PIN code data from API
  Future<void> _fetchPincodeDataFromApi(String pincode) async {
    print('=== PINCODE FETCH START ===');
    print('Fetching data for PIN code: $pincode');
    
    try {
      // 1. Try public Pincode API first (Zippopotam is CORS friendly)
      print('Trying PincodeApiService...');
      final publicData = await PincodeApiService.getPincodeData(pincode);
      
      if (publicData != null && publicData['city'] != null && publicData['state'] != null) {
        print('SUCCESS: Public API found data: ${publicData['city']}, ${publicData['state']}');
        if (mounted) {
          setState(() {
            _city.text = publicData['city']!;
            _state.text = publicData['state']!;
          });
        }
        return;
      }
      
      // 2. Fallback to internal API (if public failed)
      print('Public API failed, trying internal API...');
      try {
        final pincodeData = await ApiClient.instance.fetchPincode(pincode);
        if (pincodeData != null) {
          print('SUCCESS: Internal API found data');
          if (mounted) {
            setState(() {
              _city.text = (pincodeData['city'] ?? '').toString();
              _state.text = (pincodeData['state'] ?? '').toString();
            });
          }
          return;
        }
      } catch (apiError) {
        print('Internal API call failed: $apiError');
      }
      
      // 3. Last fallback to local hardcoded service
      print('Both APIs failed, trying local fallback service...');
      final fallbackData = PinCodeService.getPinCodeData(pincode);
      if (fallbackData != null) {
        if (mounted) {
          setState(() {
            _city.text = fallbackData['city'] ?? '';
            _state.text = fallbackData['state'] ?? '';
          });
        }
        print('SUCCESS: Local fallback found data');
      } else {
        print('ERROR: No data found in any service for $pincode');
      }
      
    } catch (e) {
      print('ERROR: Exception in pincode fetch flow: $e');
    } finally {
      print('=== PINCODE FETCH END ===');
    }
  }
  bool _saveToPrefs = true;
  bool _isDefault = false;
  bool _submitting = false;

  AddressFormRouteArgs? get _args {
    final a = ModalRoute.of(context)?.settings.arguments;
    return a is AddressFormRouteArgs ? a : null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllersCreated) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! AddressFormRouteArgs) return;
    final e = args.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _line = TextEditingController(text: e?.addressLine ?? '');
    _city = TextEditingController(text: e?.city ?? '');
    _state = TextEditingController(text: e?.state ?? '');
    _pin = TextEditingController(text: e?.pincode ?? '');
    _email = TextEditingController(text: e?.email ?? ProfileProvider.of(context).data.email ?? '');
    _isDefault = e?.isDefault ?? false;
    _controllersCreated = true;
  }

  @override
  void dispose() {
    if (_controllersCreated) {
      _name.dispose();
      _phone.dispose();
      _line.dispose();
      _city.dispose();
      _state.dispose();
      _pin.dispose();
      _email.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final args = _args;
    if (args == null) return;

    if (args.showSaveCheckbox && !_saveToPrefs) {
      if (!mounted) return;
      Navigator.of(context).pop(false);
      return;
    }

    setState(() => _submitting = true);
    try {
      final id = args.existing?.id ?? AddressStorageService.newId();
      final now = DateTime.now().millisecondsSinceEpoch;
      var next = StoredAddress(
        id: id,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        addressLine: _line.text.trim(),
        city: _city.text.trim(),
        state: _state.text.trim(),
        pincode: _pin.text.trim(),
        email: _email.text.trim(),
        isDefault: args.userId != null && _isDefault,
        lastUsedAt: now,
      );

      if (args.existing == null) {
        await AddressStorageService.instance.addAddress(next, userId: args.userId);
      } else {
        await AddressStorageService.instance.updateAddress(next, userId: args.userId);
      }

      if (args.userId != null && _isDefault) {
        await AddressStorageService.instance.setDefaultAddress(id, args.userId!);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    if (rawArgs is! AddressFormRouteArgs) {
      return Scaffold(
        appBar: AppBar(title: const Text('Address')),
        body: const Center(child: Text('Missing or invalid route arguments.')),
      );
    }
    final args = rawArgs;
    if (!_controllersCreated) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(title: const Text('Address')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Debug current form values
    print('=== FORM VALUES DEBUG ===');
    print('Current City: "${_city.text}"');
    print('Current State: "${_state.text}"');
    print('Current PIN: "${_pin.text}"');
    print('Form mounted: $mounted');
    print('========================');

    final isEdit = args.existing != null;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit address' : 'New address'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              if (args.showSaveCheckbox) ...[
                CheckboxListTile(
                  value: _saveToPrefs,
                  onChanged: (v) => setState(() => _saveToPrefs = v ?? true),
                  title: const Text('Save this address'),
                  subtitle: const Text(
                    'If unchecked, this form will close without storing.',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
              ],
              if (args.userId != null) ...[
                SwitchListTile(
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                  title: const Text('Default address'),
                  subtitle: const Text('Used as the primary delivery address.'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
              ],
              _LabeledField(
                controller: _name,
                label: 'Full name',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              _LabeledField(
                controller: _phone,
                label: 'Phone',
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 10) return 'Enter a valid phone';
                  return null;
                },
              ),
              _LabeledField(
                controller: _email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!v.trim().contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              _LabeledField(
                controller: _line,
                label: 'Address line',
                maxLines: 2,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              _LabeledField(
                controller: _pin,
                label: 'PIN / Postal code',
                keyboardType: TextInputType.text,
                onChanged: _onPinCodeChanged,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: _LabeledField(
                      controller: _city,
                      label: 'City',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabeledField(
                      controller: _state,
                      label: 'State',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Save changes' : 'Save address'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: maxLines > 1,
          labelStyle: const TextStyle(fontSize: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
