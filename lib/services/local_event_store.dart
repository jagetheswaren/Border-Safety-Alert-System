import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LocalSafetyEvent {
  const LocalSafetyEvent({
    required this.eventId,
    required this.timestamp,
    required this.eventType,
    required this.latitude,
    required this.longitude,
    required this.zone,
    required this.riskState,
    required this.aiState,
    required this.alertState,
    this.synced = false,
  });

  final String eventId;
  final DateTime timestamp;
  final String eventType;
  final double latitude;
  final double longitude;
  final String zone;
  final String riskState;
  final String aiState;
  final String alertState;
  final bool synced;

  Map<String, dynamic> toMap() => {
        'event_id': eventId,
        'timestamp': timestamp.toIso8601String(),
        'event_type': eventType,
        'latitude': latitude,
        'longitude': longitude,
        'zone': zone,
        'risk_state': riskState,
        'ai_state': aiState,
        'alert_state': alertState,
        'synced': synced ? 1 : 0,
      };

  factory LocalSafetyEvent.fromMap(Map<String, dynamic> map) => LocalSafetyEvent(
        eventId: map['event_id'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        eventType: map['event_type'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        zone: map['zone'] as String,
        riskState: map['risk_state'] as String,
        aiState: map['ai_state'] as String,
        alertState: map['alert_state'] as String,
        synced: (map['synced'] as int) == 1,
      );

  LocalSafetyEvent copyWith({bool? synced}) => LocalSafetyEvent(
        eventId: eventId,
        timestamp: timestamp,
        eventType: eventType,
        latitude: latitude,
        longitude: longitude,
        zone: zone,
        riskState: riskState,
        aiState: aiState,
        alertState: alertState,
        synced: synced ?? this.synced,
      );
}

class LocalEventStore extends ChangeNotifier {
  LocalEventStore();

  final List<LocalSafetyEvent> _events = [];
  bool _initialized = false;
  File? _file;

  bool get isInitialized => _initialized;
  List<LocalSafetyEvent> get allEvents => List.unmodifiable(_events);
  List<LocalSafetyEvent> get unsyncedEvents =>
      List.unmodifiable(_events.where((e) => !e.synced));
  int get pendingCount => _events.where((e) => !e.synced).length;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/local_events.json');
      if (await _file!.exists()) {
        final text = await _file!.readAsString();
        final list = jsonDecode(text) as List<dynamic>;
        _events.clear();
        for (final item in list) {
          _events.add(LocalSafetyEvent.fromMap(item as Map<String, dynamic>));
        }
      }
    } catch (_) {}
    _initialized = true;
    notifyListeners();
  }

  Future<void> _save() async {
    if (_file == null) return;
    try {
      final data = _events.map((e) => e.toMap()).toList();
      await _file!.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  Future<void> recordEvent(LocalSafetyEvent event) async {
    _events.insert(0, event);
    if (_events.length > 200) {
      _events.removeLast();
    }
    await _save();
    notifyListeners();
  }

  Future<void> markSynced(List<String> eventIds) async {
    final set = eventIds.toSet();
    for (int i = 0; i < _events.length; i++) {
      if (set.contains(_events[i].eventId)) {
        _events[i] = _events[i].copyWith(synced: true);
      }
    }
    await _save();
    notifyListeners();
  }

  Future<void> clearEvents() async {
    _events.clear();
    await _save();
    notifyListeners();
  }
}
