import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'checkout_razorpay.dart';
import '../models/stored_address.dart';
import '../navigation/checkout_arguments.dart';
import '../services/address_storage_service.dart';
import '../state/cart_state.dart';
import '../state/profile_state.dart';
import '../theme/app_theme.dart';
import 'addresses_screen.dart';
import '../config/api_config.dart';
import '../utils/auth_helper.dart';
import '../utils/error_message_helper.dart';
import '../services/api_client.dart';
import 'customer_details_screen.dart';

bool _checkoutShippingComplete(
  ShippingDetailsPayload? s, {
  bool guestCheckout = false,
}) {
  if (s == null) return false;
  bool ok(String x) => x.trim().isNotEmpty;
  final base = ok(s.fullName) &&
      ok(s.primaryPhone) &&
      ok(s.state) &&
      ok(s.city) &&
      ok(s.zipCode) &&
      ok(s.shippingAddress);
  if (!base) return false;
  if (!guestCheckout) return true;
  final e = (s.email ?? '').trim();
  return e.isNotEmpty &&
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
}

String _checkoutShortSavedLabel(StoredAddress a) {
  if (a.name.trim().isNotEmpty) {
    final p = a.pincode.trim();
    return p.isNotEmpty ? '${a.name.trim()} · $p' : a.name.trim();
  }
  final c = a.city.trim();
  if (c.isNotEmpty) return c;
  return 'Address';
}

