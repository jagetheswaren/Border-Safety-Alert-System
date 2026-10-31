enum SosStatus {
  created,
  alerting,
  partiallyDelivered,
  delivered,
  failed,
  cancelled,
}

class SosEvent {
  const SosEvent({
    required this.id,
    required this.eventUuid,
    required this.status,
    this.latitude,
    this.longitude,
    this.accuracy,
    required this.locationSource,
    required this.message,
    required this.createdAt,
    this.cancelledAt,
  });

  final String id;
  final String eventUuid;
  final SosStatus status;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String locationSource; // 'GPS_FRESH', 'GPS_LAST_KNOWN', 'UNAVAILABLE'
  final String message;
  final DateTime createdAt;
  final DateTime? cancelledAt;

  bool get isCancelled => status == SosStatus.cancelled || cancelledAt != null;

  String get googleMapsUrl {
    if (latitude != null && longitude != null) {
      return 'https://maps.google.com/?q=${latitude!.toStringAsFixed(6)},${longitude!.toStringAsFixed(6)}';
    }
    return 'Location unavailable';
  }

  SosEvent copyWith({
    String? id,
    String? eventUuid,
    SosStatus? status,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? locationSource,
    String? message,
    DateTime? createdAt,
    DateTime? cancelledAt,
  }) {
    return SosEvent(
      id: id ?? this.id,
      eventUuid: eventUuid ?? this.eventUuid,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      locationSource: locationSource ?? this.locationSource,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_uuid': eventUuid,
      'status': status.name.toUpperCase(),
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'location_source': locationSource,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
    };
  }

  factory SosEvent.fromMap(Map<String, dynamic> map) {
    SosStatus parseStatus(String? val) {
      switch (val?.toUpperCase()) {
        case 'ALERTING':
          return SosStatus.alerting;
        case 'PARTIALLY_DELIVERED':
          return SosStatus.partiallyDelivered;
        case 'DELIVERED':
          return SosStatus.delivered;
        case 'FAILED':
          return SosStatus.failed;
        case 'CANCELLED':
          return SosStatus.cancelled;
        case 'CREATED':
        default:
          return SosStatus.created;
      }
    }

    return SosEvent(
      id: map['id'] as String,
      eventUuid: map['event_uuid'] as String,
      status: parseStatus(map['status'] as String?),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      locationSource: map['location_source'] as String? ?? 'GPS_FRESH',
      message: map['message'] as String? ?? '',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      cancelledAt: map['cancelled_at'] != null ? DateTime.tryParse(map['cancelled_at'] as String) : null,
    );
  }
}
