import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

import 'screens/address_form_screen.dart';
import 'screens/addresses_screen.dart';
import 'screens/add_funds_screen.dart';
import 'screens/binary_tree_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/customer_details_screen.dart';
import 'screens/home_screen.dart';
import 'screens/all_products_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/profile_edit_screen.dart';
import 'screens/my_team_screen.dart';
import 'screens/member_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/withdraw_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/my_referral_screen.dart';
import 'screens/register_member_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/media_listing_screen.dart';
import 'screens/adk_events_screen.dart';
import 'screens/product_catalogue_screen.dart';
import 'screens/product_details_screen.dart';
import 'screens/delivery_center_screen.dart';
import 'screens/contact_us_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/terms_conditions_screen.dart';
import 'models/product.dart';
import 'state/product_catalog_state.dart';
import 'state/theme_controller.dart';
import 'state/cart_state.dart';
import 'state/profile_state.dart';
import 'state/wishlist_state.dart';
import 'state/location_state.dart';
import 'theme/app_theme.dart';
import 'utils/deep_link_service.dart';
import 'services/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  await dotenv.load(
    fileName: 'assets/dotenv',
    isOptional: true,
  );
  runApp(const ADKApp());
}

class ADKApp extends StatefulWidget {
  const ADKApp({super.key});

  @override
  State<ADKApp> createState() => _ADKAppState();
}

