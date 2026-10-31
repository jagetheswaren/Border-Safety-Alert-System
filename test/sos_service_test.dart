import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:border_safety_alert/models/emergency_contact.dart';
import 'package:border_safety_alert/models/gps_snapshot.dart';
import 'package:border_safety_alert/models/location_model.dart';
import 'package:border_safety_alert/models/safety_state.dart';
import 'package:border_safety_alert/models/sos_event.dart';
import 'package:border_safety_alert/services/emergency_contacts_repository.dart';
import 'package:border_safety_alert/services/sos_service.dart';
import 'package:border_safety_alert/services/sms_service.dart';
import 'package:border_safety_alert/services/sound_service.dart';
import 'package:border_safety_alert/services/voice_alert_service.dart';
import 'package:border_safety_alert/services/vibration_alert_service.dart';
import 'package:border_safety_alert/models/alert_severity.dart';

class FakeVoice implements VoiceAlertOutput {
  @override
  Future<void> speak(String message) async {}
  @override
  Future<void> stop() async {}
}

class FakeSound implements SoundAlertOutput {
  @override
  Future<void> playCritical() async {}
  @override
  Future<void> playWarning() async {}
  @override
  void setMuted(bool muted) {}
}

class FakeVibration implements VibrationAlertOutput {
  @override
  Future<void> vibrate(AlertSeverity severity) async {}
  @override
  Future<void> stop() async {}
}

class MockSmsService extends SmsService {
  final List<String> sentMessages = [];
  final List<String> sentNumbers = [];
  bool shouldFail = false;

  @override
  Future<SmsSendResult> sendEmergencySms({
    required String phoneNumber,
    required String message,
  }) async {
    if (shouldFail) {
      return const SmsSendResult(
        state: SmsSendState.failed,
        errorMessage: 'Simulated network drop',
      );
    }
    sentNumbers.add(phoneNumber);
    sentMessages.add(message);
    return const SmsSendResult(state: SmsSendState.sentDirect, partsCount: 1);
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
  });

  group('Emergency Contact Model & Validation Tests', () {
    test('validates standard phone numbers correctly', () {
      expect(EmergencyContact.validatePhoneNumber('+919876543210'), isNull);
      expect(EmergencyContact.validatePhoneNumber('9876543210'), isNull);
      expect(EmergencyContact.validatePhoneNumber('+14155552671'), isNull);
      expect(EmergencyContact.validatePhoneNumber(''), isNotNull);
      expect(EmergencyContact.validatePhoneNumber('123'), isNotNull);
      expect(EmergencyContact.validatePhoneNumber('abc'), isNotNull);
    });

    test('formats numbers for dialing', () {
      expect(EmergencyContact.formatForDialing('9876543210'), '+919876543210');
      expect(EmergencyContact.formatForDialing('+14155552671'), '+14155552671');
    });
  });

  group('EmergencyContactsRepository SQLite Tests', () {
    late EmergencyContactsRepository repo;

    setUp(() {
      repo = EmergencyContactsRepository(factory: databaseFactoryFfi);
    });

    test('seeds default emergency helplines on first launch', () async {
      final contacts = await repo.loadAllContacts();
      expect(contacts.isNotEmpty, isTrue);
      expect(contacts.any((c) => c.phoneNumber == '112'), isTrue);
      expect(contacts.any((c) => c.phoneNumber == '1926'), isTrue);
    });

    test('saves, toggles and deletes contacts', () async {
      final newContact = EmergencyContact(
        id: 'test_c1',
        name: 'Test Officer',
        phoneNumber: '+919999999999',
        relationship: 'Security',
        whatsappEnabled: true,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await repo.saveContact(newContact);
      var all = await repo.loadAllContacts();
      expect(all.any((c) => c.id == 'test_c1'), isTrue);

      await repo.toggleActive('test_c1', false);
      var active = await repo.loadActiveContacts();
      expect(active.any((c) => c.id == 'test_c1'), isFalse);

      await repo.deleteContact('test_c1');
      all = await repo.loadAllContacts();
      expect(all.any((c) => c.id == 'test_c1'), isFalse);
    });
  });

  group('One-Tap SOS Service Engine Tests', () {
    late SosService sosService;
    late MockSmsService mockSms;
    late EmergencyContactsRepository repo;

    setUp(() async {
      repo = EmergencyContactsRepository(factory: databaseFactoryFfi);
      mockSms = MockSmsService();
      sosService = SosService(
        contactsRepository: repo,
        smsService: mockSms,
        soundService: FakeSound(),
        voiceService: FakeVoice(),
        vibrationService: FakeVibration(),
        factory: databaseFactoryFfi,
      );
    });

    test('One-tap trigger generates emergency event and sends SMS with GPS coordinates', () async {
      final gps = GpsSnapshot(
        fix: GpsFixState.locked,
        permission: LocationPermissionState.granted,
        serviceEnabled: true,
        stale: false,
        location: LocationModel.validated(
          latitude: 10.7125,
          longitude: 76.9791,
          accuracy: 6.5,
        ),
      );

      final event = await sosService.triggerOneTapSos(gps: gps);

      expect(event.status, isIn([SosStatus.delivered, SosStatus.alerting, SosStatus.partiallyDelivered]));
      expect(event.latitude, 10.7125);
      expect(event.longitude, 76.9791);
      expect(event.locationSource, 'GPS_FRESH');
      expect(event.message, contains('BSAS EMERGENCY ALERT'));
      expect(event.message, contains('10.712500'));
      expect(event.message, contains('76.979100'));
      expect(mockSms.sentNumbers.isNotEmpty, isTrue);
      expect(sosService.hasActiveEmergency, isTrue);
    });

    test('SOS handles stale/unavailable GPS with truthful last-known label', () async {
      final staleGps = GpsSnapshot(
        fix: GpsFixState.locked,
        permission: LocationPermissionState.granted,
        serviceEnabled: true,
        stale: true,
        location: LocationModel.validated(
          latitude: 10.5000,
          longitude: 76.8000,
          accuracy: 15.0,
        ),
      );

      final event = await sosService.triggerOneTapSos(gps: staleGps);
      expect(event.locationSource, 'GPS_LAST_KNOWN');
      expect(event.message, contains('[GPS_LAST_KNOWN]'));
    });

    test('Cancelling active SOS updates status and broadcasts safe confirmation', () async {
      final gps = GpsSnapshot(
        fix: GpsFixState.locked,
        permission: LocationPermissionState.granted,
        serviceEnabled: true,
        stale: false,
        location: LocationModel.validated(latitude: 10.1, longitude: 76.2),
      );

      await sosService.triggerOneTapSos(gps: gps);
      expect(sosService.hasActiveEmergency, isTrue);

      await sosService.cancelSos(reason: 'Test false alarm resolved');
      expect(sosService.hasActiveEmergency, isFalse);
      expect(sosService.activeEvent?.status, SosStatus.cancelled);
      expect(sosService.activeEvent?.cancelledAt, isNotNull);
      expect(mockSms.sentMessages.last, contains('User is SAFE'));
    });
  });
}
