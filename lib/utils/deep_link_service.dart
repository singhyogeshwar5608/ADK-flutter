import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../screens/signup_screen.dart';
import '../screens/wishlist_screen.dart';

class DeepLinkService {
  DeepLinkService(this._navigatorKey);

  final GlobalKey<NavigatorState> _navigatorKey;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  Future<void> start() async {
    if (kIsWeb) return;

    // Initial link (cold start).
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      _handleUri(initial);
    }

    // Runtime links.
    _sub = _appLinks.uriLinkStream.listen(_handleUri, onError: (e, stack) {
      debugPrint('DeepLinkService uriLinkStream error: $e');
      debugPrintStack(stackTrace: stack);
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  void _handleUri(Uri uri) {
    // Debug logging
    debugPrint('=== Deep Link Received ===');
    debugPrint('URI: $uri');
    debugPrint('Scheme: ${uri.scheme}');
    debugPrint('Host: ${uri.host}');
    debugPrint('Path: ${uri.path}');
    debugPrint('Query Parameters: ${uri.queryParameters}');

    final path = uri.path.toLowerCase();

    // Handle custom scheme deep links: adkpartner://
    if (uri.scheme == 'adkpartner') {
      debugPrint('Handling adkpartner:// custom scheme');

      // Handle signup flow: adkpartner://signup?ref=CODE&leg=LEFT
      if (uri.host == 'signup') {
        debugPrint('Signup flow detected');

        final ref = (uri.queryParameters['ref'] ??
                uri.queryParameters['referral_code'] ??
                '')
            .trim();
        debugPrint('Referral code: $ref');

        if (ref.isEmpty) {
          debugPrint('No referral code provided, skipping signup flow');
          return;
        }

        final leg = (uri.queryParameters['leg'] ?? '').trim().toUpperCase();
        debugPrint('Leg: $leg');

        final args = SignupRouteArgs(
          referralCode: ref,
          leg: (leg == 'LEFT' || leg == 'RIGHT') ? leg : null,
        );

        final nav = _navigatorKey.currentState;
        if (nav == null) {
          debugPrint('Navigator is null, cannot navigate');
          return;
        }

        debugPrint('Navigating to signup screen');
        nav.pushNamedAndRemoveUntil(
          SignupScreen.routeName,
          (route) => route.isFirst,
          arguments: args,
        );
        return;
      }

      // Handle wishlist flow: adkpartner://open?type=wishlist&token=ABC123
      if (uri.host == 'open') {
        debugPrint('Open flow detected');

        final type = uri.queryParameters['type']?.trim().toLowerCase();
        debugPrint('Type: $type');

        if (type == 'wishlist') {
          final token = uri.queryParameters['token']?.trim() ?? '';
          debugPrint('Wishlist token: $token');

          if (token.isEmpty) {
            debugPrint('No token provided, skipping wishlist flow');
            return;
          }

          final nav = _navigatorKey.currentState;
          if (nav == null) {
            debugPrint('Navigator is null, cannot navigate');
            return;
          }

          debugPrint('Navigating to wishlist screen with token');
          nav.pushNamedAndRemoveUntil(
            WishlistScreen.routeName,
            (route) => route.isFirst,
            arguments: {'token': token},
          );
          return;
        }

        debugPrint('Unknown type: $type, ignoring');
        return;
      }

      debugPrint('Unknown host: ${uri.host}, ignoring');
      return;
    }

    // Handle HTTPS deep links (fallback for direct web links)
    debugPrint('Handling HTTPS deep link');

    // Handle wishlist share deep links: https://aslidesikisan.netlify.app/w/TOKEN
    if (path.startsWith('/w/')) {
      debugPrint('Wishlist HTTPS flow detected');

      final nav = _navigatorKey.currentState;
      if (nav == null) {
        debugPrint('Navigator is null, cannot navigate');
        return;
      }

      // Extract token from path /w/TOKEN
      final token = path.substring(3); // Remove '/w/' prefix
      debugPrint('Extracted token: $token');

      // Navigate to wishlist screen with token
      nav.pushNamedAndRemoveUntil(
        WishlistScreen.routeName,
        (route) => route.isFirst,
        arguments: {'token': token},
      );
      return;
    }

    // Handle signup deep links:
    // - https://aslidesikisan.netlify.app/signup?ref=CODE&leg=LEFT
    // - https://www.offerlifetime.com/signup?ref=CODE&leg=LEFT
    if (!path.endsWith('/signup') && path != '/signup') {
      debugPrint('Not a signup path, ignoring');
      return;
    }

    debugPrint('Signup HTTPS flow detected');

    final ref = (uri.queryParameters['ref'] ??
            uri.queryParameters['referral_code'] ??
            '')
        .trim();
    debugPrint('Referral code: $ref');

    if (ref.isEmpty) {
      debugPrint('No referral code provided, skipping signup flow');
      return;
    }

    final leg = (uri.queryParameters['leg'] ?? '').trim().toUpperCase();
    debugPrint('Leg: $leg');

    final args = SignupRouteArgs(
      referralCode: ref,
      leg: (leg == 'LEFT' || leg == 'RIGHT') ? leg : null,
    );

    final nav = _navigatorKey.currentState;
    if (nav == null) {
      debugPrint('Navigator is null, cannot navigate');
      return;
    }

    debugPrint('Navigating to signup screen');
    nav.pushNamedAndRemoveUntil(
      SignupScreen.routeName,
      (route) => route.isFirst,
      arguments: args,
    );
  }
}

