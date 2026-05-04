import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:razorpay_flutter/razorpay_flutter.dart';

// Conditional import - dart:html only available on web
import 'dart:html' as html if (dart.library.io) '';

import '../navigation/checkout_arguments.dart';
import '../state/cart_state.dart';
import '../state/profile_state.dart';
import '../config/api_config.dart';
import '../utils/auth_helper.dart';
import '../services/api_client.dart';
import 'customer_details_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _useWallet = true;
  bool _isProcessing = false;
  bool _isLoadingProfile = true;
  Razorpay? _razorpay;

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
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    try {
      final profileProvider = ProfileProvider.of(context, listen: false);
      await profileProvider.refresh();
      debugPrint('Checkout: Profile refreshed successfully');
    } catch (e) {
      debugPrint('Checkout: Failed to refresh profile: $e');
    } finally {
      // Use WidgetsBinding to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoadingProfile = false;
          });
        }
      });
    }
  }

  void _handlePaymentSuccess(String paymentId, String orderId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
    // Silence UI popups per requirement; log for debugging instead.
    debugPrint('Payment Successful! ID: $paymentId Order: $orderId');
    // TODO: Verify payment on backend and create order
  }

  void _handlePaymentError(String error) {
    setState(() => _isProcessing = false);
    debugPrint('Payment Failed: $error');
  }

  Future<void> _initiatePayment(double amount) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Create order on backend
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payment/create-order'),
        headers: {
          'Content-Type': 'application/json',
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
        _openRazorpayWeb(data['key_id'], data['order_id'], amount);
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

  void _openRazorpayWeb(String keyId, String orderId, double amount) {
    // This method is only called on web platform (kIsWeb check in caller)
    // For Android/iOS, razorpay_flutter SDK is used instead
    
    if (!kIsWeb) return; // Safety check
    
    // Use dart:html for web-specific code
    final script = html.document.createElement('script') as html.ScriptElement;
    script.type = 'text/javascript';
    script.text = '''
      window.razorpaySuccess = function(response) {
        console.log('Razorpay Success:', response);
        if (window.flutterRazorpaySuccess) {
          window.flutterRazorpaySuccess(JSON.stringify(response));
        }
      };
      
      window.razorpayError = function(error) {
        console.log('Razorpay Error:', error);
        if (window.flutterRazorpayError) {
          window.flutterRazorpayError(JSON.stringify(error));
        }
      };
      
      if (!window.Razorpay) {
        var razorpayScript = document.createElement('script');
        razorpayScript.src = 'https://checkout.razorpay.com/v1/checkout.js';
        razorpayScript.async = true;
        razorpayScript.onload = function() {
          openRazorpayCheckout();
        };
        document.head.appendChild(razorpayScript);
      } else {
        openRazorpayCheckout();
      }
      
      function openRazorpayCheckout() {
        var options = {
          key: "$keyId",
          amount: ${(amount * 100).toInt()},
          currency: "INR",
          name: "ADK Pvt. Ltd.",
          description: "Order Payment",
          order_id: "$orderId",
          handler: window.razorpaySuccess,
          modal: {
            ondismiss: function() {
              window.razorpayError({code: 'PAYMENT_CANCELLED', description: 'Payment cancelled by user'});
            }
          },
          prefill: {
            contact: "9999999999",
            email: "customer@example.com"
          },
          theme: {
            color: "#3399cc"
          }
        };
        var rzp = new Razorpay(options);
        rzp.open();
      }
    ''';
    
    html.document.head?.append(script);
    
    // Setup Flutter callbacks using dart:html
    html.window.addEventListener('flutterRazorpaySuccess', (event) {
      try {
        final data = json.decode((event as html.CustomEvent).detail);
        final paymentId = data['razorpay_payment_id'] ?? '';
        final orderId = data['razorpay_order_id'] ?? '';
        _handlePaymentSuccess(paymentId, orderId);
      } catch (e) {
        debugPrint('Error parsing payment success: $e');
      }
    });
    
    html.window.addEventListener('flutterRazorpayError', (event) {
      try {
        final data = json.decode((event as html.CustomEvent).detail);
        final message = data['description'] ?? 'Payment failed';
        _handlePaymentError(message);
      } catch (e) {
        debugPrint('Error parsing payment error: $e');
        _handlePaymentError('Payment failed');
      }
    });
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
    final background =
        isDark ? const Color(0xFF101A22) : const Color(0xFFF6F7F8);
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
            'Checkout: Cart has items but no shipping details - redirecting to customer details');
        // Redirect to customer details with cart items
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/customer-details');
          }
        });
      }
    }

    final subtotal = directPurchase != null
        ? directPurchase.product.price * directPurchase.quantity
        : cart.subtotal;
    final shipping = directPurchase != null
        ? directPurchase.product.shippingCharge * directPurchase.quantity
        : cart.items.fold(0.0, (sum, item) => sum + item.totalShipping);
    final tax = directPurchase != null ? subtotal * cart.taxRate : cart.tax;
    final total = subtotal + shipping + tax;

    debugPrint('Checkout: directPurchase is null? ${directPurchase == null}');
    debugPrint('Checkout: cart.subtotal = ${cart.subtotal}');
    debugPrint('Checkout: cart.totalItems = ${cart.totalItems}');
    debugPrint('Checkout: calculated subtotal = $subtotal');
    debugPrint('Checkout: calculated total = $total');

    if (directPurchase != null) {
      debugPrint(
          'Checkout: Direct purchase - product: ${directPurchase.product.title}, price: ${directPurchase.product.price}, quantity: ${directPurchase.quantity}');
    }

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              color: isDark ? const Color(0xFF0F172A) : background,
              child: Column(
                children: [
                  _CheckoutHeader(
                      onBack: () => Navigator.of(context).maybePop()),
                  Expanded(
                    child: _CheckoutBody(
                      cart: cart,
                      directPurchase: directPurchase,
                      shippingDetails: shippingDetails,
                      useWallet: _useWallet,
                      onToggleWallet: (value) =>
                          setState(() => _useWallet = value),
                      onRefresh: _refreshProfile,
                      isLoading: _isLoadingProfile,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MockOrderButton(
                    total: total,
                    directPurchase: directPurchase,
                    cart: cart,
                    shippingDetails: shippingDetails,
                  ),
                  _CheckoutFooter(
                    total: total,
                    isProcessing: _isProcessing,
                    onPayNow: () => _initiatePayment(total),
                  ),
                ],
              ),
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
    final divider = theme.brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: (theme.brightness == Brightness.dark
                ? const Color(0xFF0F172A)
                : Colors.white)
            .withValues(alpha: 0.85),
        border: Border(bottom: BorderSide(color: divider)),
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
          _CircleIconButton(icon: Icons.arrow_back, onTap: onBack),
          Expanded(
            child: Text(
              'Checkout',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _CheckoutBody extends StatelessWidget {
  const _CheckoutBody({
    required this.cart,
    this.directPurchase,
    this.shippingDetails,
    required this.useWallet,
    required this.onToggleWallet,
    required this.onRefresh,
    required this.isLoading,
  });

  final CartState cart;
  final CheckoutArguments? directPurchase;
  final ShippingDetailsPayload? shippingDetails;
  final bool useWallet;
  final ValueChanged<bool> onToggleWallet;
  final VoidCallback onRefresh;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShippingSection(theme: theme, shippingDetails: shippingDetails),
          const SizedBox(height: 16),
          _OrderSummaryCard(cart: cart, directPurchase: directPurchase),
          const SizedBox(height: 16),
          _WalletCard(
            useWallet: useWallet,
            onToggleWallet: onToggleWallet,
            onRefresh: onRefresh,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

class _ShippingSection extends StatelessWidget {
  const _ShippingSection({required this.theme, this.shippingDetails});

  final ThemeData theme;
  final ShippingDetailsPayload? shippingDetails;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final cardColor = theme.brightness == Brightness.dark
        ? const Color(0xFF0F172A)
        : Colors.white;
    final border = theme.brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);

    final hasDetails = shippingDetails != null;
    final addressLines = hasDetails
        ? [
            shippingDetails!.shippingAddress,
            '${shippingDetails!.city}, ${shippingDetails!.state} ${shippingDetails!.zipCode}',
            'Phone: ${shippingDetails!.primaryPhone}',
            if (shippingDetails!.secondaryPhone != null)
              'Alt: ${shippingDetails!.secondaryPhone}',
          ]
        : ['123 Innovation Drive, Tech City, Suite 400, CA 94103'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Shipping Address',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  CustomerDetailsScreen.routeName,
                  arguments: shippingDetails,
                );
              },
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
              child: Text(
                'Edit',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.15 : 0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on, color: colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasDetails ? shippingDetails!.fullName : 'Home',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      addressLines.join('\n'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.cart, this.directPurchase});

  final CartState cart;
  final CheckoutArguments? directPurchase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.brightness == Brightness.dark
        ? const Color(0xFF0F172A)
        : Colors.white;
    final border = theme.brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);
    final isDirect = directPurchase != null;
    final quantity = isDirect ? directPurchase!.quantity : cart.items.length;
    final itemLabel = '$quantity ${quantity == 1 ? 'Item' : 'Items'}';
    final subtotal = isDirect
        ? directPurchase!.product.price * directPurchase!.quantity
        : cart.subtotal;
    final shipping = isDirect
        ? directPurchase!.product.shippingCharge * directPurchase!.quantity
        : cart.items.fold(0.0, (sum, item) => sum + item.totalShipping);
    final totalBv = isDirect
        ? directPurchase!.product.bv * directPurchase!.quantity
        : cart.totalBv;
    final tax = isDirect ? subtotal * cart.taxRate : cart.tax;
    final total = subtotal + shipping + tax;

    Widget row(String label, String value,
        {Color? valueColor, FontWeight? weight}) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor ?? theme.colorScheme.onSurface,
              fontWeight: weight ?? FontWeight.w600,
            ),
          ),
        ],
      );
    }

    String format(double value) => '₹${value.toStringAsFixed(2)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.15 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order Summary',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  itemLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Product details section
          if (isDirect) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    directPurchase!.product.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quantity: ${directPurchase!.quantity}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Price: ${format(directPurchase!.product.price)} each',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          row('Total Business Volume (BV)', '$totalBv BV',
              valueColor: theme.colorScheme.primary),
          const SizedBox(height: 12),
          row('Subtotal', format(subtotal)),
          const SizedBox(height: 12),
          row('Shipping', shipping > 0 ? format(shipping) : 'Free',
              valueColor: shipping > 0 ? null : const Color(0xFF10B981)),
          const SizedBox(height: 12),
          row('Tax', format(tax)),
          const SizedBox(height: 12),
          Divider(color: border),
          const SizedBox(height: 12),
          row('Total Price', format(total),
              valueColor: theme.colorScheme.primary, weight: FontWeight.w700),
        ],
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard(
      {required this.useWallet,
      required this.onToggleWallet,
      this.isLoading = false,
      required this.onRefresh});

  final bool useWallet;
  final ValueChanged<bool> onToggleWallet;
  final bool isLoading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final profile = ProfileProvider.of(context).data;
    final walletBalance = profile.walletBalance ?? 0.0;
    final theme = Theme.of(context);

    debugPrint(
        'Checkout Wallet: Profile wallet balance = ₹${walletBalance.toStringAsFixed(2)}');
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Wallet Balance',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            isLoading
                                ? Container(
                                    width: 80,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      ),
                                    ),
                                  )
                                : Text(
                                    '₹${walletBalance.toStringAsFixed(2)}',
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                            if (!isLoading) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: onRefresh,
                                child: Icon(
                                  Icons.refresh,
                                  size: 20,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Use wallet for this payment',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: useWallet,
                    onChanged: onToggleWallet,
                    thumbColor: WidgetStateProperty.all(primary),
                    trackColor: WidgetStateProperty.all(
                        Colors.white.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            right: -40,
            bottom: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
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
    final divider = theme.brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF0F172A)
            : Colors.white,
        border: Border(top: BorderSide(color: divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                    shadowColor:
                        theme.colorScheme.primary.withValues(alpha: 0.35),
                  ),
                  onPressed: isProcessing ? null : onPayNow,
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Pay',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 16),
              const SizedBox(width: 6),
              Text(
                'Secure encrypted checkout'.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon),
      ),
    );
  }
}

