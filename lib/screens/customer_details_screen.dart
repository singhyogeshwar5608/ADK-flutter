import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/stored_address.dart';
import '../navigation/checkout_arguments.dart';
import '../services/address_storage_service.dart';
import '../services/api_client.dart';
import '../services/pincode_api_service.dart';
import '../state/profile_state.dart';
import 'all_products_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';

class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({super.key});

  static const routeName = '/customer-details';

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF2B9DEE);
    final theme = Theme.of(context);

    final content = Column(
      children: [
        Icon(icon, color: activeColor, size: 20),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: activeColor,
          ),
        ),
      ],
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: content,
      ),
    );
  }
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  List<StoredAddress> _savedAddresses = [];

  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'India');
  final _stateCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _address1Ctrl = TextEditingController();
  final _address2Ctrl = TextEditingController();

  bool _isFormComplete = false;
  dynamic _originalArguments;

  /// Visitors (no member id) must provide email for guest order APIs.
  bool _guestBuyer = true;

  List<TextEditingController> get _allFields => [
        _fullNameCtrl,
        _phoneCtrl,
        _emailCtrl,
        _countryCtrl,
        _stateCtrl,
        _cityCtrl,
        _zipCtrl,
        _address1Ctrl,
        _address2Ctrl,
      ];

  @override
  void initState() {
    super.initState();

    for (final controller in _allFields) {
      controller.addListener(_updateFormCompletionState);
    }
    _zipCtrl.addListener(_onZipChanged);
    _updateFormCompletionState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _maybePrefillFromStorage());
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadSavedAddresses());
  }

  void _onZipChanged() {
    final zip = _zipCtrl.text.trim();
    if (zip.length == 6) {
      _fetchPincodeData(zip);
    }
  }

  Future<void> _fetchPincodeData(String pincode) async {
    try {
      // Try public API first
      final data = await PincodeApiService.getPincodeData(pincode);
      if (data != null && data['city'] != null && data['state'] != null) {
        if (mounted) {
          setState(() {
            _cityCtrl.text = data['city']!;
            _stateCtrl.text = data['state']!;
            if (data['country'] != null) {
              _countryCtrl.text = data['country']!;
            }
          });
        }
        return;
      }

      // Fallback to internal API
      final internal = await ApiClient.instance.fetchPincode(pincode);
      if (internal != null && mounted) {
        setState(() {
          _cityCtrl.text = (internal['city'] ?? '').toString();
          _stateCtrl.text = (internal['state'] ?? '').toString();
          if (internal['country'] != null) {
            _countryCtrl.text = internal['country'].toString();
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching pincode in CustomerDetails: $e');
    }
  }

  Future<void> _loadSavedAddresses() async {
    if (!mounted) return;
    final profile = ProfileProvider.of(context, listen: false).data;
    final uid =
        profile.partnerId.trim().isEmpty ? null : profile.partnerId.trim();
    final list = await AddressStorageService.instance.listForUserId(uid);
    if (!mounted) return;
    setState(() => _savedAddresses = list);
  }

  Future<void> _maybePrefillFromStorage() async {
    if (!mounted) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ShippingDetailsPayload) return;

    if (_fullNameCtrl.text.trim().isNotEmpty) return;

    final profile = ProfileProvider.of(context, listen: false).data;
    final uid =
        profile.partnerId.trim().isEmpty ? null : profile.partnerId.trim();
    final list = await AddressStorageService.instance.listForUserId(uid);
    if (!mounted || list.isEmpty) return;

    final p =
        AddressStorageService.instance.pickPrimaryForCheckout(list).toShippingDetailsPayload();
    setState(() {
      _fullNameCtrl.text = p.fullName;
      _phoneCtrl.text = p.primaryPhone;
      if ((p.email ?? '').trim().isNotEmpty) {
        _emailCtrl.text = p.email!.trim();
      }
      _countryCtrl.text = p.country;
      _stateCtrl.text = p.state;
      _cityCtrl.text = p.city;
      _zipCtrl.text = p.zipCode;
      _address1Ctrl.text = p.shippingAddress;
      if (p.billingAddress != null && _address2Ctrl.text.trim().isEmpty) {
        _address2Ctrl.text = p.billingAddress!;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final partnerId = ProfileProvider.of(context).data.partnerId.trim();
    final guest = partnerId.isEmpty;
    if (_guestBuyer != guest) {
      setState(() => _guestBuyer = guest);
    }

    // Store the original arguments
    _originalArguments = ModalRoute.of(context)?.settings.arguments;

    debugPrint(
        'CustomerDetails: Original arguments type: ${_originalArguments.runtimeType}');
    debugPrint('CustomerDetails: Original arguments: $_originalArguments');

    // Check if we have existing shipping details passed as arguments
    final args = _originalArguments;
    if (args != null && args is ShippingDetailsPayload) {
      final shippingDetails = args;
      _fullNameCtrl.text = shippingDetails.fullName;
      _phoneCtrl.text = shippingDetails.primaryPhone;
      if ((shippingDetails.email ?? '').trim().isNotEmpty) {
        _emailCtrl.text = shippingDetails.email!.trim();
      }
      _countryCtrl.text = shippingDetails.country;
      _stateCtrl.text = shippingDetails.state;
      _cityCtrl.text = shippingDetails.city;
      _zipCtrl.text = shippingDetails.zipCode;
      _address1Ctrl.text = shippingDetails.shippingAddress;
      if (shippingDetails.billingAddress != null) {
        _address2Ctrl.text = shippingDetails.billingAddress!;
      }
    }
  }

  @override
  void dispose() {
    _zipCtrl.removeListener(_onZipChanged);
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _countryCtrl.dispose();
    _stateCtrl.dispose();
    _cityCtrl.dispose();
    _zipCtrl.dispose();
    for (final controller in _allFields) {
      controller.removeListener(_updateFormCompletionState);
    }
    _address1Ctrl.dispose();
    _address2Ctrl.dispose();
    super.dispose();
  }

  void _updateFormCompletionState() {
    final requiredCtrls = [
      _fullNameCtrl,
      _phoneCtrl,
      _countryCtrl,
      _stateCtrl,
      _cityCtrl,
      _zipCtrl,
      _address1Ctrl,
      _address2Ctrl,
      if (_guestBuyer) _emailCtrl,
    ];
    final allFilled =
        requiredCtrls.every((controller) => controller.text.trim().isNotEmpty);
    final nextValue = allFilled;
    if (nextValue != _isFormComplete) {
      setState(() => _isFormComplete = nextValue);
    }
  }

  ShippingDetailsPayload _buildPayload() {
    final emailTrimmed = _emailCtrl.text.trim();
    return ShippingDetailsPayload(
      fullName: _fullNameCtrl.text.trim(),
      primaryPhone: _phoneCtrl.text.trim(),
      secondaryPhone: null,
      country: _countryCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      zipCode: _zipCtrl.text.trim(),
      shippingAddress: _address1Ctrl.text.trim(),
      billingAddress: _address2Ctrl.text.trim().isNotEmpty
          ? _address2Ctrl.text.trim()
          : null,
      email: _guestBuyer && emailTrimmed.isNotEmpty ? emailTrimmed : null,
    );
  }

  void _selectAddress(StoredAddress address) {
    setState(() {
      _fullNameCtrl.text = address.name.trim();
      _phoneCtrl.text = address.phone.trim();
      _emailCtrl.text = address.email?.trim() ?? '';
      _countryCtrl.text = address.country.trim();
      _stateCtrl.text = address.state.trim();
      _cityCtrl.text = address.city.trim();
      _zipCtrl.text = address.pincode.trim();
      _address1Ctrl.text = address.addressLine.trim();
      _address2Ctrl.text = ''; // billingAddress not available in StoredAddress
    });
  }

  Future<void> _handleContinue() async {
    if (_formKey.currentState?.validate() != true) return;

    final profile = ProfileProvider.of(context, listen: false).data;
    final uid =
        profile.partnerId.trim().isEmpty ? null : profile.partnerId.trim();
    final shippingPayload = _buildPayload();
    await AddressStorageService.instance
        .upsertFromShippingDetails(shippingPayload, userId: uid);
    await AddressStorageService.instance
        .writeCheckoutShippingOverride(shippingPayload);
    if (!mounted) return;
    debugPrint(
        'CustomerDetails: Original arguments type: ${_originalArguments.runtimeType}');
    debugPrint('CustomerDetails: Original arguments: $_originalArguments');

    // Check if this is a direct purchase
    if (_originalArguments is CheckoutArguments) {
      final checkoutArgs = _originalArguments as CheckoutArguments;

      debugPrint(
          'CustomerDetails: Direct purchase detected - product: ${checkoutArgs.product.title}, price: ${checkoutArgs.product.price}');

      Navigator.of(context).pushNamed('/checkout', arguments: {
        'directPurchase': checkoutArgs,
        'shippingDetails': shippingPayload,
      });
    } else {
      debugPrint('CustomerDetails: Cart purchase detected');
      Navigator.of(context).pushNamed('/checkout', arguments: shippingPayload);
    }
  }

  String? _required(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static const double _fieldRadius = 8;

  /// Base body size from theme, minus 3px for both input and hint (per spec).
  double _inputFontSize(ThemeData theme) {
    final base = theme.textTheme.bodyLarge?.fontSize ?? 15;
    return (base - 3).clamp(11.0, 18.0);
  }

  InputDecoration _decoration(
    BuildContext context,
    String placeholder, {
    int? maxLines,
    required double inputFontSize,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final hintFontSize = inputFontSize;
    final muted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final idleColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    OutlineInputBorder outline(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      isDense: true,
      hintText: placeholder,
      hintStyle: TextStyle(
        fontSize: hintFontSize,
        fontWeight: FontWeight.w400,
        color: muted.withValues(alpha: 0.88),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      border: outline(idleColor),
      enabledBorder: outline(idleColor),
      focusedBorder: outline(primary, 1.35),
      errorBorder: outline(Colors.red.shade400),
      focusedErrorBorder: outline(Colors.red.shade300, 1.15),
      errorStyle: TextStyle(
        fontSize: (hintFontSize - 1).clamp(10.0, 14.0),
        height: 1.2,
        color: Colors.red.shade700,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: (maxLines != null && maxLines > 1) ? 12 : 10,
      ),
    );
  }

  /// Soft shadow (light) / inset panel (dark) behind the field.
  Widget _fieldShell(BuildContext context, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1724),
          borderRadius: BorderRadius.circular(_fieldRadius),
        ),
        child: child,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_fieldRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_fieldRadius),
        child: child,
      ),
    );
  }

  Widget _shippingField(
    BuildContext context, {
    required TextEditingController controller,
    required String placeholder,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLines,
    bool required = true,
  }) {
    final theme = Theme.of(context);
    final inputSize = _inputFontSize(theme);
    final isDark = theme.brightness == Brightness.dark;

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
        _fieldShell(
          context,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            maxLines: maxLines ?? 1,
            style: TextStyle(
              fontSize: inputSize,
              fontWeight: FontWeight.w500,
              height: 1.25,
              color: theme.colorScheme.onSurface,
            ),
            cursorColor: theme.colorScheme.primary,
            decoration: _decoration(
              context,
              '',
              maxLines: maxLines,
              inputFontSize: inputSize,
              isDark: isDark,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  double _horizontalPadding(double width) {
    if (width >= 1024) return 96.0;
    if (width >= 768) return 64.0;
    return 20.0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _horizontalPadding(constraints.maxWidth);
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final background =
            isDark ? const Color(0xFF070F1B) : Colors.white;

        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: background,
            elevation: 0,
            title: const Text('Shipping Details'),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    horizontalPadding, 14, horizontalPadding, 14),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    if (_savedAddresses.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Saved Address',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _savedAddresses.map((address) => InkWell(
                                onTap: () => _selectAddress(address),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2B9DEE).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF2B9DEE).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    address.name.trim().isEmpty ? 'Address ${_savedAddresses.indexOf(address) + 1}' : address.name.trim(),
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF2B9DEE)),
                                  ),
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _shippingField(
                      context,
                      controller: _fullNameCtrl,
                      placeholder: 'Full name',
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => _required(v, 'Full name'),
                    ),
                    const SizedBox(height: 12),
                    _shippingField(
                      context,
                      controller: _phoneCtrl,
                      placeholder: 'Primary phone number',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        if (v.trim().length != 10) {
                          return 'Phone number must be exactly 10 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _shippingField(
                      context,
                      controller: _emailCtrl,
                      placeholder: 'Email (order updates)',
                      keyboardType: TextInputType.emailAddress,
                      textCapitalization: TextCapitalization.none,
                      required: false,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return null;
                        }
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _shippingField(
                      context,
                      controller: _zipCtrl,
                      placeholder: 'Pin Code',
                      keyboardType: TextInputType.text,
                      validator: (v) => _required(v, 'Pin Code'),
                    ),
                    const SizedBox(height: 12),
                    _shippingField(
                      context,
                      controller: _countryCtrl,
                      placeholder: 'Country',
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => _required(v, 'Country'),
                    ),
                    const SizedBox(height: 12),
                    _shippingField(
                      context,
                      controller: _stateCtrl,
                      placeholder: 'State / Province',
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => _required(v, 'State / Province'),
                    ),
                    const SizedBox(height: 12),
                    _shippingField(
                      context,
                      controller: _cityCtrl,
                      placeholder: 'City',
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => _required(v, 'City'),
                    ),
                    const SizedBox(height: 12),
                    _shippingField(
                      context,
                      controller: _address1Ctrl,
                      placeholder: 'Address line 1',
                      validator: (v) => _required(v, 'Address line 1'),
                    ),
                    const SizedBox(height: 12),
                    _shippingField(
                      context,
                      controller: _address2Ctrl,
                      placeholder: 'Address line 2',
                      validator: (v) => _required(v, 'Address line 2'),
                    ),
                  ],
                ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: background,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: ElevatedButton(
                    onPressed: _isFormComplete ? _handleContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B9DEE),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 6,
                      shadowColor:
                          const Color(0xFF2B9DEE).withValues(alpha: 0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Proceed to Checkout',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward,
                            size: 20, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _NavItem(
                        icon: Icons.home,
                        label: 'Home',
                        onTap: () =>
                            Navigator.of(context).pushReplacementNamed('/'),
                      ),
                      _NavItem(
                        icon: Icons.grid_view,
                        label: 'Shop',
                        onTap: () => Navigator.of(context)
                            .pushNamed(AllProductsScreen.routeName),
                      ),
                      _NavItem(
                        icon: Icons.account_balance_wallet,
                        label: 'Wallet',
                        onTap: () => Navigator.of(context)
                            .pushNamed(WalletScreen.routeName),
                      ),
                      _NavItem(
                        icon: Icons.person,
                        label: 'Profile',
                        onTap: () => Navigator.of(context)
                            .pushNamed(ProfileScreen.routeName),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
