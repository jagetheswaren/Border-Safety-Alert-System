import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_event_store.dart';
import 'sound_service.dart';
import 'notification_service.dart';

enum SyncStatus { idle, syncing, complete, offline, error, notConfigured, authenticationRequired }

class SyncService extends ChangeNotifier {
  SyncService({required this.eventStore, this.soundService, this.notificationService,
    this.baseUrl = const String.fromEnvironment('BSAS_API_URL'), this.deviceId = '', this.authToken});
  final LocalEventStore eventStore;
  final SoundService? soundService;
  final NotificationService? notificationService;
  final _secure = const FlutterSecureStorage();
  String baseUrl;
  String deviceId;
  String? authToken;
  Timer? _timer;
  bool _disposed = false;
  bool _busy = false;
  SyncStatus _status = SyncStatus.idle;
  int _lastSyncedCount = 0;
  int _consecutiveFailures = 0;
  String? _errorMessage;
  DateTime? _lastSyncTime;
  SyncStatus get status => _status;
  int get lastSyncedCount => _lastSyncedCount;
  int get pendingCount => eventStore.pendingCount;
  String? get errorMessage => _errorMessage;
  DateTime? get lastSyncTime => _lastSyncTime;
  void _changed() { if (!_disposed) notifyListeners(); }

  static bool validEndpoint(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.hasAuthority && uri.userInfo.isEmpty && uri.query.isEmpty && uri.fragment.isEmpty &&
      (uri.scheme == 'https' || (!kReleaseMode && uri.scheme == 'http' && ['localhost','127.0.0.1','10.0.2.2'].contains(uri.host)));
  }

