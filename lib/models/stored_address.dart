import 'package:flutter/foundation.dart';

import '../navigation/checkout_arguments.dart';

/// Local-only shipping address (SharedPreferences). Not synced to backend.
@immutable
class StoredAddress {
  const StoredAddress({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.addressLine,
    required this.city,
    required this.state,
    this.country = 'India',
    required this.pincode,
    this.isDefault = false,
    this.lastUsedAt = 0,
  });

  final String id;
  final String name;
  final String phone;
  final String? email;
  final String addressLine;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final bool isDefault;

  /// Milliseconds since epoch; used to pick latest checkout delivery.
  final int lastUsedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        if (email != null && email!.trim().isNotEmpty) 'email': email,
        'addressLine': addressLine,
        'city': city,
        'state': state,
        'country': country,
        'pincode': pincode,
        'isDefault': isDefault,
        'lastUsedAt': lastUsedAt,
      };

  factory StoredAddress.fromJson(Map<String, dynamic> json) {
    final lu = json['lastUsedAt'] ?? json['last_used_at'];
    return StoredAddress(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString().trim().isEmpty
          ? null
          : (json['email'] ?? '').toString().trim(),
      addressLine: (json['addressLine'] ?? json['address_line'] ?? '')
          .toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      country: (json['country'] ?? 'India').toString(),
      pincode: (json['pincode'] ?? json['zip'] ?? '').toString(),
      isDefault: json['isDefault'] == true || json['is_default'] == true,
      lastUsedAt: lu is int ? lu : int.tryParse('$lu') ?? 0,
    );
  }

  StoredAddress copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? addressLine,
    String? city,
    String? state,
    String? country,
    String? pincode,
    bool? isDefault,
    int? lastUsedAt,
  }) {
    return StoredAddress(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      pincode: pincode ?? this.pincode,
      isDefault: isDefault ?? this.isDefault,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  factory StoredAddress.fromShippingDetails(
    ShippingDetailsPayload p, {
    required String id,
    bool isDefault = false,
    int lastUsedAt = 0,
  }) {
    return StoredAddress(
      id: id,
      name: p.fullName.trim(),
      phone: p.primaryPhone.trim(),
      email: (p.email ?? '').trim().isEmpty ? null : p.email!.trim(),
      addressLine: p.shippingAddress.trim(),
      city: p.city.trim(),
      state: p.state.trim(),
      country: p.country.trim(),
      pincode: p.zipCode.trim(),
      isDefault: isDefault,
      lastUsedAt: lastUsedAt,
    );
  }

  /// Maps into the existing checkout payload shape.
  ShippingDetailsPayload toShippingDetailsPayload() {
    return ShippingDetailsPayload(
      fullName: name.trim(),
      primaryPhone: phone.trim(),
      secondaryPhone: null,
      country: country.trim(),
      state: state.trim(),
      city: city.trim(),
      zipCode: pincode.trim(),
      shippingAddress: addressLine.trim(),
      billingAddress: null,
      email: (email ?? '').trim().isEmpty ? null : email!.trim(),
    );
  }

  /// Fuzzy key for de-duplication when merging guest → user lists.
  String get dedupeKey {
    final p = phone.replaceAll(RegExp(r'\s'), '');
    return '${p.toLowerCase()}|${pincode.trim().toLowerCase()}|'
        '${city.trim().toLowerCase()}|${state.trim().toLowerCase()}|'
        '${addressLine.trim().toLowerCase()}';
  }
}
