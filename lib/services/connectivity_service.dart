import 'dart:io';

/// Lightweight reachability probe. Never used to disable local safety.
class ConnectivityService {
  ConnectivityService({this.host = 'server.arcgisonline.com'});

  final String host;

  Future<bool> isOnline({Duration timeout = const Duration(seconds: 3)}) async {
    try {
      final result = await InternetAddress.lookup(host).timeout(timeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      try {
        final fallback = await InternetAddress.lookup('dns.google').timeout(timeout);
        return fallback.isNotEmpty;
      } catch (_) {
        // Return true as default to attempt online tile loading unless confirmed completely unavailable
        return true;
      }
    }
  }
}
