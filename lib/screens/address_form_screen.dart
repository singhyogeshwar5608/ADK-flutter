import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/stored_address.dart';
import '../services/address_storage_service.dart';
import '../services/api_client.dart';
import '../services/pin_code_service.dart';
import '../services/pincode_api_service.dart';
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
    final bg = isDark ? const Color(0xFF070F1B) : Colors.white;

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

    final isEdit = args.existing != null;

    final inputFontSize = (theme.textTheme.bodyLarge?.fontSize ?? 15) - 3;

    OutlineInputBorder outline(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    InputDecoration decoration(String placeholder, {int? maxLines}) {
      final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
      final idleColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
      return InputDecoration(
        isDense: true,
        hintText: placeholder,
        hintStyle: TextStyle(
          fontSize: inputFontSize,
          fontWeight: FontWeight.w400,
          color: muted.withValues(alpha: 0.88),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        border: outline(idleColor),
        enabledBorder: outline(idleColor),
        focusedBorder: outline(theme.colorScheme.primary, 1.35),
        errorBorder: outline(Colors.red.shade400),
        focusedErrorBorder: outline(Colors.red.shade300, 1.15),
        errorStyle: TextStyle(
          fontSize: (inputFontSize - 1).clamp(10.0, 14.0),
          height: 1.2,
          color: Colors.red.shade700,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: (maxLines != null && maxLines > 1) ? 12 : 10,
        ),
      );
    }

    Widget fieldShell({required Widget child}) {
      if (isDark) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1724),
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        );
      }
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: child,
        ),
      );
    }

    Widget labeledField({
      required TextEditingController controller,
      required String placeholder,
      String? Function(String?)? validator,
      TextInputType? keyboardType,
      List<TextInputFormatter>? inputFormatters,
      TextCapitalization textCapitalization = TextCapitalization.none,
      int? maxLines,
      bool required = true,
      void Function(String)? onChanged,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: RichText(
              text: TextSpan(
                text: placeholder,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                ),
                children: [
                  if (required)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                ],
              ),
            ),
          ),
          fieldShell(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              textCapitalization: textCapitalization,
              maxLines: maxLines ?? 1,
              onChanged: onChanged,
              style: TextStyle(
                fontSize: inputFontSize,
                fontWeight: FontWeight.w500,
                height: 1.25,
                color: theme.colorScheme.onSurface,
              ),
              cursorColor: theme.colorScheme.primary,
              decoration: decoration(placeholder, maxLines: maxLines),
              validator: validator,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit address' : 'New address'),
        centerTitle: true,
        backgroundColor: bg,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                labeledField(
                  controller: _name,
                  placeholder: 'Full name',
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                labeledField(
                  controller: _phone,
                  placeholder: 'Phone',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v.trim())) return 'Enter valid 10-digit mobile number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                labeledField(
                  controller: _email,
                  placeholder: 'Email (order updates)',
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(v.trim())) return 'Enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                labeledField(
                  controller: _line,
                  placeholder: 'Address line',
                  maxLines: 2,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                labeledField(
                  controller: _pin,
                  placeholder: 'Pin Code',
                  keyboardType: TextInputType.text,
                  onChanged: _onPinCodeChanged,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                labeledField(
                  controller: _city,
                  placeholder: 'City',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                labeledField(
                  controller: _state,
                  placeholder: 'State',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2B9DEE),
                    minimumSize: const Size(double.infinity, 52),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    shadowColor: const Color(0xFF2B9DEE).withValues(alpha: 0.3),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Save address',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
