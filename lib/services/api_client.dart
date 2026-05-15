import 'dart:convert';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_entry.dart';
import '../models/event_media_item.dart';
import '../models/adk_event.dart';
import '../models/catalogue_page.dart';
import '../models/category.dart';
import '../models/member_summary.dart';
import '../models/member_tree.dart';
import '../models/product.dart';
import '../config/api_config.dart';
import '../models/delivery_center.dart';
import '../models/hero_slide.dart';
import '../models/social_link.dart';

class CataloguePageResponse {
  const CataloguePageResponse({required this.data, required this.meta});

  final List<CataloguePage> data;
  final CatalogueMeta meta;

  factory CataloguePageResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['data'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CataloguePage.fromJson)
        .toList(growable: false);
    return CataloguePageResponse(
      data: items,
      meta: CatalogueMeta.fromJson(
          json['meta'] as Map<String, dynamic>? ?? const {}),
    );
  }
}

class CatalogueMeta {
  const CatalogueMeta(
      {required this.page,
      required this.limit,
      required this.total,
      required this.pages});

  final int page;
  final int limit;
  final int total;
  final int pages;

  factory CatalogueMeta.fromJson(Map<String, dynamic> json) {
    return CatalogueMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      pages: (json['pages'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Left/right signup URLs from [fetchReferralLinks] (`GET /referral/link`).
class ReferralLinks {
  const ReferralLinks({required this.left, required this.right});

  final String left;
  final String right;
}

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();
  static const _accessTokenStorageKey = 'access_token';
  static const _accessTokenSavedAtStorageKey = 'access_token_saved_at_ms';
  static const _accessTokenTtl = Duration(days: 7);

  final http.Client _httpClient = http.Client();
  String? _accessToken;

  String get _baseUrl {
    // Use environment variable for API URL
    final url =
        dotenv.env['API_BASE_URL'] ?? 'https://www.offerlifetime.com/api/v1';
    print('Using API URL: $url');
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  String get baseServerUrl {
    final apiUrl = _baseUrl;
    final match = RegExp(r'^(.*?)/api/v1$').firstMatch(apiUrl);
    return match?.group(1) ?? apiUrl;
  }

  String? get accessToken => _accessToken;

  String get _loginEmail => dotenv.env['API_MEMBER_EMAIL'] ?? 'admin@mlm.com';
  String get _loginPassword => dotenv.env['API_MEMBER_PASSWORD'] ?? 'Admin@123';

  Future<void> ensureAuthenticated() async {
    if (_accessToken != null) return;
    await _loadTokenFromStorage();
    if (_accessToken != null) return;
    await _login();
  }

  /// Restores [accessToken] from disk into memory. Never calls the API / [_login].
  Future<void> restoreSessionFromStorage() async {
    if (_accessToken != null) return;
    await _loadTokenFromStorage();
  }

  /// Member token for requests that must use a **real** login (e.g. mock order).
  /// Does not use the service-account [_login] fallback.
  Future<String?> resolveStoredMemberToken() async {
    await restoreSessionFromStorage();
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      return _accessToken;
    }
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      _accessTokenStorageKey,
      'auth_token',
      'netshop_access_token',
      'token',
    ]) {
      final v = prefs.getString(key);
      if (v != null && v.isNotEmpty) {
        return v;
      }
    }
    return null;
  }

  Future<void> _loadTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenStorageKey);
      final savedAtMs = prefs.getInt(_accessTokenSavedAtStorageKey);

      if (token == null || token.isEmpty) {
        _accessToken = null;
        return;
      }

      // Legacy installs: token without TTL key — keep session and start TTL now.
      if (savedAtMs == null) {
        await prefs.setInt(
          _accessTokenSavedAtStorageKey,
          DateTime.now().millisecondsSinceEpoch,
        );
        _accessToken = token;
        print('Token loaded (legacy TTL): ${token.substring(0, 10)}...');
        return;
      }

