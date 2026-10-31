import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/app_database.dart';
import '../models/alert_severity.dart';
import '../models/gps_snapshot.dart';
import '../models/sos_delivery.dart';
import '../models/sos_event.dart';
import 'emergency_contacts_repository.dart';
import 'sms_service.dart';
import 'sound_service.dart';
import 'vibration_alert_service.dart';
import 'voice_alert_service.dart';
import 'whatsapp_service.dart';

class SosService extends ChangeNotifier {
  SosService({
    EmergencyContactsRepository? contactsRepository,
    SmsService? smsService,
    WhatsAppService? whatsAppService,
    SoundAlertOutput? soundService,
    VibrationAlertOutput? vibrationService,
    VoiceAlertOutput? voiceService,
    DatabaseFactory? factory,
    AppDatabase? appDatabase,
  })  : _contactsRepo = contactsRepository ?? EmergencyContactsRepository(factory: factory, appDatabase: appDatabase),
        _smsService = smsService ?? SmsService(),
        _whatsAppService = whatsAppService ?? WhatsAppService(),
        _soundService = soundService ?? SoundService(),
        _vibrationService = vibrationService ?? VibrationAlertService(),
        _voiceService = voiceService ?? VoiceAlertService(),
        _customFactory = factory,
        _appDb = appDatabase;

  final EmergencyContactsRepository _contactsRepo;
  final SmsService _smsService;
  final WhatsAppService _whatsAppService;
  final SoundAlertOutput _soundService;
  final VibrationAlertOutput _vibrationService;
  final VoiceAlertOutput _voiceService;
  final DatabaseFactory? _customFactory;

  DatabaseFactory get _factory {
    if (_customFactory != null) return _customFactory;
    try {
      return databaseFactory;
    } catch (_) {
      return databaseFactoryFfi;
    }
  }

  AppDatabase? _appDb;
  SosEvent? _activeEvent;
  List<SosDelivery> _activeDeliveries = [];
  bool _isProcessing = false;

  SosEvent? get activeEvent => _activeEvent;
  List<SosDelivery> get activeDeliveries => List.unmodifiable(_activeDeliveries);
  bool get isProcessing => _isProcessing;
  bool get hasActiveEmergency => _activeEvent != null && !_activeEvent!.isCancelled;

  Future<AppDatabase> _getDb() async {
    if (_appDb != null) return _appDb!;
    final dbPath = await _factory.getDatabasesPath();
    final path = '$dbPath/border_safety.db';
    _appDb = await AppDatabase.open(factory: _factory, path: path);
    return _appDb!;
  }