/// Compact selectable pill — avoids oversized default [ChoiceChip] on checkout.
class _CompactCheckoutAddressChip extends StatelessWidget {
  const _CompactCheckoutAddressChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final borderIdle = isDark
        ? const Color(0xFF3D4F6B).withValues(alpha: 0.9)
        : const Color(0xFFCBD5E1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withValues(alpha: isDark ? 0.22 : 0.1)
                : (isDark ? const Color(0xFF141D2E) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? cs.primary : borderIdle,
              width: selected ? 1.25 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.12,
                letterSpacing: -0.1,
                color: selected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.82),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isProcessing = false;
  Razorpay? _razorpay;
  ShippingDetailsPayload? _prefsShipping;
  ShippingDetailsPayload? _manualShipping;
  ShippingDetailsPayload? _cartBootstrapShipping;
  bool _cartBootstrapScheduled = false;
  List<StoredAddress> _savedAddresses = [];

  @override
  void initState() {
    super.initState();
    // Initialize Razorpay only on mobile platforms
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay!
          .on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccessResponse);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentErrorResponse);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _reloadShippingContext());
  }

  Future<void> _reloadShippingContext() async {
    if (!mounted) return;
    final profile = ProfileProvider.of(context, listen: false).data;
    final uid =
        profile.partnerId.trim().isEmpty ? null : profile.partnerId.trim();
    final p = await AddressStorageService.instance.readCheckoutShippingOverride();
    final saved = await AddressStorageService.instance.listForUserId(uid);
    if (!mounted) return;
    setState(() {
      _prefsShipping = p;
      _savedAddresses = saved;
    });
  }

  Future<void> _openAddressBook() async {
    await Navigator.of(context).pushNamed(
      AddressesScreen.routeName,
      arguments: const AddressesScreenArgs(selectForCheckout: true),
    );
    if (!mounted) return;
    await _reloadShippingContext();
    setState(() => _manualShipping = null);
  }

  Future<void> _selectSavedCheckout(StoredAddress a) async {
    final profile = ProfileProvider.of(context, listen: false).data;
    final uid =
        profile.partnerId.trim().isEmpty ? null : profile.partnerId.trim();
    final payload = a.toShippingDetailsPayload();
    setState(() => _manualShipping = payload);
    await AddressStorageService.instance.writeCheckoutShippingOverride(payload);
    if (!mounted) return;
    await AddressStorageService.instance.markAddressUsed(a.id, userId: uid);
  }

  Future<void> _tryResolveCartWithoutArgs() async {
    if (!mounted) return;
    final cart = CartProvider.of(context, listen: false);
    if (cart.items.isEmpty) return;

    final profile = ProfileProvider.of(context, listen: false).data;
    final uid =
        profile.partnerId.trim().isEmpty ? null : profile.partnerId.trim();
    final list = await AddressStorageService.instance.listForUserId(uid);
    if (!mounted) return;

    if (list.isEmpty) {
      Navigator.of(context)
          .pushReplacementNamed(CustomerDetailsScreen.routeName);
      return;
    }

    // Don't auto-pick address, let user choose from saved addresses
    // The _cartBootstrapShipping will be set when user selects an address
  }

  Future<void> _handlePayPressed(
    double total,
    ShippingDetailsPayload? mergedShipping,
    bool guestCheckout,
  ) async {
    if (!_checkoutShippingComplete(
      mergedShipping,
      guestCheckout: guestCheckout,
    )) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            guestCheckout
                ? 'Add your full shipping details and email before paying.'
                : 'Add a complete delivery address before paying.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    await _initiatePayment(total);
  }

  void _handlePaymentSuccess(String paymentId, String orderId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isProcessing = false);
        if (mounted) {
          ProfileProvider.of(context, listen: false).refresh();
        }
      }
    });
    // Silence UI popups per requirement; log for debugging instead.
    debugPrint('Payment Successful! ID: $paymentId Order: $orderId');
    
    // Send WhatsApp notification
    final profile = ProfileProvider.of(context, listen: false).data;
    _sendOrderWhatsApp(
      paymentId: paymentId,
      orderId: orderId,
      shiprocketOrderId: null,
      shipmentId: null,
      awbCode: null,
      courierName: null,
      trackingUrl: null,
      cart: CartProvider.of(context, listen: false),
      shippingDetails: _manualShipping ??
          _prefsShipping ??
          _cartBootstrapShipping,
      directPurchase: ModalRoute.of(context)?.settings.arguments is CheckoutArguments
          ? ModalRoute.of(context)?.settings.arguments as CheckoutArguments
          : (ModalRoute.of(context)?.settings.arguments is Map<String, dynamic>
              ? (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>)['directPurchase']
              : null),
      memberId: profile.partnerId.isNotEmpty ? profile.partnerId : null,
      serialNo: profile.dbId.isNotEmpty ? profile.dbId : null,
      profilePhone: profile.phone,
      profileType: profile.membershipTier,
    );
    
    // TODO: Verify payment on backend and create order
  }

  void _handlePaymentError(String error) {
    setState(() => _isProcessing = false);
    debugPrint('Payment Failed: $error');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(parseApiError(error)),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _initiatePayment(double amount) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Create order on backend
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payment/create-order'),
        headers: {
          ...ApiConfig.jsonHeaders,
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: json.encode({
          'amount': amount,
          'currency': 'INR',
          'receipt': 'order_${DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create order');
      }

      final data = json.decode(response.body);

      if (!data['success']) {
        throw Exception(data['message'] ?? 'Failed to create order');
      }

      // Open Razorpay checkout - platform specific
      if (kIsWeb) {
        openRazorpayWebCheckout(
          keyId: data['key_id'].toString(),
          orderId: data['order_id'].toString(),
          amount: amount,
          onSuccess: _handlePaymentSuccess,
          onError: _handlePaymentError,
        );
      } else {
        var options = {
          'key': data['key_id'],
          'amount': (amount * 100).toInt(), // Amount in paise
          'currency': 'INR',
          'name': 'ADK Pvt. Ltd.',
          'description': 'Order Payment',
          'order_id': data['order_id'],
          'prefill': {
            'contact': '9999999999',
            'email': 'customer@example.com',
          },
          'theme': {
            'color': '#3399cc',
          },
        };
        _razorpay!.open(options);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      debugPrint('Error: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(parseApiError(e)),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Razorpay SDK event handlers
  void _handlePaymentSuccessResponse(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    _handlePaymentSuccess(response.paymentId ?? '', response.orderId ?? '');
  }

  void _handlePaymentErrorResponse(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    _handlePaymentError(response.message ?? 'Payment failed');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  Future<String> _getAuthToken() async {
    // Use our unified auth helper
    return await AuthHelper.getAuthToken();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cart = CartProvider.of(context);
    final args = ModalRoute.of(context)?.settings.arguments;
    CheckoutArguments? directPurchase;
    ShippingDetailsPayload? shippingDetails;

    if (args is Map<String, dynamic>) {
      // Handle combined payload from customer details
      directPurchase = args['directPurchase'] as CheckoutArguments?;
      shippingDetails = args['shippingDetails'] as ShippingDetailsPayload?;
      debugPrint(
          'Checkout: Combined payload - directPurchase: $directPurchase, shippingDetails: $shippingDetails');
    } else if (args is CheckoutArguments) {
      directPurchase = args;
      debugPrint('Checkout: Direct purchase - $directPurchase');
    } else if (args is ShippingDetailsPayload) {
      shippingDetails = args;
      debugPrint('Checkout: Cart purchase - $shippingDetails');
    } else {
      debugPrint('Checkout: Unknown args type - $args');

      // If no arguments, check if cart has items and redirect to customer details
      if (cart.items.isEmpty) {
        debugPrint(
            'Checkout: No items in cart and no arguments - showing empty state');
        // Show empty cart state or redirect
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).maybePop();
          }
        });
      } else {
        debugPrint(
            'Checkout: Cart has items but no routing args — loading saved addresses if any.');
        if (!_cartBootstrapScheduled) {
          _cartBootstrapScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _tryResolveCartWithoutArgs();
          });
        }
      }
    }

    final mergedShipping = _manualShipping ??
        shippingDetails ??
        _prefsShipping ??
        _cartBootstrapShipping;

    final country = mergedShipping?.country ?? 'India';
    final state = mergedShipping?.state ?? 'Haryana';

    double subtotalValue = 0;
    double taxValue = 0;
    double totalValue = 0;
    double unitPriceValue = 0;
    String gstType = 'GST';
    double gstPercent = 0;

    final countryNorm = country.toLowerCase().trim();
    final stateNorm = state.toLowerCase().trim();

    if (countryNorm == 'india' || countryNorm == 'in') {
      if (stateNorm == 'haryana' || stateNorm == 'hr') {
        gstType = 'SGST';
      } else {
        gstType = 'CGST';
      }
    } else {
      gstType = 'IGST';
    }

    if (directPurchase != null) {
      final data = directPurchase.product.calculateDynamicPrice(country, state);
      final basePrice = data['basePrice'] as double;
      final gstAmount = data['gstAmount'] as double;
      unitPriceValue = data['finalPrice'] as double;
      gstPercent = data['gstPercent'] as double;
      
      subtotalValue = basePrice * directPurchase.quantity;
      taxValue = gstAmount * directPurchase.quantity;
      totalValue = subtotalValue + taxValue;
    } else {
      double totalGstAmount = 0;
      double totalBasePrice = 0;
      final selectedItems = cart.items.where((i) => i.isSelected);
      for (final item in selectedItems) {
        final data = item.product.calculateDynamicPrice(country, state);
        totalGstAmount += (data['gstAmount'] as double) * item.quantity;
        totalBasePrice += (data['basePrice'] as double) * item.quantity;
      }
      if (totalBasePrice > 0) {
        gstPercent = (totalGstAmount / totalBasePrice) * 100;
      }

      subtotalValue = cart.selectedSubtotal(country, state);
      taxValue = cart.selectedTax(country, state);
      totalValue = cart.selectedTotal(country, state);
    }

    final totalBv = directPurchase != null
        ? directPurchase.product.bv * directPurchase.quantity
        : cart.selectedTotalBv;

    final guestCheckout =
        ProfileProvider.of(context).data.partnerId.trim().isEmpty;

    final pageBg = isDark
        ? AppColors.backgroundDark
        : const Color(0xFFE8EEF5);

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                _CheckoutHeader(
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: _CheckoutBody(
                    cart: cart,
                    directPurchase: directPurchase,
                    shippingDetails: mergedShipping,
                    guestCheckout: guestCheckout,
                    subtotal: subtotalValue,
                    tax: taxValue,
                    total: totalValue,
                    totalBv: totalBv,
                    gstType: gstType,
                    gstPercent: gstPercent,
                    unitPrice: unitPriceValue,
                    shippingCountry: country,
                    shippingState: state,
                    onOpenAddressBook: _openAddressBook,
                    savedAddresses: _savedAddresses,
                    onSelectSavedAddress: _selectSavedCheckout,
                    onEditShipping: () async {
                      if (!mounted) return;
                      await _reloadShippingContext();
                      setState(() => _manualShipping = null);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: _MockOrderButton(
                    total: totalValue,
                    tax: taxValue,
                    unitPrice: unitPriceValue,
                    directPurchase: directPurchase,
                    cart: cart,
                    shippingDetails: mergedShipping,
                    guestCheckout: guestCheckout,
                  ),
                ),
                _CheckoutFooter(
                  total: totalValue,
                  isProcessing: _isProcessing,
                  onPayNow: () =>
                      _handlePayPressed(totalValue, mergedShipping, guestCheckout),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckoutHeader extends StatelessWidget {
  const _CheckoutHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? const Color(0xFF243042) : const Color(0xFFE2E8F0);

    return Material(
      color: surface,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: border),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(4, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: onBack,
              style: IconButton.styleFrom(
                visualDensity: VisualDensity.standard,
                foregroundColor: theme.colorScheme.onSurface,
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 22),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'SECURE CHECKOUT',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.35,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.42),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Checkout',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.35,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

class _CheckoutBody extends StatelessWidget {
  const _CheckoutBody({
    required this.cart,
    this.directPurchase,
    this.shippingDetails,
    required this.guestCheckout,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.totalBv,
    required this.gstType,
    required this.gstPercent,
    required this.unitPrice,
    required this.shippingCountry,
    required this.shippingState,
    required this.onOpenAddressBook,
    required this.savedAddresses,
    required this.onSelectSavedAddress,
    required this.onEditShipping,
  });

  final CartState cart;
  final CheckoutArguments? directPurchase;
  final ShippingDetailsPayload? shippingDetails;
  final bool guestCheckout;
  final double subtotal;
  final double tax;
  final double total;
  final int totalBv;
  final String gstType;
  final double gstPercent;
  final double unitPrice;
  final String shippingCountry;
  final String shippingState;
  final VoidCallback onOpenAddressBook;
  final List<StoredAddress> savedAddresses;
  final ValueChanged<StoredAddress> onSelectSavedAddress;
  final Future<void> Function() onEditShipping;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ShippingSection(
            shippingDetails: shippingDetails,
            guestCheckout: guestCheckout,
            onOpenAddressBook: onOpenAddressBook,
            savedAddresses: savedAddresses,
            onSelectSavedAddress: onSelectSavedAddress,
            onEditShipping: onEditShipping,
          ),
          const SizedBox(height: 22),
          _OrderSummaryCard(
            cart: cart,
            directPurchase: directPurchase,
            subtotal: subtotal,
            tax: tax,
            total: total,
            totalBv: totalBv,
            gstType: gstType,
            gstPercent: gstPercent,
            unitPrice: unitPrice,
            shippingCountry: shippingCountry,
            shippingState: shippingState,
          ),
        ],
      ),
    );
  }
}

