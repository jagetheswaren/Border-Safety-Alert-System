import 'dart:io';

/// Lightweight reachability probe. Never used to disable local safety.
class ConnectivityService {
  ConnectivityService({this.host = 'tile.openstreetmap.org'});

  final String host;

  Future<bool> isOnline({Duration timeout = const Duration(seconds: 2)}) async {
    try {
      final result = await InternetAddress.lookup(host).timeout(timeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