  Future<void> start() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      baseUrl = prefs.getString('backend_url') ?? baseUrl;
      deviceId = prefs.getString('device_id') ?? List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2,'0')).join();
      await prefs.setString('device_id', deviceId);
      authToken = await _secure.read(key:'bsas_access_token');
      _lastSyncTime = DateTime.tryParse(prefs.getString('last_sync_time') ?? '');
    } catch (error) { _errorMessage = 'Session storage unavailable'; }
    if (_disposed) return;
    eventStore.addListener(_onEventsChanged);
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => unawaited(syncNow()));
    await syncNow();
  }

  void _onEventsChanged() {
    _changed();
    if (!_busy) unawaited(syncNow());
  }

  Future<void> signIn(String endpoint, String email, String password, {bool register = false}) async {
    endpoint = endpoint.trim().replaceFirst(RegExp(r'/+$'), '');
    if (!validEndpoint(endpoint)) throw ArgumentError('Use an HTTPS backend URL. Local HTTP is available only in debug builds.');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      if (register) {
        final req = await client.postUrl(Uri.parse('$endpoint/api/v1/auth/register'));
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode({'email':email.trim(),'password':password}));
        final res = await req.close().timeout(const Duration(seconds:15));
        await res.drain<void>();
        if (res.statusCode != 201) throw StateError('Account creation failed (${res.statusCode})');
      }
      final req = await client.postUrl(Uri.parse('$endpoint/api/v1/auth/login'));
      req.headers.contentType = ContentType('application','x-www-form-urlencoded');
      req.write(Uri(queryParameters:{'username':email.trim(),'password':password}).query);
      final res = await req.close().timeout(const Duration(seconds:15));
      final body = await utf8.decoder.bind(res).join();
      if (res.statusCode != 200) throw StateError('Sign-in failed (${res.statusCode})');
      final token = (jsonDecode(body) as Map<String,dynamic>)['access_token'];
      if (token is! String || token.isEmpty) throw StateError('Invalid authentication response');
      await _secure.write(key:'bsas_access_token',value:token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('backend_url',endpoint);
      baseUrl = endpoint;
      authToken = token;
      _errorMessage = null;
      await syncNow(force:true);
    } finally { client.close(force:true); }
  }

  Future<void> signOut() async {
    authToken = null;
    await _secure.delete(key:'bsas_access_token');
    _status = SyncStatus.authenticationRequired;
    _changed();
  }

  Future<bool> checkConnectivity() async {
    if (!validEndpoint(baseUrl)) return false;
    final client = HttpClient()..connectionTimeout = const Duration(seconds:3);
    try {
      final req = await client.getUrl(Uri.parse('$baseUrl/api/v1/health'));
      final res = await req.close().timeout(const Duration(seconds:5));
      final data = jsonDecode(await utf8.decoder.bind(res).join().timeout(const Duration(seconds:5)));
      return res.statusCode == 200 && data is Map && data['status'] == 'ok';
    } catch (_) { return false; }
    finally { client.close(force:true); }
  }

  Future<void> syncNow({bool force = false}) async {
    if (_busy || _disposed) return;
    if (!validEndpoint(baseUrl)) { _status=SyncStatus.notConfigured; _changed(); return; }
    if (authToken == null || authToken!.isEmpty) { _status=SyncStatus.authenticationRequired; _changed(); return; }
    _busy = true;
    List<LocalSafetyEvent> pending = [];
    HttpClient? client;
    try {
      pending = await eventStore.pendingBatch(force:force);
      if (pending.isEmpty) { _status = pendingCount == 0 && _lastSyncTime != null ? SyncStatus.complete : SyncStatus.idle; return; }
      _status = SyncStatus.syncing;
      _errorMessage = null;
      _changed();
      if (!await checkConnectivity()) throw const SocketException('Backend unreachable or unhealthy');
      client = HttpClient()..connectionTimeout = const Duration(seconds:8);
      final req = await client.postUrl(Uri.parse('$baseUrl/api/v1/sync/batch'));
      req.headers.contentType = ContentType.json;
      req.headers.set('Authorization','Bearer $authToken');
      req.write(jsonEncode({'device_id':deviceId,'client_timestamp':DateTime.now().toUtc().toIso8601String(),
        'events':pending.map((e)=>{'event_id':e.eventId,'timestamp':e.timestamp.toUtc().toIso8601String(),
          'event_type':e.eventType,'latitude':e.latitude,'longitude':e.longitude,'zone':e.zone,
          'risk_state':e.riskState,'ai_state':e.aiState,'alert_state':e.alertState,'device_id':deviceId}).toList()}));
      final res = await req.close().timeout(const Duration(seconds:15));
      final body = await utf8.decoder.bind(res).join().timeout(const Duration(seconds:15));
      if (res.statusCode == 401) { _status=SyncStatus.authenticationRequired; throw StateError('Sign in again to resume sync'); }
      if (res.statusCode != 200) throw StateError('Server rejected batch (${res.statusCode})');
      final data = jsonDecode(body) as Map<String,dynamic>;
      final ids = data['acknowledged_ids'];
      final sent = pending.map((e)=>e.eventId).toSet();
      if (data['status'] != 'SUCCESS' || data['receipt_id'] is! String || (data['receipt_id'] as String).isEmpty ||
          ids is! List || ids.any((id)=>id is! String || !sent.contains(id)) ||
          ids.toSet().length != ids.length || data['synced_count'] != ids.length || ids.length != sent.length) {
        throw const FormatException('Invalid server acknowledgement; events remain pending');
      }
      await eventStore.markSynced(ids.cast<String>());
      _lastSyncedCount = ids.length;
      _lastSyncTime = DateTime.now().toUtc();
      _consecutiveFailures = 0;
      _status = pendingCount == 0 ? SyncStatus.complete : SyncStatus.idle;
      try { final prefs=await SharedPreferences.getInstance(); await prefs.setString('last_sync_time',_lastSyncTime!.toIso8601String()); } catch (_) {}
    } catch (error) {
      _consecutiveFailures++;
      if (_status != SyncStatus.authenticationRequired) _status = error is SocketException || error is TimeoutException ? SyncStatus.offline : SyncStatus.error;
      _errorMessage = error.toString();
      if (pending.isNotEmpty) {
        try { await eventStore.recordFailure(pending.map((e)=>e.eventId).toList(),_errorMessage!,getRetryDelay()); }
        catch (_) { _errorMessage = 'Sync failed; SQLite retry status could not be saved'; }
      }
    } finally {
      client?.close(force:true);
      _busy = false;
      _changed();
    }
  }

  Duration getRetryDelay() => Duration(seconds:min(300, 1 << min(_consecutiveFailures,8)));
  @override
  void dispose() { _disposed=true; _timer?.cancel(); eventStore.removeListener(_onEventsChanged); super.dispose(); }
}