class _ShippingSection extends StatelessWidget {
  const _ShippingSection({
    this.shippingDetails,
    required this.guestCheckout,
    required this.onOpenAddressBook,
    required this.savedAddresses,
    required this.onSelectSavedAddress,
    required this.onEditShipping,
  });

  final ShippingDetailsPayload? shippingDetails;
  final bool guestCheckout;
  final VoidCallback onOpenAddressBook;
  final List<StoredAddress> savedAddresses;
  final ValueChanged<StoredAddress> onSelectSavedAddress;
  final Future<void> Function() onEditShipping;

  String? _dedupeKey(ShippingDetailsPayload p) =>
      StoredAddress.fromShippingDetails(p, id: '_', lastUsedAt: 0).dedupeKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final card = isDark ? AppColors.darkSurface : Colors.white;
    final border = isDark ? const Color(0xFF2A3A52) : const Color(0xFFE2E8F0);

    final hasDetails = shippingDetails != null &&
        _checkoutShippingComplete(
          shippingDetails,
          guestCheckout: guestCheckout,
        );
    final addressLines = hasDetails
        ? [
            shippingDetails!.shippingAddress,
            '${shippingDetails!.city}, ${shippingDetails!.state} ${shippingDetails!.zipCode}',
            'Phone: ${shippingDetails!.primaryPhone}',
            if ((shippingDetails!.email ?? '').trim().isNotEmpty)
              'Email: ${shippingDetails!.email!.trim()}',
            if (shippingDetails!.secondaryPhone != null)
              'Alt: ${shippingDetails!.secondaryPhone}',
          ]
        : ['123 Innovation Drive, Tech City, Suite 400, CA 94103'];

