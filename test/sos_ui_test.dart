import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:border_safety_alert/models/emergency_contact.dart';
import 'package:border_safety_alert/models/gps_snapshot.dart';
import 'package:border_safety_alert/models/location_model.dart';
import 'package:border_safety_alert/models/safety_state.dart';
import 'package:border_safety_alert/screens/sos_screen.dart';
import 'package:border_safety_alert/screens/emergency_contacts_screen.dart';
import 'package:border_safety_alert/services/emergency_contacts_repository.dart';
import 'package:border_safety_alert/services/sos_service.dart';
import 'package:border_safety_alert/services/sms_service.dart';

class TestSmsService extends SmsService {
  @override
  Future<SmsSendResult> sendEmergencySms({
    required String phoneNumber,
    required String message,
  }) async {
    return const SmsSendResult(state: SmsSendState.sentDirect);
  }
}

class FakeEmergencyContactsRepository extends EmergencyContactsRepository {
  FakeEmergencyContactsRepository({List<EmergencyContact>? initial})
      : _contacts = initial ??
            [
              EmergencyContact(
                id: 'contact_112',
                name: 'National Emergency Response (ERSS)',
                phoneNumber: '112',
                relationship: 'Emergency Services',
                whatsappEnabled: false,
                isActive: true,
                createdAt: DateTime(2026, 1, 1),
              ),
            ],
        super(factory: databaseFactoryFfi);

  final List<EmergencyContact> _contacts;

  @override
  Future<List<EmergencyContact>> loadAllContacts() async => List.unmodifiable(_contacts);

  @override
  Future<List<EmergencyContact>> loadActiveContacts() async =>
      _contacts.where((c) => c.isActive).toList();

  @override
  Future<void> saveContact(EmergencyContact contact) async {
    _contacts.add(contact);
  }

  @override
  Future<void> deleteContact(String contactId) async {
    _contacts.removeWhere((c) => c.id == contactId);
  }

  @override
  Future<void> toggleActive(String contactId, bool isActive) async {
    final idx = _contacts.indexWhere((c) => c.id == contactId);
    if (idx != -1) {
      _contacts[idx] = _contacts[idx].copyWith(isActive: isActive);
    }
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('SosScreen displays large SOS button and GPS telemetry', (tester) async {
    final repo = FakeEmergencyContactsRepository();
    final sosService = SosService(
      contactsRepository: repo,
      smsService: TestSmsService(),
    );

    final gps = GpsSnapshot(
      fix: GpsFixState.locked,
      permission: LocationPermissionState.granted,
      serviceEnabled: true,
      stale: false,
      location: LocationModel.validated(
        latitude: 10.712530,
        longitude: 76.979150,
        accuracy: 8.0,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SosScreen(
          sosService: sosService,
          gps: gps,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ONE-TAP SOS'), findsOneWidget);
    expect(find.text('TAP FOR SOS'), findsOneWidget);
    expect(find.text('10.712530'), findsOneWidget);
    expect(find.text('76.979150'), findsOneWidget);
    expect(find.text('±8 m'), findsOneWidget);
    expect(find.text('GPS LOCKED'), findsOneWidget);

    // Clean up repeating pulse animation controller before test exits
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('EmergencyContactsScreen renders contacts list and opens add dialog', (tester) async {
    final repo = FakeEmergencyContactsRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: EmergencyContactsScreen(repository: repo),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Emergency Contacts'), findsOneWidget);
    // Default seeded numbers
    expect(find.text('112'), findsOneWidget);

    // Tap add contact button
    await tester.tap(find.byIcon(Icons.person_add_alt_1_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Add Emergency Contact'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);

    // Clean up
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
