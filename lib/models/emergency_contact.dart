class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.relationship = 'Family / Emergency Contact',
    this.whatsappEnabled = true,
    this.isActive = true,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final bool whatsappEnabled;
  final bool isActive;
  final DateTime createdAt;

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? relationship,
    bool? whatsappEnabled,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      whatsappEnabled: whatsappEnabled ?? this.whatsappEnabled,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'relationship': relationship,
      'whatsapp_enabled': whatsappEnabled ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'] as String,
      name: map['name'] as String,
      phoneNumber: map['phone_number'] as String,
      relationship: map['relationship'] as String? ?? 'Contact',
      whatsappEnabled: (map['whatsapp_enabled'] as int? ?? 1) == 1,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Validates standard phone format (Indian 10-digit mobile, +91, or international E.164).
  static String? validatePhoneNumber(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Phone number cannot be empty';
    }
    final cleaned = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Standard international E.164 pattern or local 10-digit Indian pattern
    final regex = RegExp(r'^(\+?[1-9]\d{7,14}|[6-9]\d{9})$');
    if (!regex.hasMatch(cleaned)) {
      return 'Enter a valid mobile number (e.g. +91 9876543210 or 10-digit)';
    }
    return null;
  }

  /// Formats number for international dialling/SMS intent (e.g. prepends +91 if 10-digit Indian number)
  static String formatForDialing(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return '+91$cleaned';
    }
    return cleaned.startsWith('+') ? cleaned : '+$cleaned';
  }
}
