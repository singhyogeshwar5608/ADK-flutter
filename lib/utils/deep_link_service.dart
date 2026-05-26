import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../screens/product_details_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/wishlist_screen.dart';
import '../state/product_catalog_state.dart';
import '../services/api_client.dart';
import '../models/product.dart';

class DeepLinkService {
  DeepLinkService(this._navigatorKey);

  final GlobalKey<NavigatorState> _navigatorKey;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  Future<void> start() async {
    if (kIsWeb) return;

    // Runtime links stream setup first.
    _sub = _appLinks.uriLinkStream.listen(_handleUri, onError: (e, stack) {
      debugPrint('DeepLinkService uriLinkStream error: $e');
      debugPrintStack(stackTrace: stack);
    });

    // Initial link (cold start) - Wait for Navigator to be ready.
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      debugPrint('DeepLinkService: Initial link found: $initial');
      // Give the app some time to mount the home screen and navigator
      Future.delayed(const Duration(milliseconds: 1500), () {
        debugPrint('DeepLinkService: Processing initial link after delay');
        _handleUri(initial);
      });
    }
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

    // Remove /members prefix if present (Amplify domain structure)
    String effectivePath = path;
    if (path.startsWith('/members/')) {
      effectivePath = path.substring(8); // Remove '/members'
    } else if (path == '/members') {
      effectivePath = '/';
    }

    // Handle wishlist share deep links: 
    // - https://master.d1yeg5lmbstgw1.amplifyapp.com/members/wishlist/TOKEN
    // - https://master.d1yeg5lmbstgw1.amplifyapp.com/members/w/TOKEN
    // - https://www.offerlifetime.com/wishlist/TOKEN
    // - https://www.offerlifetime.com/w/TOKEN
    final isWishlistLong = effectivePath.startsWith('/wishlist/');
    final isWishlistShort = effectivePath.startsWith('/w/');

    if (isWishlistLong || isWishlistShort) {
      debugPrint('Wishlist HTTPS flow detected (Path: $path, Effective: $effectivePath)');

      final nav = _navigatorKey.currentState;
      if (nav == null) {
        debugPrint('Navigation Status: FAILED (Navigator is null)');
        return;
      }

      // Extract token from effective path
      String token = '';
      if (isWishlistLong) {
        token = effectivePath.substring(10); // Remove '/wishlist/' prefix
      } else {
        token = effectivePath.substring(3); // Remove '/w/' prefix
      }
      
      token = token.trim();
      debugPrint('Extracted Token: $token');

      if (token.isEmpty) {
        debugPrint('Navigation Status: SKIPPED (Token is empty)');
        return;
      }

      // Navigate to wishlist screen with token
      debugPrint('Navigation Status: SUCCESS (Navigating to WishlistScreen)');
      nav.pushNamedAndRemoveUntil(
        WishlistScreen.routeName,
        (route) => route.isFirst,
        arguments: {'token': token},
      );
      return;
    }

    // Handle product detail deep links:
    // - https://master.d1yeg5lmbstgw1.amplifyapp.com/members/product/ID
    // - https://www.offerlifetime.com/product/ID
    final isProductLink = effectivePath.contains('/product/');
    if (isProductLink) {
      debugPrint('Product HTTPS flow detected (Effective: $effectivePath)');
      final productId = effectivePath.split('/').last.trim();
      if (productId.isEmpty) return;

      debugPrint('Navigation Status: SUCCESS (Navigating to Product Loader for ID: $productId)');
      final nav = _navigatorKey.currentState;
      if (nav == null) return;

      nav.pushNamedAndRemoveUntil(
        '/', // Go to home first
        (route) => false,
      );
      
      // Use the named route that onGenerateRoute handles
      nav.pushNamed('/product/$productId');
      return;
    }

    // Handle signup deep links:
    _handleSignupDeepLink(uri, effectivePath);
  }

  void _handleSignupDeepLink(Uri uri, String effectivePath) {
    // - https://master.d1yeg5lmbstgw1.amplifyapp.com/members/signup?ref=CODE&leg=LEFT
    // - https://www.offerlifetime.com/signup?ref=CODE&leg=LEFT
    if (!effectivePath.endsWith('/signup') && effectivePath != '/signup') {
      debugPrint('Not a signup path, ignoring (Effective: $effectivePath)');
      return;
    }

    debugPrint('Signup HTTPS flow detected (Effective: $effectivePath)');

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