class _MockOrderButton extends StatelessWidget {
  const _MockOrderButton({
    required this.total,
    this.directPurchase,
    required this.cart,
    this.shippingDetails,
  });

  final double total;
  final CheckoutArguments? directPurchase;
  final CartState cart;
  final ShippingDetailsPayload? shippingDetails;

  Future<void> _createMockOrder(BuildContext context) async {
    try {
      debugPrint('Mock Order: Creating test order...');

      // Prepare order data
      final Map<String, dynamic> orderData = {
        'total_amount': total,
        'items': directPurchase != null
            ? [
                {
                  'product_id': directPurchase!.product.id,
                  'product_name': directPurchase!.product.title,
                  'quantity': directPurchase!.quantity,
                  'price': directPurchase!.product.price,
                  'bv': directPurchase!.product.bv,
                  'total_bv':
                      directPurchase!.product.bv * directPurchase!.quantity,
                }
              ]
            : cart.items
                .map((item) => {
                      'product_id': item.product.id,
                      'product_name': item.product.title,
                      'quantity': item.quantity,
                      'price': item.product.price,
                      'bv': item.product.bv,
                      'total_bv': item.product.bv * item.quantity,
                    })
                .toList(),
        'shipping_details': shippingDetails != null
            ? {
                'full_name': shippingDetails!.fullName,
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

      // Call the real mock order API using the same authentication as ApiClient
      // We need to ensure we're authenticated first
      final apiClient = ApiClient.instance;
      await apiClient.ensureAuthenticated();

      // Get the token from ApiClient's internal storage
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/orders/mock'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(orderData),
      );

      debugPrint('Mock Order: API response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        debugPrint(
            'Mock Order: Order created successfully - ID: ${responseData['order']['id']}');
        debugPrint('Mock Order: BV awarded: ${responseData['bv_awarded']}');

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
                    const Text('✅ Order saved to database!'),
                    const SizedBox(height: 8),
                    const Text('✅ Income calculations updated!'),
                    const SizedBox(height: 8),
                    const Text('✅ BV points distributed!'),
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
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Mock Order: Error creating order - $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating mock order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: () => _createMockOrder(context),
        icon: const Icon(Icons.shopping_bag_outlined),
        label: const Text('Create Mock Order (Testing)'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
