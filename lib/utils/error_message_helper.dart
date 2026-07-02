import 'dart:convert';

String parseApiError(dynamic error) {
  final raw = error.toString();

  final body = _tryExtractJsonBody(raw);
  if (body != null) {
    final msg = _extractMessage(body);
    if (msg != null && msg.isNotEmpty) return msg;
  }

  final friendly = _fallbackMessage(raw);
  if (friendly != null) return friendly;

  final clean = raw
      .replaceFirst(RegExp(r'^Exception:\s*'), '')
      .replaceFirst(RegExp(r'^Error:\s*'), '')
      .trim();
  if (clean.length > 120 || _looksTechnical(clean)) {
    return 'Something went wrong. Please try again.';
  }
  return clean;
}

bool _looksTechnical(String text) {
  final lower = text.toLowerCase();
  return lower.contains('sql') ||
      lower.contains('syntax') ||
      lower.contains('stack') ||
      lower.contains('trace') ||
      lower.contains('foreign key') ||
      lower.contains('constraint') ||
      lower.contains('#0 ') ||
      lower.contains('.dart:') ||
      lower.contains('null check') ||
      lower.contains('no such');
}

String? _fallbackMessage(String raw) {
  final lower = raw.toLowerCase();

  if (lower.contains('timeout') || lower.contains('timed out')) {
    return 'Request timed out. Please check your connection and try again.';
  }
  if (lower.contains('socket') || lower.contains('connection refused')) {
    return 'Could not connect to server. Please check your internet connection.';
  }
  if (lower.contains('401')) {
    return 'Session expired. Please login again.';
  }
  if (lower.contains('403')) {
    return 'You do not have permission to perform this action.';
  }
  if (lower.contains('404')) {
    return 'The requested resource was not found.';
  }
  if (lower.contains('500') || lower.contains('502') || lower.contains('503')) {
    return 'Server error. Please try again later.';
  }

  return null;
}

Map<String, dynamic>? _tryExtractJsonBody(String raw) {
  try {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1 || start >= end) return null;
    final jsonPart = raw.substring(start, end + 1);
    return jsonDecode(jsonPart) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

String? _extractMessage(Map<String, dynamic> body) {
  var message = (body['message'] as String?)?.trim();
  if (message != null && message.isNotEmpty) {
    return _mapKnownError(message);
  }

  final errors = body['errors'];
  if (errors is Map) {
    for (final entry in errors.entries) {
      final field = entry.key.toString();
      final value = entry.value;
      String? firstMsg;
      if (value is List && value.isNotEmpty) {
        firstMsg = value.first.toString();
      } else if (value is String && value.isNotEmpty) {
        firstMsg = value;
      }
      if (firstMsg != null && firstMsg.isNotEmpty) {
        return _mapKnownError(firstMsg, field: field);
      }
    }
  }

  final error = body['error'] as String?;
  if (error != null && error.isNotEmpty) return _mapKnownError(error);

  return null;
}

String _mapKnownError(String rawMessage, {String? field}) {
  final lower = rawMessage.toLowerCase();

  if (lower.contains('email already exists') || lower.contains('email already')) {
    return 'This email is already registered. Please use a different email.';
  }
  if (lower.contains('email') && (lower.contains('taken') || lower.contains('exist'))) {
    return 'This email is already in use. Please try another email.';
  }

  if (lower.contains('sponsor not found') || lower.contains('sponsor_id')) {
    return 'Sponsor ID not found. Please enter a valid Sponsor/Member ID.';
  }
  if (lower.contains('invalid sponsor') || lower.contains('invalid referral')) {
    return 'Invalid Sponsor or Referral ID. Please check and try again.';
  }
  if (lower.contains('referral') || lower.contains('referral_code')) {
    return 'Invalid or expired referral code. Please check with your sponsor.';
  }

  if (lower.contains('password') && (lower.contains('weak') || lower.contains('short'))) {
    return 'Password is too weak. Please use a stronger password (min 6 characters).';
  }
  if (lower.contains('password') && lower.contains('match')) {
    return 'Passwords do not match. Please try again.';
  }

  if (lower.contains('phone') || lower.contains('mobile')) {
    if (lower.contains('already') || lower.contains('exist') || lower.contains('taken') || lower.contains('registered')) {
      return 'This phone number is already registered with another account. Please use a different number.';
    }
    return 'Please enter a valid phone number.';
  }

  if (lower.contains('required') || lower.contains('mandatory')) {
    final f = field ?? 'field';
    return '${f[0].toUpperCase()}${f.substring(1)} is required. Please fill it in.';
  }
  if (lower.contains('invalid') && field != null) {
    return 'Invalid ${field.replaceAll('_', ' ')}. Please check and try again.';
  }

  if (lower.contains('out of stock') || lower.contains('insufficient stock')) {
    return 'Some items are out of stock. Please adjust your order.';
  }
  if (lower.contains('invalid product') || lower.contains('product not found')) {
    return 'Product not found. It may have been removed.';
  }
  if (lower.contains('minimum order') || lower.contains('order minimum')) {
    return 'Your order does not meet the minimum order amount.';
  }

  if (lower.contains('unauthorized') || lower.contains('unauthenticated')) {
    return 'Please login to continue.';
  }
  if (lower.contains('not found')) {
    return 'The requested information was not found.';
  }
  if (lower.contains('duplicate') || lower.contains('already exists')) {
    return 'This record already exists. Please check your information.';
  }

  if (lower.contains('rate limit') || lower.contains('too many requests')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }

  if (lower.contains('order') && (lower.contains('exist') || lower.contains('already') || lower.contains('duplicate'))) {
    return 'This order has already been placed. Please check your order history.';
  }
  if (lower.contains('order') && lower.contains('not found')) {
    return 'Order not found. It may have been removed or cancelled.';
  }
  if (lower.contains('order') && lower.contains('fail')) {
    return 'Order could not be created. Please try again.';
  }
  if (lower.contains('payment') && lower.contains('fail')) {
    return 'Payment failed. Please try again with a different method.';
  }
  if (lower.contains('insufficient balance') || lower.contains('not enough')) {
    return 'Insufficient balance to complete this order.';
  }
  if (lower.contains('shipping') && lower.contains('not available')) {
    return 'Shipping is not available for your location.';
  }

  if (lower.contains('sql') || lower.contains('syntax') || lower.contains('stack') || lower.contains('trace')) {
    return 'Something went wrong on the server. Please try again.';
  }

  return rawMessage;
}
