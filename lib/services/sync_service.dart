import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'local_event_store.dart';
import 'sound_service.dart';
import 'notification_service.dart';

enum SyncStatus { idle, syncing, complete, offline, error }

class SyncService extends ChangeNotifier {
  SyncService({
    required this.eventStore,
    this.soundService,
    this.notificationService,
    this.baseUrl = 'http://10.0.2.2:8000',
  });

  final LocalEventStore eventStore;
  final SoundService? soundService;
  final NotificationService? notificationService;
  String baseUrl;

  SyncStatus _status = SyncStatus.idle;
  int _lastSyncedCount = 0;
  String? _errorMessage;

  SyncStatus get status => _status;
  int get lastSyncedCount => _lastSyncedCount;
  int get pendingCount => eventStore.pendingCount;
  String? get errorMessage => _errorMessage;

  Future<bool> checkConnectivity() async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
      final uri = Uri.parse('$baseUrl/api/v1/health');
      final req = await client.getUrl(uri);
      final res = await req.close();
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> syncNow() async {
    final pending = eventStore.unsyncedEvents;
    if (pending.isEmpty) {
      _status = SyncStatus.complete;
      _lastSyncedCount = 0;
      notifyListeners();
      return;
    }

    _status = SyncStatus.syncing;
    _errorMessage = null;
    notifyListeners();

    final isOnline = await checkConnectivity();
    if (!isOnline) {
      _status = SyncStatus.offline;
      notifyListeners();
      return;
    }

    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final uri = Uri.parse('$baseUrl/api/v1/alerts/bulk');
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;

      final payload = jsonEncode(pending.map((e) => e.toMap()).toList());
      req.write(payload);
      final res = await req.close();

      if (res.statusCode == 200 || res.statusCode == 201) {
        final ids = pending.map((e) => e.eventId).toList();
        await eventStore.markSynced(ids);
        _lastSyncedCount = ids.length;
        _status = SyncStatus.complete;

        // Feedback
        await soundService?.playSyncComplete();
        await notificationService?.showSystemNotification(
          'BSAS Sync Complete',
          '${ids.length} offline safety events synced to Operations Dashboard.',
        );
      } else {
        _status = SyncStatus.error;
        _errorMessage = 'Backend returned status code ${res.statusCode}';
      }
    } catch (e) {
      _status = SyncStatus.offline;
      _errorMessage = 'Network unreachable: $e';
    }
    notifyListeners();
  }
}
