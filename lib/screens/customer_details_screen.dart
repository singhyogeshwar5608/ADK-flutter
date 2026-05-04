import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigation/checkout_arguments.dart';
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

  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _address1Ctrl = TextEditingController();
  final _address2Ctrl = TextEditingController();

  bool _isFormComplete = false;
  dynamic _originalArguments;

  @override
  void initState() {
    super.initState();

    // Add listeners
    for (final controller in _requiredControllers) {
      controller.addListener(_updateFormCompletionState);
    }
    _updateFormCompletionState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

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
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _stateCtrl.dispose();
    _cityCtrl.dispose();
    _zipCtrl.dispose();
    for (final controller in _requiredControllers) {
      controller.removeListener(_updateFormCompletionState);
    }
    _address1Ctrl.dispose();
    _address2Ctrl.dispose();
    super.dispose();
  }

  List<TextEditingController> get _requiredControllers => [
        _fullNameCtrl,
        _phoneCtrl,
        _stateCtrl,
        _cityCtrl,
        _zipCtrl,
        _address1Ctrl,
      ];

  void _updateFormCompletionState() {
    final allFilled = _requiredControllers
        .every((controller) => controller.text.trim().isNotEmpty);
    final nextValue = allFilled;
    if (nextValue != _isFormComplete) {
      setState(() => _isFormComplete = nextValue);
    }
  }

  ShippingDetailsPayload _buildPayload() {
    return ShippingDetailsPayload(
      fullName: _fullNameCtrl.text.trim(),
      primaryPhone: _phoneCtrl.text.trim(),
      secondaryPhone: null,
      state: _stateCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      zipCode: _zipCtrl.text.trim(),
      shippingAddress: _address1Ctrl.text.trim(),
      billingAddress: _address2Ctrl.text.trim().isNotEmpty
          ? _address2Ctrl.text.trim()
          : null,
    );
  }

  void _handleContinue() {
    if (_formKey.currentState?.validate() != true) return;

    debugPrint(
        'CustomerDetails: Original arguments type: ${_originalArguments.runtimeType}');
    debugPrint('CustomerDetails: Original arguments: $_originalArguments');

    // Check if this is a direct purchase
    if (_originalArguments is CheckoutArguments) {
      // For direct purchase, pass both CheckoutArguments and ShippingDetailsPayload
      final checkoutArgs = _originalArguments as CheckoutArguments;
      final shippingPayload = _buildPayload();

      debugPrint(
          'CustomerDetails: Direct purchase detected - product: ${checkoutArgs.product.title}, price: ${checkoutArgs.product.price}');

      // Create a combined payload that includes both
      Navigator.of(context).pushNamed('/checkout', arguments: {
        'directPurchase': checkoutArgs,
        'shippingDetails': shippingPayload,
      });
    } else {
      // For cart purchase, pass only shipping details
      debugPrint('CustomerDetails: Cart purchase detected');
      Navigator.of(context).pushNamed('/checkout', arguments: _buildPayload());
    }
  }

  String? _required(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  InputDecoration _decoration(BuildContext context, String placeholder,
      {int? maxLines}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: isDark ? const Color(0xFF273548) : const Color(0xFFE2E8F0),
      ),
    );

    return InputDecoration(
      hintText: placeholder,
      filled: true,
      fillColor: isDark ? const Color(0xFF0F1724) : const Color(0xFFF8FAFC),
      border: baseBorder,
      enabledBorder: baseBorder,
      focusedBorder: baseBorder.copyWith(
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary, width: 1.4),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 18,
        vertical: (maxLines != null && maxLines > 1) ? 16 : 14,
      ),
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
            isDark ? const Color(0xFF070F1B) : const Color(0xFFF3F6FB);

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
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    horizontalPadding, 14, horizontalPadding, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _fullNameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: _decoration(context, 'Full name'),
                      validator: (v) => _required(v, 'Full name'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(
                            10), // Limit to 10 digits
                      ],
                      decoration: _decoration(context, 'Primary phone number'),
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
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _stateCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: _decoration(context, 'State / Province'),
                      validator: (v) => _required(v, 'State / Province'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _cityCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: _decoration(context, 'City'),
                      validator: (v) => _required(v, 'City'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _zipCtrl,
                      keyboardType: TextInputType.text,
                      decoration: _decoration(context, 'ZIP / Postal code'),
                      validator: (v) => _required(v, 'ZIP / Postal code'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _address1Ctrl,
                      decoration: _decoration(context, 'Address line 1'),
                      validator: (v) => _required(v, 'Address line 1'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _address2Ctrl,
                      decoration:
                          _decoration(context, 'Address line 2 (optional)'),
                    ),
                  ],
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
