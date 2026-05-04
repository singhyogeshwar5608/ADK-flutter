class DeliveryCenter {
  const DeliveryCenter({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.location,
    required this.mobileNumber,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String ownerName;
  final String location;
  final String mobileNumber;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory DeliveryCenter.fromJson(Map<String, dynamic> json) {
    return DeliveryCenter(
      id: json['id'] as int,
      name: json['name'] as String,
      ownerName: json['owner_name'] as String,
      location: json['location'] as String,
      mobileNumber: json['mobile_number'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_name': ownerName,
      'location': location,
      'mobile_number': mobileNumber,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DeliveryCenter copyWith({
    int? id,
    String? name,
    String? ownerName,
    String? location,
    String? mobileNumber,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeliveryCenter(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      location: location ?? this.location,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DeliveryCenter &&
        other.id == id &&
        other.name == name &&
        other.ownerName == ownerName &&
        other.location == location &&
        other.mobileNumber == mobileNumber &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        ownerName.hashCode ^
        location.hashCode ^
        mobileNumber.hashCode ^
        isActive.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'DeliveryCenter(id: $id, name: $name, ownerName: $ownerName, location: $location, mobileNumber: $mobileNumber, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

class DeliveryCenterMeta {
  const DeliveryCenterMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  final int page;
  final int limit;
  final int total;
  final int pages;

  factory DeliveryCenterMeta.fromJson(Map<String, dynamic> json) {
    return DeliveryCenterMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 25,
      total: (json['total'] as num?)?.toInt() ?? 0,
      pages: (json['pages'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'pages': pages,
    };
  }
}

class DeliveryCenterResponse {
  const DeliveryCenterResponse({
    required this.data,
    required this.meta,
  });

  final List<DeliveryCenter> data;
  final DeliveryCenterMeta meta;

  factory DeliveryCenterResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['data'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DeliveryCenter.fromJson)
        .toList(growable: false);
    return DeliveryCenterResponse(
      data: items,
      meta: DeliveryCenterMeta.fromJson(
          json['meta'] as Map<String, dynamic>? ?? const {}),
    );
  }
}