      final savedAt = DateTime.fromMillisecondsSinceEpoch(savedAtMs);
      final age = DateTime.now().difference(savedAt);
      if (age >= _accessTokenTtl) {
        print('Stored token expired (${age.inHours}h old); clearing session');
        await _clearTokenFromStorage();
        return;
      }
      _accessToken = token;
      print('Token loaded from storage: ${token.substring(0, 10)}...');
    } catch (e) {
      print('Failed to load token from storage: $e');
    }
  }

  Future<void> _saveTokenToStorage(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenStorageKey, token);
      await prefs.setInt(
        _accessTokenSavedAtStorageKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      print('Token saved to storage: ${token.substring(0, 10)}...');
    } catch (e) {
      print('Failed to save token to storage: $e');
    }
  }

  Future<void> _clearTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenStorageKey);
      await prefs.remove(_accessTokenSavedAtStorageKey);
      _accessToken = null;
      print('Token removed from storage');
    } catch (e) {
      print('Failed to clear token from storage: $e');
    }
  }

  Future<List<ProductCatalogEntry>> fetchProductEntries(
      {int limit = 200, int page = 1}) async {
    await ensureAuthenticated();
    final uri = _buildUri('products', {'limit': '$limit', 'page': '$page'});
    final response = await _httpClient.get(uri, headers: _authorizedHeaders());
    return _parseProductList(response, context: 'Fetch products');
  }

  Future<List<ProductCatalogEntry>> fetchPublicProducts(
      {int limit = 100, int page = 1}) async {
    final uri =
        _buildUri('products/public', {'limit': '$limit', 'page': '$page'});
    final response = await _httpClient
        .get(uri, headers: ApiConfig.jsonHeaders);
    return _parseProductList(response, context: 'Fetch public products');
  }

  Future<Map<String, dynamic>?> fetchPincode(String pincode) async {
    final normalized = pincode.trim();
    final uri = _buildUri('pincode/$normalized');
    final response = await _httpClient.get(uri, headers: ApiConfig.jsonHeaders);
    _throwIfNeeded(response, context: 'Fetch pincode');
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<List<Product>> fetchWishlistProducts() async {
    await ensureAuthenticated();
    final uri = _buildUri('wishlist');
    final response = await _httpClient.get(uri, headers: _authorizedHeaders());
    _throwIfNeeded(response, context: 'Fetch wishlist');
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final productJson = item['product'];
          if (productJson is Map<String, dynamic>) {
            return Product.fromJson(productJson);
          }
          return null;
        })
        .whereType<Product>()
        .toList(growable: false);
  }

  Future<void> addToWishlist(String productId) async {
    await ensureAuthenticated();
    final normalizedId = _normalizeProductId(productId);
    final uri = _buildUri('wishlist');
    final response = await _httpClient.post(
      uri,
      headers: _authorizedHeaders(),
      body: jsonEncode({'productId': normalizedId}),
    );
    _throwIfNeeded(response, context: 'Add to wishlist');
  }

  Future<void> removeFromWishlist(String productId) async {
    await ensureAuthenticated();
    final normalizedId = _normalizeProductId(productId);
    final uri = _buildUri('wishlist/$normalizedId');
    final response =
        await _httpClient.delete(uri, headers: _authorizedHeaders());
    _throwIfNeeded(response, context: 'Remove from wishlist');
  }

  Future<EventMediaResponse> fetchEventMedia({
    int page = 1,
    int limit = 50,
    String? search,
    String? mediaType,
    String? status,
    String? sort,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (mediaType != null && mediaType.isNotEmpty) 'mediaType': mediaType,
      if (status != null && status.isNotEmpty) 'status': status,
      if (sort != null && sort.isNotEmpty) 'sort': sort,
    };
    final uri = _buildUri('event-media', query);
    final response = await _httpClient
        .get(uri, headers: ApiConfig.jsonHeaders);
    _throwIfNeeded(response, context: 'Fetch event media');
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return EventMediaResponse.fromJson(decoded);
  }

  Future<List<SocialLink>> fetchSocialLinks() async {
    try {
      // Try both common naming conventions
      final endpoints = ['social_links', 'social-links', 'settings/social-links'];
      
      for (final endpoint in endpoints) {
        final uri = _buildUri(endpoint);
        debugPrint('Trying to fetch social links from: $uri');
        final response = await _httpClient.get(uri, headers: ApiConfig.jsonHeaders);
        
        if (response.statusCode == 200) {
          debugPrint('Successfully fetched social links from $endpoint');
          return _parseSocialLinks(response.body);
        }
      }
      
      debugPrint('All social links endpoints failed');
      return [];
    } catch (e) {
      debugPrint('Error fetching social links: $e');
      return [];
    }
  }

  List<SocialLink> _parseSocialLinks(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      List<dynamic> list = [];
      
      if (decoded is List<dynamic>) {
        list = decoded;
      } else if (decoded is Map<String, dynamic>) {
        // Handle different common wrapping keys
        final data = decoded['data'] ?? decoded['social_links'] ?? decoded['links'] ?? decoded['results'];
        if (data is List<dynamic>) {
          list = data;
        } else if (decoded.containsKey('id') && decoded.containsKey('platform')) {
          // It's a single object, wrap it
          list = [decoded];
        }
      }
      
      final links = list
          .whereType<Map<String, dynamic>>()
          .map(SocialLink.fromJson)
          .toList(growable: false);
          
      debugPrint('Parsed ${links.length} social links');
      return links;
    } catch (e) {
      debugPrint('Error parsing social links: $e');
      return [];
    }
  }

  Future<List<Category>> fetchPublicCategories(
      {int limit = 100, int page = 1}) async {
    final uri = _buildUri('categories/public', {
      'limit': '$limit',
      'page': '$page',
    });
    final response = await _httpClient
        .get(uri, headers: ApiConfig.jsonHeaders);
    _throwIfNeeded(response, context: 'Fetch public categories');
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Category.fromJson)
        .toList(growable: false);
  }

  /// Public home hero banners (`HeroSliderController@active`).
  Future<List<HeroSlide>> fetchActiveHeroSlides() async {
    final uri = _buildUri('hero-sliders/active');
    final response = await _httpClient
        .get(uri, headers: ApiConfig.jsonHeaders);
    _throwIfNeeded(response, context: 'Fetch active hero slides');
    final decoded = jsonDecode(response.body);
    final List<dynamic> list;
    if (decoded is List<dynamic>) {
      list = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      list = data is List<dynamic> ? data : const [];
    } else {
      list = const [];
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(HeroSlide.fromJson)
        .where((s) => s.imageUrl.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<AdkEventResponse> fetchAdkEvents({
    int page = 1,
    int limit = 20,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (startDate != null) 'start_date': _dateOnly(startDate),
      if (endDate != null) 'end_date': _dateOnly(endDate),
    };
    final uri = _buildUri('admin/events', query);
    final response = await _httpClient
        .get(uri, headers: ApiConfig.jsonHeaders);
    _throwIfNeeded(response, context: 'Fetch ADK events');
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return AdkEventResponse.fromJson(decoded);
  }

  Future<CataloguePageResponse> fetchCataloguePages(
      {int limit = 100, int page = 1, bool? isActive}) async {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (isActive != null) 'is_active': isActive ? '1' : '0',
    };
    final uri = _buildUri('catalogue', query);
    final response = await _httpClient
        .get(uri, headers: ApiConfig.jsonHeaders);
    _throwIfNeeded(response, context: 'Fetch catalogue pages');
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return CataloguePageResponse.fromJson(decoded);
  }

  Future<List<MemberSummary>> fetchPublicMembers({int limit = 500}) async {
    final uri = _buildUri('members/public', {'limit': '$limit'});
    print('Fetching from: $uri');

    try {
      final response = await _httpClient
          .get(uri, headers: ApiConfig.jsonHeaders);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      _throwIfNeeded(response, context: 'Fetch public members');
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['members'] as List<dynamic>? ?? const [];
      print('Parsed ${data.length} members');

      return data
          .whereType<Map<String, dynamic>>()
          .map(MemberSummary.fromJson)
          .toList(growable: false);
    } catch (e) {
      print('Error loading members: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchTeamStats() async {
    await ensureAuthenticated();
    final uri = _buildUri('auth/team-stats');
    print('Fetching team stats from: $uri');

    try {
      final response = await _httpClient.get(
        uri,
        headers: _authorizedHeaders(),
      );
      print('Team stats response status: ${response.statusCode}');
      print('Team stats response body: ${response.body}');

      _throwIfNeeded(response, context: 'Fetch team stats');
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      print('Team stats parsed: $decoded');
      return decoded;
    } catch (e) {
      print('Error loading team stats: $e');
      rethrow;
    }
  }

  Future<List<MemberSummary>> fetchTeamMembers({int limit = 1000}) async {
    await ensureAuthenticated();
    final uri = _buildUri('members/team', {'limit': '$limit'});
    print('Fetching team members from: $uri');

    try {
      final response = await _httpClient.get(
        uri,
        headers: _authorizedHeaders(),
      );
      print('Team members response status: ${response.statusCode}');
      print('Team members response body: ${response.body}');

      _throwIfNeeded(response, context: 'Fetch team members');
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['members'] as List<dynamic>? ?? const [];
      print('Parsed ${data.length} team members');

      return data
          .whereType<Map<String, dynamic>>()
          .map(MemberSummary.fromJson)
          .toList(growable: false);
    } catch (e) {
      print('Error loading team members: $e');
      rethrow;
    }
  }

  Map<String, String> _authorizedHeaders() {
    final token = _accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Not authenticated');
    }
    return {
      ...ApiConfig.jsonHeaders,
      'Authorization': 'Bearer $token',
    };
  }

  int _normalizeProductId(String productId) {
    final normalized = productId.trim();
    final parsed = int.tryParse(normalized);
    if (parsed != null) return parsed;
    final digits = RegExp(r'\d+').firstMatch(normalized)?.group(0);
    if (digits != null) {
      final fromDigits = int.tryParse(digits);
      if (fromDigits != null) return fromDigits;
    }
    throw ArgumentError('Invalid product id: $productId');
  }

  Uri _buildUri(String pathSegment, [Map<String, String>? query]) {
    final uri = Uri.parse('$_baseUrl/$pathSegment');
    return uri.replace(queryParameters: query);
  }

  String _dateOnly(DateTime date) => date.toIso8601String().split('T').first;

  List<ProductCatalogEntry> _parseProductList(http.Response response,
      {required String context}) {
    _throwIfNeeded(response, context: context);

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ProductCatalogEntry.fromJson)
        .toList(growable: false);
  }

  Future<void> _login() async {
    final uri = _buildUri('auth/login');
    final response = await _httpClient.post(
      uri,
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode({'email': _loginEmail, 'password': _loginPassword}),
    );

    _throwIfNeeded(response, context: 'Login');

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    _accessToken = decoded['accessToken'] as String?;

    if (_accessToken == null) {
      throw Exception('Login succeeded but token missing');
    }
    await _saveTokenToStorage(_accessToken!);
  }

  Future<void> loginWithCredentials(String email, String password) async {
    final uri = _buildUri('auth/login');
    final response = await _httpClient.post(
      uri,
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );

    _throwIfNeeded(response, context: 'Login');

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final token = decoded['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Login response missing access token');
    }
    _accessToken = token;
    await _saveTokenToStorage(token);
  }

  Future<Map<String, dynamic>> fetchCurrentMember(
      {bool autoAuthenticate = true}) async {
    if (_accessToken == null) {
      await _loadTokenFromStorage();
    }
    if (_accessToken == null) {
      if (!autoAuthenticate) {
        throw StateError('Not authenticated');
      }
      await ensureAuthenticated();
    }

    final uri = _buildUri('auth/me');
    final response = await _httpClient.get(uri, headers: _authorizedHeaders());
    _throwIfNeeded(response, context: 'Fetch current user');

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final member = decoded['member'];
    if (member is Map<String, dynamic>) {
      return member;
    }
    throw Exception('Malformed user payload: missing member');
  }

  /// Referral signup URLs from the server ([ReferralService] / `APP_SIGNUP_URL`).
  Future<ReferralLinks?> fetchReferralLinks() async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      await _loadTokenFromStorage();
    }
    if (_accessToken == null || _accessToken!.isEmpty) {
      return null;
    }
    final uri = _buildUri('referral/link');
    try {
      final response = await _httpClient.get(
        uri,
        headers: _authorizedHeaders(),
      );
      _throwIfNeeded(response, context: 'Fetch referral links');
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['status'] != true) return null;
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) return null;
      final left = (data['referral_link_left'] ?? data['referral_link'])
          as String?;
      final right = data['referral_link_right'] as String?;
      if (left == null || left.isEmpty) return null;
      return ReferralLinks(
        left: left,
        right: (right != null && right.isNotEmpty) ? right : left,
      );
    } catch (e, st) {
      debugPrint('fetchReferralLinks failed: $e');
      debugPrint('$st');
      return null;
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? profileImage,
    String? qrCodeUrl,
  }) async {
    await ensureAuthenticated();
    final payload = <String, dynamic>{
      if (fullName != null) 'fullName': fullName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (profileImage != null) 'profileImage': profileImage,
      if (qrCodeUrl != null) 'qrCodeUrl': qrCodeUrl,
    };

    final uri = _buildUri('profile');
    final response = await _httpClient.patch(
      uri,
      headers: _authorizedHeaders(),
      body: jsonEncode(payload),
    );
    _throwIfNeeded(response, context: 'Update profile');

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final member = decoded['member'];
    if (member is Map<String, dynamic>) {
      return member;
    }
    throw Exception('Malformed profile update response');
  }

  /// Updates member KYC number/image fields and returns refreshed `auth/me` member.
  Future<Map<String, dynamic>> updateKyc({
    String? bankAccountNumber,
    String? bankAccountImage,
    String? aadharNumber,
    String? aadharImage,
    String? panNumber,
    String? panImage,
  }) async {
    await ensureAuthenticated();
    final payload = <String, dynamic>{
      if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
      if (bankAccountImage != null) 'bankAccountImage': bankAccountImage,
      if (aadharNumber != null) 'aadharNumber': aadharNumber,
      if (aadharImage != null) 'aadharImage': aadharImage,
      if (panNumber != null) 'panNumber': panNumber,
      if (panImage != null) 'panImage': panImage,
    };
    if (payload.isEmpty) {
      throw ArgumentError('At least one KYC field is required');
    }

    final uri = _buildUri('kyc/update');
    final response = await _httpClient.post(
      uri,
      headers: _authorizedHeaders(),
      body: jsonEncode(payload),
    );
    _throwIfNeeded(response, context: 'Update KYC');

    // Keep ProfileState source-of-truth consistent with existing parsing logic.
    return fetchCurrentMember(autoAuthenticate: false);
  }

  Future<void> registerMember({
    required String fullName,
    required String email,
    required String password,
    required String referralCode,
    String? phone,
    String? address,
    String? sponsorId,
    String? leg,
    String? profileImage,
  }) async {
    final payload = {
      'full_name': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'referral_code': referralCode.trim(),
      if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
      if (address != null && address.isNotEmpty) 'address': address.trim(),
      if (sponsorId != null && sponsorId.isNotEmpty) 'sponsor_id': sponsorId,
      if (leg != null && leg.isNotEmpty) 'leg': leg.toUpperCase(),
      if (profileImage != null && profileImage.isNotEmpty)
        'profile_image': profileImage,
    };

    final uri = _buildUri('auth/register');
    final response = await _httpClient.post(
      uri,
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode(payload),
    );

    _throwIfNeeded(response, context: 'Register member');
  }

  Future<MemberTree> fetchMemberTree({
    required String memberId,
    int depth = 3,
  }) async {
    print('📡 API: Fetching member tree for $memberId with depth $depth');
    await ensureAuthenticated();
    final uri = _buildUri('members/$memberId/tree', {'depth': '$depth'});
    print('📡 API: Request URL: $uri');
    final response = await _httpClient.get(uri, headers: _authorizedHeaders());
    print('📡 API: Response status: ${response.statusCode}');
    _throwIfNeeded(response, context: 'Fetch member tree');
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    print(
        '📡 API: Response parsed, nodes count: ${(decoded['nodes'] as List?)?.length ?? 0}');
    return MemberTree.fromJson(decoded);
  }

  Future<void> logout() async {
    if (_accessToken == null) {
      return;
    }

    try {
      final uri = _buildUri('auth/logout');
      final response =
          await _httpClient.post(uri, headers: _authorizedHeaders());
      _throwIfNeeded(response, context: 'Logout');
    } catch (error) {
      rethrow;
    } finally {
      _accessToken = null;
      await _clearTokenFromStorage();
    }
  }

  void _throwIfNeeded(http.Response response, {required String context}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    if (response.statusCode == 401) {
      _accessToken = null;
    }
    throw Exception(
        '$context failed (${response.statusCode}): ${response.body}');
  }

  Future<Map<String, dynamic>> getIncomeTransactions(String memberId) async {
    if (_accessToken == null) {
      await ensureAuthenticated();
    }

    final uri = _buildUri('mlm/income/$memberId/transactions');
    final response = await _httpClient.get(uri, headers: _authorizedHeaders());
    _throwIfNeeded(response, context: 'Fetch income transactions');

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded;
  }

  Future<Map<String, dynamic>> getWalletTransactions(String memberId) async {
    if (_accessToken == null) {
      await ensureAuthenticated();
    }

    final uri = _buildUri('mlm/income/$memberId/wallet');
    final response = await _httpClient.get(uri, headers: _authorizedHeaders());
    _throwIfNeeded(response, context: 'Fetch wallet transactions');

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded;
  }

  Future<Map<String, dynamic>> getBVTransactions(String memberId) async {
    if (_accessToken == null) {
      await ensureAuthenticated();
    }

    final uri = _buildUri('mlm/income/$memberId/bv');
    final response = await _httpClient.get(uri, headers: _authorizedHeaders());
    _throwIfNeeded(response, context: 'Fetch BV transactions');

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded;
  }

  @mustCallSuper
  Future<Map<String, dynamic>> createMember({
    required String fullName,
    required String email,
    required String password,
    required String sponsorId,
    required String leg,
    String? phone,
    required String address,
    String? profileImage,
  }) async {
    await ensureAuthenticated();
    final uri = _buildUri('members');
    print('Creating member at: $uri');

    final payload = {
      'fullName': fullName,
      'email': email,
      'password': password,
      'sponsorId': sponsorId,
      'leg': leg,
      if (phone != null) 'phone': phone,
      'address': address,
      if (profileImage != null) 'profileImage': profileImage,
    };

    try {
      final response = await _httpClient.post(
        uri,
        headers: _authorizedHeaders(),
        body: jsonEncode(payload),
      );
      print('Create member response status: ${response.statusCode}');
      print('Create member response body: ${response.body}');

      _throwIfNeeded(response, context: 'Create member');
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      print('Member created successfully: $decoded');
      return decoded;
    } catch (e) {
      print('Error creating member: $e');
      rethrow;
    }
  }

  // Delivery Center API Methods
  Future<DeliveryCenterResponse> getDeliveryCenters({
    int page = 1,
    int limit = 25,
    String? search,
    String? location,
    bool? status,
  }) async {
    try {
      // Note: This endpoint is now public, no authentication required
      final query = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        query['search'] = search;
      }

      if (location != null && location.isNotEmpty) {
        query['location'] = location;
      }

      if (status != null) {
        query['status'] = status.toString();
      }

      final uri = _buildUri('delivery-centers', query);
      print('Fetching delivery centers from: $uri');

      final response =
          await _httpClient.get(uri, headers: ApiConfig.jsonHeaders);

      print('Delivery centers response status: ${response.statusCode}');
      print('Delivery centers response body: ${response.body}');

      _throwIfNeeded(response, context: 'Get delivery centers');
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      return DeliveryCenterResponse.fromJson(decoded);
    } catch (e) {
      print('Error fetching delivery centers: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createDeliveryCenter({
    required String name,
    required String ownerName,
    required String location,
    required String mobileNumber,
    bool isActive = true,
  }) async {
    try {
      await ensureAuthenticated();
      final uri = _buildUri('delivery-centers');
      final payload = {
        'name': name,
        'owner_name': ownerName,
        'location': location,
        'mobile_number': mobileNumber,
        'is_active': isActive,
      };

      print('Creating delivery center at: $uri');
      print('Payload: $payload');

      final response = await _httpClient.post(
        uri,
        headers: _authorizedHeaders(),
        body: jsonEncode(payload),
      );

      print('Create delivery center response status: ${response.statusCode}');
      print('Create delivery center response body: ${response.body}');

      _throwIfNeeded(response, context: 'Create delivery center');
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      print('Delivery center created successfully: $decoded');
      return decoded;
    } catch (e) {
      print('Error creating delivery center: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateDeliveryCenter({
    required int id,
    String? name,
    String? ownerName,
    String? location,
    String? mobileNumber,
    bool? isActive,
  }) async {
    try {
      await ensureAuthenticated();
      final uri = _buildUri('delivery-centers/$id');
      final payload = <String, dynamic>{};

      if (name != null) payload['name'] = name;
      if (ownerName != null) payload['owner_name'] = ownerName;
      if (location != null) payload['location'] = location;
      if (mobileNumber != null) payload['mobile_number'] = mobileNumber;
      if (isActive != null) payload['is_active'] = isActive;

      print('Updating delivery center at: $uri');
      print('Payload: $payload');

      final response = await _httpClient.patch(
        uri,
        headers: _authorizedHeaders(),
        body: jsonEncode(payload),
      );

      print('Update delivery center response status: ${response.statusCode}');
      print('Update delivery center response body: ${response.body}');

      _throwIfNeeded(response, context: 'Update delivery center');
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      print('Delivery center updated successfully: $decoded');
      return decoded;
    } catch (e) {
      print('Error updating delivery center: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteDeliveryCenter(int id) async {
    try {
      await ensureAuthenticated();
      final uri = _buildUri('delivery-centers/$id');
      print('Deleting delivery center at: $uri');

      final response = await _httpClient.delete(
        uri,
        headers: _authorizedHeaders(),
      );

      print('Delete delivery center response status: ${response.statusCode}');
      print('Delete delivery center response body: ${response.body}');

      _throwIfNeeded(response, context: 'Delete delivery center');
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      print('Delivery center deleted successfully: $decoded');
      return decoded;
    } catch (e) {
      print('Error deleting delivery center: $e');
      rethrow;
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
