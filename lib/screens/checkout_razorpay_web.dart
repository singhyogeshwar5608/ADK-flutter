import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'dart:html' as html;

typedef RazorpayWebSuccess = void Function(String paymentId, String orderId);

typedef RazorpayWebError = void Function(String message);

void openRazorpayWebCheckout({
  required String keyId,
  required String orderId,
  required double amount,
  required RazorpayWebSuccess onSuccess,
  required RazorpayWebError onError,
}) {
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

  html.window.addEventListener('flutterRazorpaySuccess', (event) {
    try {
      final raw = (event as html.CustomEvent).detail;
      final Map<String, dynamic> data = raw is String
          ? json.decode(raw) as Map<String, dynamic>
          : Map<String, dynamic>.from(raw as Map);
      final paymentId = data['razorpay_payment_id'] ?? '';
      final razorOrderId = data['razorpay_order_id'] ?? '';
      onSuccess(paymentId.toString(), razorOrderId.toString());
    } catch (e) {
      debugPrint('Error parsing payment success: $e');
    }
  });

  html.window.addEventListener('flutterRazorpayError', (event) {
    try {
      final raw = (event as html.CustomEvent).detail;
      final Map<String, dynamic> data = raw is String
          ? json.decode(raw) as Map<String, dynamic>
          : Map<String, dynamic>.from(raw as Map);
      final message = data['description'] ?? 'Payment failed';
      onError(message.toString());
    } catch (e) {
      debugPrint('Error parsing payment error: $e');
      onError('Payment failed');
    }
  });
}
