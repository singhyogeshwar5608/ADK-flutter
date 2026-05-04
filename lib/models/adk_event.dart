class AdkEvent {
  const AdkEvent({
    required this.id,
    required this.leaderName,
    required this.meetingDate,
    required this.meetingTime,
    required this.storeName,
    required this.address,
    required this.state,
    required this.city,
    required this.leaderMobile,
    required this.storeMobile,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory AdkEvent.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    return AdkEvent(
      id: (json['id'] as num?)?.toInt() ?? 0,
      leaderName: json['leaderName'] as String? ?? '',
      meetingDate: parseDate(json['meetingDate'] as String?) ?? DateTime.now(),
      meetingTime: json['meetingTime'] as String? ?? '',
      storeName: json['storeName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      state: json['state'] as String? ?? '',
      city: json['city'] as String? ?? '',
      leaderMobile: json['leaderMobile'] as String? ?? '',
      storeMobile: json['storeMobile'] as String? ?? '',
      notes: json['notes'] as String?,
      createdAt: parseDate(json['createdAt'] as String?),
      updatedAt: parseDate(json['updatedAt'] as String?),
    );
  }

  final int id;
  final String leaderName;
  final DateTime meetingDate;
  final String meetingTime;
  final String storeName;
  final String address;
  final String state;
  final String city;
  final String leaderMobile;
  final String storeMobile;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class AdkEventResponse {
  const AdkEventResponse({required this.items, required this.meta});

  factory AdkEventResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AdkEvent.fromJson)
        .toList(growable: false);
    return AdkEventResponse(
      items: data,
      meta: AdkEventPaginationMeta.fromJson(json['meta'] as Map<String, dynamic>? ?? const {}),
    );
  }

  final List<AdkEvent> items;
  final AdkEventPaginationMeta meta;
}

class AdkEventPaginationMeta {
  const AdkEventPaginationMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory AdkEventPaginationMeta.fromJson(Map<String, dynamic> json) {
    return AdkEventPaginationMeta(
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      perPage: (json['perPage'] as num?)?.toInt() ?? 10,
      total: (json['total'] as num?)?.toInt() ?? 0,
      lastPage: (json['lastPage'] as num?)?.toInt() ?? 1,
    );
  }

  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
}
