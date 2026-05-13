import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/stored_address.dart';
import '../navigation/checkout_arguments.dart';

/// Persists address books in SharedPreferences only (no backend).
///
/// - **Guest** list key: [kGuestAddressesKey]
/// - **User** list key: `user_{userId}_addresses` (see [_userListKey])
/// - Optional checkout override JSON: [kCheckoutShippingOverrideKey]
class AddressStorageService {
  AddressStorageService._();
  static final AddressStorageService instance = AddressStorageService._();

  static const String kGuestAddressesKey = 'adk_v1_guest_addresses_json';
  static const String kCheckoutShippingOverrideKey =
      'adk_v1_checkout_shipping_override_json';

  /// At most this many addresses are kept per guest or user bucket.
  static const int maxSavedAddresses = 2;

  static String _userListKey(String userId) =>
      'adk_v1_user_${userId.trim()}_addresses_json';

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  List<StoredAddress> _decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => StoredAddress.fromJson(Map<String, dynamic>.from(e)))
          .where((a) => a.id.isNotEmpty)
          .toList();
    } catch (e, st) {
      debugPrint('AddressStorageService: corrupt JSON, clearing. $e\n$st');
      return [];
    }
  }

  Future<void> _writeList(String key, List<StoredAddress> list) async {
    final prefs = await _prefs();
    final encoded =
        jsonEncode(list.map((e) => e.toJson()).toList(growable: false));
    await prefs.setString(key, encoded);
  }

  // --- Public API (names aligned with requirements) ---

  Future<List<StoredAddress>> getGuestAddresses() async {
    final prefs = await _prefs();
    return _decodeList(prefs.getString(kGuestAddressesKey));
  }

  Future<void> saveGuestAddresses(List<StoredAddress> list) async {
    await _writeList(kGuestAddressesKey, list);
  }

  Future<List<StoredAddress>> getUserAddresses(String userId) async {
    if (userId.trim().isEmpty) return [];
    final prefs = await _prefs();
    return _decodeList(prefs.getString(_userListKey(userId)));
  }

  Future<void> saveUserAddresses(String userId, List<StoredAddress> list) async {
    if (userId.trim().isEmpty) return;
    await _writeList(_userListKey(userId), list);
  }

  Future<List<StoredAddress>> listForUserId(String? userId) async {
    if (userId == null || userId.trim().isEmpty) {
      return getGuestAddresses();
    }
    return getUserAddresses(userId);
  }

  List<StoredAddress> _normalizeDefaultsForUser(
    List<StoredAddress> list,
    String? userId,
  ) {
    if (list.isEmpty) return list;
    final uid = userId?.trim() ?? '';
    if (uid.isEmpty) return list;

    final defaultIds = list.where((e) => e.isDefault).map((e) => e.id).toList();
    if (defaultIds.isEmpty) {
      return [
        list.first.copyWith(isDefault: true),
        ...list.skip(1).map((e) => e.copyWith(isDefault: false)),
      ];
    }
    if (defaultIds.length == 1) return list;
    final keep = defaultIds.first;
    return list
        .map((e) => e.copyWith(isDefault: e.id == keep))
        .toList(growable: false);
  }

  /// Keeps the [maxSavedAddresses] most recently used rows; then normalizes default flag for logged-in users.
  List<StoredAddress> applyMaxCap(List<StoredAddress> list, {String? userId}) {
    if (list.length <= maxSavedAddresses) {
      return _normalizeDefaultsForUser(list, userId);
    }
    final sorted = [...list]
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    final trimmed =
        sorted.take(maxSavedAddresses).toList(growable: false);
    return _normalizeDefaultsForUser(trimmed, userId);
  }

  Future<void> persistAll(
    List<StoredAddress> list, {
    required String? userId,
  }) async {
    final capped = applyMaxCap(list, userId: userId);
    if (userId == null || userId.trim().isEmpty) {
      await saveGuestAddresses(capped);
    } else {
      await saveUserAddresses(userId, capped);
    }
  }

  /// Prefer most recently used; tie-break logged-in default.
  StoredAddress pickPrimaryForCheckout(List<StoredAddress> list) {
    assert(list.isNotEmpty, 'pickPrimaryForCheckout: empty list');
    var best = list.first;
    for (final a in list.skip(1)) {
      if (a.lastUsedAt > best.lastUsedAt) {
        best = a;
      } else if (a.lastUsedAt == best.lastUsedAt &&
          a.isDefault &&
          !best.isDefault) {
        best = a;
      }
    }
    return best;
  }

  Future<void> upsertFromShippingDetails(
    ShippingDetailsPayload payload, {
    String? userId,
  }) async {
    final list = await listForUserId(userId);
    final now = DateTime.now().millisecondsSinceEpoch;
    final probe = StoredAddress.fromShippingDetails(
      payload,
      id: '_',
      lastUsedAt: now,
    );
    final key = probe.dedupeKey;
    final idx = list.indexWhere((e) => e.dedupeKey == key);
    if (idx >= 0) {
      final old = list[idx];
      list[idx] = StoredAddress.fromShippingDetails(
        payload,
        id: old.id,
        isDefault: old.isDefault,
        lastUsedAt: now,
      );
    } else {
      final makeDefault = userId != null &&
          userId.trim().isNotEmpty &&
          !list.any((e) => e.isDefault);
      list.add(
        StoredAddress.fromShippingDetails(
          payload,
          id: newId(),
          isDefault: makeDefault,
          lastUsedAt: now,
        ),
      );
    }
    await persistAll(list, userId: userId);
  }

  Future<void> markAddressUsed(String id, {String? userId}) async {
    final list = await listForUserId(userId);
    final i = list.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    list[i] = list[i].copyWith(lastUsedAt: now);
    await persistAll(list, userId: userId);
  }

  Future<void> addAddress(StoredAddress address, {String? userId}) async {
    final list = await listForUserId(userId);
    list.add(address);
    await persistAll(list, userId: userId);
  }

  Future<void> updateAddress(StoredAddress address, {String? userId}) async {
    final list = await listForUserId(userId);
    final i = list.indexWhere((e) => e.id == address.id);
    if (i < 0) return;
    list[i] = address;
    await persistAll(list, userId: userId);
  }

  Future<void> deleteAddress(String id, {String? userId}) async {
    final list = await listForUserId(userId);
    list.removeWhere((e) => e.id == id);
    if (list.isNotEmpty && !list.any((e) => e.isDefault)) {
      list[0] = list[0].copyWith(isDefault: true);
    }
    await persistAll(list, userId: userId);
  }

  /// Ensures exactly one default when [userId] is non-null (logged-in).
  Future<void> setDefaultAddress(String id, String userId) async {
    if (userId.trim().isEmpty) return;
    final list = await getUserAddresses(userId);
    final next = <StoredAddress>[];
    for (final a in list) {
      next.add(a.copyWith(isDefault: a.id == id));
    }
    await persistAll(next, userId: userId);
  }

  /// After login: merge guest list into user list, de-dupe, clear guest storage.
  Future<void> migrateGuestToUser(String userId) async {
    final uid = userId.trim();
    if (uid.isEmpty) return;

    final guest = await getGuestAddresses();
    if (guest.isEmpty) return;

    final user = await getUserAddresses(uid);
    final merged = _mergeDedupe(user, guest);
    await persistAll(merged, userId: uid);
    await saveGuestAddresses([]);
    final prefs = await _prefs();
    await prefs.remove(kCheckoutShippingOverrideKey);
  }

  List<StoredAddress> _mergeDedupe(
    List<StoredAddress> user,
    List<StoredAddress> guest,
  ) {
    final out = <StoredAddress>[...user];
    final keys = out.map((e) => e.dedupeKey).toSet();
    for (final g in guest) {
      if (keys.add(g.dedupeKey)) {
        out.add(g);
      }
    }
    if (out.isEmpty) return out;
    final defaultCount = out.where((e) => e.isDefault).length;
    if (defaultCount == 0) {
      out[0] = out[0].copyWith(isDefault: true);
      return out;
    }
    if (defaultCount <= 1) return out;
    var keep = true;
    return out
        .map((e) {
          if (!e.isDefault) return e;
          if (keep) {
            keep = false;
            return e;
          }
          return e.copyWith(isDefault: false);
        })
        .toList(growable: false);
  }

  // --- Checkout override (selected "Use for checkout" from list) ---

  Future<ShippingDetailsPayload?> readCheckoutShippingOverride() async {
    final prefs = await _prefs();
    final raw = prefs.getString(kCheckoutShippingOverrideKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final em = map['email']?.toString().trim();
      return ShippingDetailsPayload(
        fullName: (map['fullName'] ?? '').toString(),
        primaryPhone: (map['primaryPhone'] ?? '').toString(),
        secondaryPhone: map['secondaryPhone']?.toString(),
        state: (map['state'] ?? '').toString(),
        city: (map['city'] ?? '').toString(),
        zipCode: (map['zipCode'] ?? '').toString(),
        shippingAddress: (map['shippingAddress'] ?? '').toString(),
        billingAddress: map['billingAddress']?.toString(),
        email: (em == null || em.isEmpty) ? null : em,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> writeCheckoutShippingOverride(
    ShippingDetailsPayload payload,
  ) async {
    final prefs = await _prefs();
    final map = {
      'fullName': payload.fullName,
      'primaryPhone': payload.primaryPhone,
      'secondaryPhone': payload.secondaryPhone,
      'state': payload.state,
      'city': payload.city,
      'zipCode': payload.zipCode,
      'shippingAddress': payload.shippingAddress,
      'billingAddress': payload.billingAddress,
      if ((payload.email ?? '').trim().isNotEmpty)
        'email': payload.email!.trim(),
    };
    await prefs.setString(kCheckoutShippingOverrideKey, jsonEncode(map));
  }

  Future<void> clearCheckoutShippingOverride() async {
    final prefs = await _prefs();
    await prefs.remove(kCheckoutShippingOverrideKey);
  }

  static String newId() => 'addr_${DateTime.now().microsecondsSinceEpoch}';
}
