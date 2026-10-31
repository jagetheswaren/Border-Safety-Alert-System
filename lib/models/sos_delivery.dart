enum SosDeliveryChannel {
  sms,
  whatsapp,
}

enum SosDeliveryStatus {
  pending,
  submitted,
  delivered,
  failed,
  retry,
}

class SosDelivery {
  const SosDelivery({
    required this.id,
    required this.eventId,
    required this.contactId,
    required this.contactName,
    required this.phoneNumber,
    required this.channel,
    required this.status,
    this.attemptCount = 1,
    required this.lastAttemptAt,
    this.errorMessage,
  });

  final String id;
  final String eventId;
  final String contactId;
  final String contactName;
  final String phoneNumber;
  final SosDeliveryChannel channel;
  final SosDeliveryStatus status;
  final int attemptCount;
  final DateTime lastAttemptAt;
  final String? errorMessage;

  SosDelivery copyWith({
    String? id,
    String? eventId,
    String? contactId,
    String? contactName,
    String? phoneNumber,
    SosDeliveryChannel? channel,
    SosDeliveryStatus? status,
    int? attemptCount,
    DateTime? lastAttemptAt,
    String? errorMessage,
  }) {
    return SosDelivery(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      channel: channel ?? this.channel,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'contact_id': contactId,
      'contact_name': contactName,
      'phone_number': phoneNumber,
      'channel': channel.name.toUpperCase(),
      'status': status.name.toUpperCase(),
      'attempt_count': attemptCount,
      'last_attempt_at': lastAttemptAt.toIso8601String(),
      'error_message': errorMessage,
    };
  }

  factory SosDelivery.fromMap(Map<String, dynamic> map) {
    return SosDelivery(
      id: map['id'] as String,
      eventId: map['event_id'] as String,
      contactId: map['contact_id'] as String,
      contactName: map['contact_name'] as String,
      phoneNumber: map['phone_number'] as String,
      channel: (map['channel'] as String? ?? 'SMS').toUpperCase() == 'WHATSAPP'
          ? SosDeliveryChannel.whatsapp
          : SosDeliveryChannel.sms,
      status: _parseStatus(map['status'] as String?),
      attemptCount: map['attempt_count'] as int? ?? 1,
      lastAttemptAt: DateTime.tryParse(map['last_attempt_at'] as String? ?? '') ?? DateTime.now(),
      errorMessage: map['error_message'] as String?,
    );
  }

  static SosDeliveryStatus _parseStatus(String? val) {
    switch (val?.toUpperCase()) {
      case 'SUBMITTED':
        return SosDeliveryStatus.submitted;
      case 'DELIVERED':
        return SosDeliveryStatus.delivered;
      case 'FAILED':
        return SosDeliveryStatus.failed;
      case 'RETRY':
        return SosDeliveryStatus.retry;
      case 'PENDING':
      default:
        return SosDeliveryStatus.pending;
    }
  }
}