  /// Triggers One-Tap SOS emergency sequence.
  Future<SosEvent> triggerOneTapSos({
    required GpsSnapshot gps,
    String? customMessageNotes,
  }) async {
    _isProcessing = true;
    notifyListeners();

    final now = DateTime.now();
    final eventUuid = 'SOS-${now.millisecondsSinceEpoch}';
    final location = gps.location;

    final hasFreshGps = location != null && !gps.stale && !location.isStale;
    final lat = location?.latitude;
    final lon = location?.longitude;
    final accuracy = location?.accuracy;
    final locationSource = hasFreshGps ? 'GPS_FRESH' : (location != null ? 'GPS_LAST_KNOWN' : 'UNAVAILABLE');

    // Build emergency message
    final timeStr = DateFormat('hh:mm a, dd MMM yyyy').format(now);
    final mapLink = lat != null && lon != null
        ? 'https://maps.google.com/?q=${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}'
        : 'Coordinates unavailable';

    final emergencyMessage = '''
BSAS EMERGENCY ALERT
SOS - EMERGENCY! I NEED HELP.
I may be in danger and need immediate assistance.
My current location:
Latitude: ${lat?.toStringAsFixed(6) ?? 'N/A'}
Longitude: ${lon?.toStringAsFixed(6) ?? 'N/A'}
Accuracy: ${accuracy != null ? '±${accuracy.round()}m' : 'Unknown'} [$locationSource]
Location: $mapLink
Time: $timeStr
Please contact me and arrange emergency assistance.
Automated alert from Border Safety & Alert System (BSAS).'''.trim();

    var event = SosEvent(
      id: eventUuid,
      eventUuid: eventUuid,
      status: SosStatus.alerting,
      latitude: lat,
      longitude: lon,
      accuracy: accuracy,
      locationSource: locationSource,
      message: emergencyMessage,
      createdAt: now,
    );

    _activeEvent = event;
    _activeDeliveries = [];
    notifyListeners();

    // 1. Play high priority emergency sirens, vibration, and TTS announcement
    unawaited(_soundService.playCritical());
    unawaited(_vibrationService.vibrate(AlertSeverity.critical));
    unawaited(_voiceService.speak(
      'Emergency SOS activated. Sending location alerts to emergency contacts.',
    ));

    // 2. Persist event locally in SQLite
    final appDb = await _getDb();
    await appDb.db.insert(
      AppDatabase.tableSosEvents,
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 3. Load all active emergency contacts
    final contacts = await _contactsRepo.loadActiveContacts();
    final deliveryList = <SosDelivery>[];

    int successCount = 0;

    for (final contact in contacts) {
      // Channel: SMS (Primary)
      final smsDeliveryId = '${event.id}_sms_${contact.id}';
      var smsDelivery = SosDelivery(
        id: smsDeliveryId,
        eventId: event.id,
        contactId: contact.id,
        contactName: contact.name,
        phoneNumber: contact.phoneNumber,
        channel: SosDeliveryChannel.sms,
        status: SosDeliveryStatus.pending,
        attemptCount: 1,
        lastAttemptAt: DateTime.now(),
      );

      deliveryList.add(smsDelivery);
      _activeDeliveries = List.from(deliveryList);
      notifyListeners();

      // Dispatch SMS
      final smsResult = await _smsService.sendEmergencySms(
        phoneNumber: contact.phoneNumber,
        message: emergencyMessage,
      );

      if (smsResult.isSuccessful) {
        successCount++;
        smsDelivery = smsDelivery.copyWith(
          status: SosDeliveryStatus.delivered,
          lastAttemptAt: DateTime.now(),
        );
      } else {
        smsDelivery = smsDelivery.copyWith(
          status: SosDeliveryStatus.failed,
          errorMessage: smsResult.errorMessage,
          lastAttemptAt: DateTime.now(),
        );
      }

      await appDb.db.insert(
        AppDatabase.tableSosDeliveries,
        smsDelivery.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Channel: WhatsApp (Secondary Handoff)
      if (contact.whatsappEnabled) {
        final waDeliveryId = '${event.id}_wa_${contact.id}';
        var waDelivery = SosDelivery(
          id: waDeliveryId,
          eventId: event.id,
          contactId: contact.id,
          contactName: contact.name,
          phoneNumber: contact.phoneNumber,
          channel: SosDeliveryChannel.whatsapp,
          status: SosDeliveryStatus.pending,
          attemptCount: 1,
          lastAttemptAt: DateTime.now(),
        );
        deliveryList.add(waDelivery);
        _activeDeliveries = List.from(deliveryList);
        notifyListeners();

        await appDb.db.insert(
          AppDatabase.tableSosDeliveries,
          waDelivery.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    // Determine final status
    if (contacts.isEmpty) {
      event = event.copyWith(status: SosStatus.alerting);
    } else if (successCount == contacts.length) {
      event = event.copyWith(status: SosStatus.delivered);
    } else if (successCount > 0) {
      event = event.copyWith(status: SosStatus.partiallyDelivered);
    } else {
      event = event.copyWith(status: SosStatus.failed);
    }

    _activeEvent = event;
    _activeDeliveries = deliveryList;
    _isProcessing = false;
    notifyListeners();

    await appDb.db.update(
      AppDatabase.tableSosEvents,
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );

    return event;
  }

  /// Initiates WhatsApp handoff for a specific contact delivery.
  Future<void> initiateWhatsAppHandoff(SosDelivery delivery) async {
    if (_activeEvent == null) return;
    final state = await _whatsAppService.openEmergencyChat(
      phoneNumber: delivery.phoneNumber,
      message: _activeEvent!.message,
    );

    final appDb = await _getDb();
    final updatedDelivery = delivery.copyWith(
      status: state == WhatsAppHandoffState.openedHandoff
          ? SosDeliveryStatus.delivered
          : SosDeliveryStatus.failed,
      errorMessage: state == WhatsAppHandoffState.appNotInstalled
          ? 'WhatsApp is not installed on this device.'
          : (state == WhatsAppHandoffState.failed ? 'Could not open WhatsApp.' : null),
      lastAttemptAt: DateTime.now(),
    );

    await appDb.db.update(
      AppDatabase.tableSosDeliveries,
      updatedDelivery.toMap(),
      where: 'id = ?',
      whereArgs: [delivery.id],
    );

    final idx = _activeDeliveries.indexWhere((d) => d.id == delivery.id);
    if (idx != -1) {
      _activeDeliveries[idx] = updatedDelivery;
      notifyListeners();
    }
  }

  /// Cancels the active SOS alert and notifies contacts with safe status.
  Future<void> cancelSos({String reason = 'Accidental activation / False alarm'}) async {
    if (_activeEvent == null) return;
    final now = DateTime.now();
    final cancelledEvent = _activeEvent!.copyWith(
      status: SosStatus.cancelled,
      cancelledAt: now,
    );
    _activeEvent = cancelledEvent;
    notifyListeners();

    final appDb = await _getDb();
    await appDb.db.update(
      AppDatabase.tableSosEvents,
      cancelledEvent.toMap(),
      where: 'id = ?',
      whereArgs: [cancelledEvent.id],
    );

    // Vocal notification
    _soundService.setMuted(true);
    unawaited(_voiceService.speak('Emergency alert has been cancelled.'));

    // Optional safe all-clear SMS broadcast
    final timeStr = DateFormat('hh:mm a').format(now);
    final safeMsg = 'BSAS UPDATE: Emergency alert #$_activeEvent?.id has been CANCELLED at $timeStr. User is SAFE. ($reason)';
    final contacts = await _contactsRepo.loadActiveContacts();
    for (final contact in contacts) {
      unawaited(_smsService.sendEmergencySms(
        phoneNumber: contact.phoneNumber,
        message: safeMsg,
      ));
    }
  }

  /// Loads previous SOS events history from SQLite.
  Future<List<SosEvent>> loadHistory() async {
    final appDb = await _getDb();
    final rows = await appDb.db.query(
      AppDatabase.tableSosEvents,
      orderBy: 'created_at DESC',
      limit: 50,
    );
    return rows.map(SosEvent.fromMap).toList();
  }
}