class _ADKAppState extends State<ADKApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final DeepLinkService _deepLinks = DeepLinkService(_navigatorKey);

  late final ProfileState _profileState;
  late final CartState _cartState;
  late final WishlistState _wishlistState;
  late final ThemeController _themeController;
  late final ProductCatalogState _productCatalogState;

  @override
  void initState() {
    super.initState();
    _profileState = ProfileState();
    _cartState = CartState(profile: _profileState);
    _wishlistState = WishlistState(profile: _profileState);
    _themeController = ThemeController();
    _productCatalogState = ProductCatalogState();
    // Best-effort; doesn't block app startup.
    unawaited(_deepLinks.start());
  }

  @override
  void dispose() {
    _deepLinks.dispose();
    _cartState.dispose();
    _profileState.dispose();
    _wishlistState.dispose();
    _themeController.dispose();
    _productCatalogState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CartProvider(
      notifier: _cartState,
      child: ProfileProvider(
        notifier: _profileState,
        child: WishlistProvider(
          notifier: _wishlistState,
          child: ProductCatalogProvider(
            notifier: _productCatalogState,
            child: ThemeControllerProvider(
                notifier: _themeController,
                child: AnimatedBuilder(
                  animation: _themeController,
                  builder: (context, _) => MaterialApp(
                    title: 'ADK Partner Portal',
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: _themeController.mode,
                    navigatorKey: _navigatorKey,
                    home: const HomeScreen(),
                    onGenerateRoute: (settings) {
                      final name = settings.name ?? '';
                      
                      // Handle /product/ID or /members/product/ID deep links (especially for Web)
                      if (name.contains('/product/')) {
                        final productId = name.split('/').last.trim();
                        if (productId.isNotEmpty) {
                          return MaterialPageRoute(
                            builder: (context) => _ProductDeepLinkLoader(productId: productId),
                          );
                        }
                      }

                      // Handle /wishlist/TOKEN or /members/wishlist/TOKEN deep links (especially for Web)
                      final isWishlist = name.contains('/wishlist/') || name.contains('/w/');
                      if (isWishlist) {
                        final token = name.split('/').last.trim();
                        if (token.isNotEmpty) {
                          return MaterialPageRoute(
                            builder: (context) => const WishlistScreen(),
                            settings: RouteSettings(
                              name: WishlistScreen.routeName,
                              arguments: {'token': token},
                            ),
                          );
                        }
                      }

                      if (settings.name == BinaryTreeScreen.routeName) {
                        return MaterialPageRoute(
                          builder: (context) => BinaryTreeScreen(
                            memberId: (settings.arguments as String? ?? '').trim().isNotEmpty
                                ? settings.arguments as String
                                : null,
                          ),
                        );
                      }
                      return null;
                    },
                    routes: {
                      ProductDetailsScreen.routeName: (context) {
                        final product = ModalRoute.of(context)?.settings.arguments as Product;
                        return ProductDetailsScreen(product: product);
                      },
                      CartScreen.routeName: (_) => const CartScreen(),
                      '/checkout': (_) => const CheckoutScreen(),
                      WalletScreen.routeName: (_) => const WalletScreen(),
                      AddFundsScreen.routeName: (_) => const AddFundsScreen(),
                      WithdrawScreen.routeName: (_) => const WithdrawScreen(),
                      ProfileScreen.routeName: (_) => const ProfileScreen(),
                      ProfileEditScreen.routeName: (_) =>
                          const ProfileEditScreen(),
                      TransactionsScreen.routeName: (_) =>
                          const TransactionsScreen(),
                      WishlistScreen.routeName: (_) => const WishlistScreen(),
                      AllProductsScreen.routeName: (_) =>
                          const AllProductsScreen(),
                      CustomerDetailsScreen.routeName: (_) =>
                          const CustomerDetailsScreen(),
                      AddressesScreen.routeName: (_) => const AddressesScreen(),
                      AddressFormScreen.routeName: (_) => const AddressFormScreen(),
                      NotificationsScreen.routeName: (_) =>
                          const NotificationsScreen(),
                      MyTeamScreen.routeName: (_) => const MyTeamScreen(),
                      RegisterMemberScreen.routeName: (_) =>
                          const RegisterMemberScreen(),
                      MyReferralScreen.routeName: (_) =>
                          const MyReferralScreen(),
                      MemberDetailScreen.routeName: (_) =>
                          const MemberDetailScreen(),
                      SettingsScreen.routeName: (_) => const SettingsScreen(),
                      MenuScreen.routeName: (_) => const MenuScreen(),
                      MediaListingScreen.routeName: (_) =>
                          const MediaListingScreen(),
                      AdkEventsScreen.routeName: (_) => const AdkEventsScreen(),
                      ProductCatalogueScreen.routeName: (_) =>
                          const ProductCatalogueScreen(),
                      DeliveryCenterScreen.routeName: (_) =>
                          const DeliveryCenterScreen(),
                      ContactUsScreen.routeName: (_) => const ContactUsScreen(),
                      PrivacyPolicyScreen.routeName: (_) =>
                          const PrivacyPolicyScreen(),
                      TermsConditionsScreen.routeName: (_) =>
                          const TermsConditionsScreen(),
                      LoginScreen.routeName: (_) => const LoginScreen(),
                      SignupScreen.routeName: (_) => const SignupScreen(),
                    },
                  ),
                ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper widget to load a product from a deep link ID and navigate to details.
class _ProductDeepLinkLoader extends StatefulWidget {
  const _ProductDeepLinkLoader({required this.productId});
  final String productId;

  @override
  State<_ProductDeepLinkLoader> createState() => _ProductDeepLinkLoaderState();
}

class _ProductDeepLinkLoaderState extends State<_ProductDeepLinkLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndNavigate();
    });
  }

  Future<void> _loadAndNavigate() async {
    // delay to ensure catalog is initializing
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (!mounted) return;
    
    final catalog = ProductCatalogProvider.of(context, listen: false);
    Product? product;

    // 1. Try catalog
    final entry = catalog.entries.where((e) => e.product.id.toString() == widget.productId).firstOrNull;
    if (entry != null) {
      product = entry.product;
    } else {
      // 2. Try API
      try {
        final results = await ApiClient.instance.fetchPublicProducts(ids: [widget.productId]);
        if (results.isNotEmpty) {
          product = results.first.product;
        }
      } catch (e) {
        debugPrint('Deep link load failed: $e');
      }
    }

    if (!mounted) return;

    if (product != null) {
      Navigator.of(context).pushReplacementNamed(
        ProductDetailsScreen.routeName,
        arguments: product,
      );
    } else {
      // Fallback to home if not found
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