    final actionLabelStyle = theme.textTheme.labelMedium?.copyWith(
      color: cs.primary,
      fontWeight: FontWeight.w700,
      fontSize: 11.5,
      height: 1.1,
      letterSpacing: -0.05,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DELIVERY',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.25,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Shipping address',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      height: 1.15,
                      fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) - 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: isDark ? 0.12 : 0.07),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.26),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onOpenAddressBook,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        child: Text('Saved', style: actionLabelStyle),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 16,
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      indent: 0,
                      endIndent: 0,
                      color: cs.primary.withValues(alpha: 0.22),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await Navigator.of(context).pushNamed(
                          CustomerDetailsScreen.routeName,
                          arguments: shippingDetails,
                        );
                        if (!context.mounted) return;
                        await onEditShipping();
                      },
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 4),
                            Text('Edit', style: actionLabelStyle),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (savedAddresses.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Select delivery address',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: cs.onSurface.withValues(alpha: 0.5),
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 6),
          ...savedAddresses.map((address) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CompactCheckoutAddressChip(
              label: _checkoutShortSavedLabel(address),
              selected: shippingDetails != null &&
                  address.dedupeKey == _dedupeKey(shippingDetails!),
              onTap: () => onSelectSavedAddress(address),
            ),
          )).toList(),
        ],
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark ? 0.22 : 0.05,
                ),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.local_shipping_outlined,
                      color: cs.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasDetails ? shippingDetails!.fullName : 'Home',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                          height: 1.2,
                          fontSize: (theme.textTheme.titleSmall?.fontSize ?? 14) - 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        addressLines.join('\n'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          height: 1.45,
                          color: cs.onSurface.withValues(alpha: 0.68),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.cart,
    this.directPurchase,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.totalBv,
    required this.gstType,
    required this.gstPercent,
    required this.unitPrice,
    required this.shippingCountry,
    required this.shippingState,
  });

  final CartState cart;
  final CheckoutArguments? directPurchase;
  final double subtotal;
  final double tax;
  final double total;
  final int totalBv;
  final String gstType;
  final double gstPercent;
  final double unitPrice;
  final String shippingCountry;
  final String shippingState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final card = isDark ? AppColors.darkSurface : Colors.white;
    final border = isDark ? const Color(0xFF2A3A52) : const Color(0xFFE2E8F0);
    final muted = cs.onSurface.withValues(alpha: 0.62);

    final quantity = directPurchase != null 
        ? directPurchase!.quantity 
        : cart.items.where((i) => i.isSelected).length;
    final itemLabel = '$quantity ${quantity == 1 ? 'Item' : 'Items'}';
    final isDirect = directPurchase != null;

    String format(double value) => '₹${value.toStringAsFixed(2)}';

    Widget summaryRow(
      String label,
      String value, {
      Color? valueColor,
      FontWeight valueWeight = FontWeight.w600,
      double labelSize = 11,
      double valueSize = 11,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w500,
                  color: muted,
                  height: 1.2,
                ),
              ),
            ),
            Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: valueSize,
                fontWeight: valueWeight,
                color: valueColor ?? cs.onSurface,
                height: 1.2,
              ),
            ),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR ORDER',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.25,
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order summary',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          height: 1.1,
                          fontSize:
                              (theme.textTheme.titleMedium?.fontSize ?? 16) - 2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E2A3D)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: border.withValues(alpha: 0.85),
                    ),
                  ),
                  child: Text(
                    itemLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      letterSpacing: 0.2,
                      color: cs.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (isDirect) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF141D2E)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF243042)
                        : const Color(0xFFE8EEF4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        directPurchase!.product.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: -0.15,
                          fontSize:
                              (theme.textTheme.titleSmall?.fontSize ?? 14) - 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Qty ${directPurchase!.quantity} · ${format(unitPrice)} each',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10.5,
                          color: muted,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            summaryRow(
              'Total Business Volume (BV)',
              '$totalBv BV',
              valueColor: cs.primary,
              valueWeight: FontWeight.w700,
            ),
            const Divider(height: 16),
            summaryRow('Subtotal', format(subtotal)),
            summaryRow(gstType, format(tax), valueColor: AppColors.mlmGreen),
            const Divider(height: 24),
            summaryRow(
              'Total Payable', 
              format(total), 
              valueColor: cs.primary, 
              valueWeight: FontWeight.w800,
              labelSize: 13,
              valueSize: 15,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.mlmGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.mlmGreen.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 14,
                    color: AppColors.mlmGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'GST calculated based on shipping address: $shippingState, $shippingCountry',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mlmGreen,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutFooter extends StatelessWidget {
  const _CheckoutFooter({
    required this.total,
    required this.onPayNow,
    this.isProcessing = false,
  });

  final double total;
  final VoidCallback onPayNow;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkCard : Colors.white;
    final line = isDark ? const Color(0xFF243042) : const Color(0xFFE2E8F0);
    final headline = theme.textTheme.headlineSmall;
    final totalRupeeFontSize = (headline?.fontSize ?? 24) - 7;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: line)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TOTAL AMOUNT',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: cs.onSurface.withValues(alpha: 0.48),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${total.toStringAsFixed(2)}',
                        style: headline?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: totalRupeeFontSize,
                          letterSpacing: -0.4,
                          height: 1.05,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: isProcessing ? null : onPayNow,
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    minimumSize: const Size(88, 44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                            'Pay',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 0.2,
                              color: Colors.white,
                            ),
                          ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: line.withValues(alpha: 0.75)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 15,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Secure encrypted checkout'.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.15,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MockOrderButton extends StatelessWidget {
  const _MockOrderButton({
    required this.total,
    required this.tax,
    required this.unitPrice,
    this.directPurchase,
    required this.cart,
    this.shippingDetails,
    required this.guestCheckout,
  });

  final double total;
  final double tax;
  final double unitPrice;
  final CheckoutArguments? directPurchase;
  final CartState cart;
  final ShippingDetailsPayload? shippingDetails;
  final bool guestCheckout;

  Future<void> _createMockOrder(BuildContext context) async {
    try {
      debugPrint('Mock Order: Creating test order...');

      final country = shippingDetails?.country ?? 'India';
      final state = shippingDetails?.state ?? 'Haryana';

      // Prepare order data
      final Map<String, dynamic> orderData = {
        'total_amount': total,
        'tax_amount': tax,
        'base_subtotal': total - tax,
        'receipt': 'order_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}',
        'items': directPurchase != null
            ? [
                {
                  'product_id': directPurchase!.product.id,
                  'product_name': directPurchase!.product.title,
                  'quantity': directPurchase!.quantity,
                  'price': unitPrice, // Dynamic price
                  'bv': directPurchase!.product.bv,
                  'total_bv':
                      directPurchase!.product.bv * directPurchase!.quantity,
                }
              ]
            : cart.items
                .where((i) => i.isSelected)
                .map((item) => {
                      'product_id': item.product.id,
                      'product_name': item.product.title,
                      'quantity': item.quantity,
                      'price': item.unitPrice(country, state), // Dynamic price
                      'bv': item.product.bv,
                      'total_bv': item.product.bv * item.quantity,
                    })
                .toList(),
        'shipping_details': shippingDetails != null
            ? {
                'full_name': shippingDetails!.fullName,
                if ((shippingDetails!.email ?? '').trim().isNotEmpty)
                  'email': shippingDetails!.email!.trim(),
                'phone': shippingDetails!.primaryPhone,
                'state': shippingDetails!.state,
                'city': shippingDetails!.city,
                'zip_code': shippingDetails!.zipCode,
                'address': shippingDetails!.shippingAddress,
              }
            : null,
      };

      debugPrint(
          'Mock Order: Order data prepared - ${orderData['items']?.length ?? 0} items');

      late final http.Response response;

      if (guestCheckout) {
        if (!_checkoutShippingComplete(
          shippingDetails,
          guestCheckout: true,
        )) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Guest checkout needs a valid email. Tap Edit on shipping and save your details.',
                ),
                duration: Duration(seconds: 5),
              ),
            );
          }
          return;
        }
        final s = shippingDetails!;
        orderData['shipping_address'] = {
          'full_name': s.fullName,
          'email': s.email!.trim(),
          'phone': s.primaryPhone,
          'state': s.state,
          'city': s.city,
          'zip_code': s.zipCode,
          'address': s.shippingAddress,
        };
        response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/orders/guest-checkout'),
          headers: ApiConfig.jsonHeaders,
          body: json.encode(orderData),
        );
      } else {
        final token = await ApiClient.instance.resolveStoredMemberToken();
        if (token == null || token.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Sign in from Profile to create a member test order, or use guest checkout while logged out.',
                ),
                duration: Duration(seconds: 5),
              ),
            );
          }
          return;
        }
        response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/orders/mock'),
          headers: {
            ...ApiConfig.jsonHeaders,
            'Authorization': 'Bearer $token',
          },
          body: json.encode(orderData),
        );
      }

      debugPrint('Mock Order: API response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        debugPrint(
            'Mock Order: Order created successfully - ID: ${responseData['order']['id']}');
        debugPrint('Mock Order: BV awarded: ${responseData['bv_awarded']}');

        // Open WhatsApp with order details using backend-generated wa.me link
        final whatsAppLink = responseData['whatsapp_link'] as String?;
        if (whatsAppLink != null && whatsAppLink.isNotEmpty) {
          final uri = Uri.parse(whatsAppLink);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } else {
          // Fallback: send WhatsApp notification from Flutter
          final profile = ProfileProvider.of(context, listen: false).data;
          _sendOrderWhatsApp(
            paymentId: 'MOCK_PAYMENT',
            orderId: responseData['order']['id'].toString(),
            shiprocketOrderId: responseData['order']['shiprocketOrderId'] ?? responseData['order']['shiprocket_order_id'],
            shipmentId: responseData['order']['shipmentId'] ?? responseData['order']['shipment_id'],
            awbCode: responseData['order']['awbCode'] ?? responseData['order']['awb_code'],
            courierName: responseData['order']['courierName'] ?? responseData['order']['courier_name'],
            trackingUrl: responseData['order']['trackingUrl'] ?? responseData['order']['tracking_url'] ?? responseData['tracking_url'],
            cart: cart,
            shippingDetails: shippingDetails,
            directPurchase: directPurchase,
            memberId: profile.partnerId.isNotEmpty ? profile.partnerId : null,
            serialNo: profile.dbId.isNotEmpty ? profile.dbId : null,
            profilePhone: profile.phone,
            profileType: profile.membershipTier,
          );
        }

        // Refresh profile immediately to update BV & wallet
        if (context.mounted) {
          ProfileProvider.of(context, listen: false).refresh();
        }

        // Show success dialog with real data
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Mock Order Created!'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order Status: Completed'),
                    const SizedBox(height: 8),
                    Text('Order ID: #${responseData['order']['id']}'),
                    const SizedBox(height: 8),
                    Text('Items: ${orderData['items']?.length ?? 0}'),
                    const SizedBox(height: 8),
                    Text('Total: ₹${total.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    Text(
                        'BV Points Awarded: ${responseData['bv_awarded'] ?? _calculateTotalBv(orderData)}'),
                    const SizedBox(height: 8),
                    if (guestCheckout) ...[
                      const Text('✅ Guest order saved to database.'),
                      const SizedBox(height: 8),
                      const Text(
                        'Retail checkout — BV / MLM income is not applied.',
                      ),
                    ] else ...[
                      const Text('✅ Order saved to database!'),
                      const SizedBox(height: 8),
                      const Text('✅ Income calculations updated!'),
                      const SizedBox(height: 8),
                      const Text('✅ BV points distributed!'),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Refresh profile to show updated BV and income
                      if (context.mounted) {
                        ProfileProvider.of(context, listen: false).refresh();
                      }
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        final errorMsg = _parseOrderError(response);
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('Mock Order: Error creating order - $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(parseApiError(e)),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  String _parseOrderError(http.Response response) {
    try {
      final body = json.decode(response.body);
      if (body is Map<String, dynamic>) {
        final msg = body['message'] as String?;
        if (msg != null && msg.isNotEmpty) return msg;
        final errors = body['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
          if (first is String) return first;
        }
        final error = body['error'] as String?;
        if (error != null && error.isNotEmpty) return error;
      }
    } catch (_) {}

    switch (response.statusCode) {
      case 400:
        return 'Invalid order data. Please check your items and try again.';
      case 401:
        return 'Please login to place an order.';
      case 403:
        return 'You are not allowed to place this order.';
      case 404:
        return 'Order service not available. Please try again later.';
      case 409:
        return 'This order has already been placed.';
      case 422:
        return 'Some order details are invalid. Please review and try again.';
      case 429:
        return 'Too many orders. Please wait a moment and try again.';
      default:
        return 'Unable to create order (Error ${response.statusCode}). Please try again.';
    }
  }

  int _calculateTotalBv(Map<String, dynamic> orderData) {
    int totalBv = 0;
    if (orderData['items'] != null) {
      for (var item in orderData['items']) {
        totalBv += (item['total_bv'] ?? 0) as int;
      }
    }
    return totalBv;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orange = AppColors.accentAmber;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _createMockOrder(context),
        icon: Icon(Icons.science_outlined, size: 20, color: orange),
        label: Text(
          'Create Mock Order (Testing)',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: orange,
            letterSpacing: 0.15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: orange,
          side: BorderSide(color: orange.withValues(alpha: 0.85), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: theme.brightness == Brightness.dark
              ? orange.withValues(alpha: 0.08)
              : orange.withValues(alpha: 0.06),
        ),
      ),
    );
  }
}

