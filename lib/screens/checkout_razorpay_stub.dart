typedef RazorpayWebSuccess = void Function(String paymentId, String orderId);

typedef RazorpayWebError = void Function(String message);

/// Mobile/desktop — Razorpay web script is unused.
void openRazorpayWebCheckout({
  required String keyId,
  required String orderId,
  required double amount,
  required RazorpayWebSuccess onSuccess,
  required RazorpayWebError onError,
}) {}