Future<void> _sendOrderWhatsApp({
  required String paymentId,
  required String orderId,
  dynamic shiprocketOrderId,
  dynamic shipmentId,
  dynamic awbCode,
  dynamic courierName,
  dynamic trackingUrl,
  required CartState cart,
  required ShippingDetailsPayload? shippingDetails,
  required CheckoutArguments? directPurchase,
  String? memberId,
  String? serialNo,
  String? profilePhone,
  String? profileType,
}) async {
  final country = shippingDetails?.country ?? 'India';
  final state = shippingDetails?.state ?? 'Haryana';

  double subtotal = 0;
  double tax = 0;

  if (directPurchase != null) {
    final data = directPurchase.product.calculateDynamicPrice(country, state);
    subtotal = (data['basePrice'] as double) * directPurchase.quantity;
    tax = (data['gstAmount'] as double) * directPurchase.quantity;
  } else {
    subtotal = cart.selectedSubtotal(country, state);
    tax = cart.selectedTax(country, state);
  }
  final total = subtotal + tax;

  String itemsText = '';
  if (directPurchase != null) {
    itemsText =
        '- ${directPurchase.product.title} (Qty: ${directPurchase.quantity}, Price: ₹${directPurchase.product.price})';
  } else {
    itemsText = cart.items
        .map((item) =>
            '- ${item.product.title} (Qty: ${item.quantity}, Price: ₹${item.product.price})')
        .join('\n');
  }

  String customerInfo = 'Customer Details:\n';
  if (shippingDetails != null) {
    customerInfo += 'Name: ${shippingDetails.fullName}\n';
    customerInfo += 'Phone: ${shippingDetails.primaryPhone}\n';
    customerInfo +=
        'Address: ${shippingDetails.shippingAddress}, ${shippingDetails.city}, ${shippingDetails.state}, ${shippingDetails.country} - ${shippingDetails.zipCode}';
  } else {
    customerInfo += 'Name: Guest User';
  }

  String shiprocketInfo = '';
  // Check if any shiprocket data is present
  if (shiprocketOrderId != null && shiprocketOrderId.toString().isNotEmpty) {
    shiprocketInfo += '\n\n🚀 *Shiprocket Shipping Details:*\n';
    shiprocketInfo += 'Order ID: $shiprocketOrderId\n';
    
    if (shipmentId != null && shipmentId.toString().isNotEmpty) {
      shiprocketInfo += 'Shipment ID: $shipmentId\n';
    }
    
    if (awbCode != null && awbCode.toString().isNotEmpty) {
      shiprocketInfo += 'AWB Number: $awbCode\n';
      
      // Hardcoded tracking link fallback if trackingUrl is missing
      final effectiveTrackingUrl = (trackingUrl != null && trackingUrl.toString().isNotEmpty)
          ? trackingUrl.toString()
          : 'https://shiprocket.co/tracking/$awbCode';
          
      shiprocketInfo += 'Track Your Order: $effectiveTrackingUrl\n';
    }
    
    if (courierName != null && courierName.toString().isNotEmpty) {
      shiprocketInfo += 'Courier Partner: $courierName\n';
    }
  }

  final memberInfo = memberId != null
      ? 'Member ID: $memberId\nSerial No: $serialNo\nType: ${profileType == 'LEADER' ? '👑 LEADER' : '👤 USER'}'
      : 'simple user hai koi member nhi hai';

  final message = '''
Asli Desi Kisan Pvt. Ltd,

Your Order Number *#$orderId* is under process.

📦 *Order Details:*
$itemsText

💰 *Total Amount:* ₹${total.toStringAsFixed(2)}
💳 *Payment ID:* $paymentId
$shiprocketInfo

👤 *$customerInfo*

👤 *$memberInfo*

Please confirm if you wish to receive the same.
''';

  final phone = '918307599904';
  if (phone.length < 10) {
    debugPrint('Invalid phone number for WhatsApp: $phone');
    return;
  }
  final whatsappUrl = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

  if (await canLaunchUrl(whatsappUrl)) {
    await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
  } else {
    debugPrint('Could not launch WhatsApp');
  }
}
