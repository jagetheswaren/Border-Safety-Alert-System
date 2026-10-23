import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'ai_provider.dart';
import 'local_chat_service.dart';

class BackendAiProvider implements AiProvider {
  BackendAiProvider({
    String? baseUrl,
    this.authToken,
  }) : baseUrl = baseUrl ?? (kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000');

  String baseUrl;
  String? authToken;
  String _activeModelName = 'BSAS AI Gateway';
  AiProviderStatus _status = AiProviderStatus.checking;
  http.Client? _activeClient;
  bool _cancelled = false;

  @override
  String get providerName => 'FastAPI AI Gateway';

  @override
  String get modelName => _activeModelName;

  @override
  AiProviderStatus get status => _status;

  void updateBaseUrl(String newUrl) {
    baseUrl = newUrl.trim().replaceAll(RegExp(r'/+$'), '');
  }

  void updateToken(String? token) {
    authToken = token;
  }

  @override
  Future<AiProviderStatus> checkHealth() async {
    _status = AiProviderStatus.checking;

    final candidateHosts = [
      baseUrl,
      'http://127.0.0.1:8000',
      'http://10.0.2.2:8000',
    ];

    for (final host in candidateHosts) {
      try {
        final uri = Uri.parse('$host/api/v1/health');
        final response = await http.get(uri).timeout(const Duration(milliseconds: 2500));
        if (response.statusCode == 200) {
          baseUrl = host;
          _status = AiProviderStatus.ready;
          return _status;
        }
      } catch (_) {
        // try next host
      }
    }

    _status = AiProviderStatus.offline;
    return _status;
  }

  @override
  Stream<String> generateChatStream({
    required List<Map<String, String>> messages,
    SafetyContextSnapshot? safetyContext,
  }) async* {
    _cancelled = false;
    _activeClient = http.Client();

    final userMessage = messages.isNotEmpty ? messages.last['content'] ?? '' : '';

    // If authToken is not yet set, attempt dev-mode login to obtain access token
    if (authToken == null || authToken!.isEmpty) {
      try {
        final loginUri = Uri.parse('$baseUrl/api/v1/auth/login');
        final loginRes = await _activeClient!.post(
          loginUri,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'username': 'operator@bsas.local', 'password': 'Operator123!'},
        ).timeout(const Duration(seconds: 4));
        if (loginRes.statusCode == 200) {
          final data = jsonDecode(loginRes.body);
          authToken = data['access_token'];
        }
      } catch (_) {}
    }

    final chatUri = Uri.parse('$baseUrl/api/v1/ai/chat');
    final payload = {
      'message': userMessage,
      'conversation_id': 'bsas-session-${DateTime.now().millisecondsSinceEpoch}',
      if (safetyContext != null) 'telemetry': safetyContext.toJson(),
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (authToken != null && authToken!.isNotEmpty) 'Authorization': 'Bearer $authToken',
    };

    try {
      final response = await _activeClient!.post(
        chatUri,
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final reply = data['reply'] as String? ?? 'No response content returned.';
        final provider = data['provider'] as String? ?? 'BSAS AI';
        _activeModelName = provider;

        // Yield reply in natural chunks for smooth reading
        final words = reply.split(' ');
        for (int i = 0; i < words.length; i++) {
          if (_cancelled) break;
          yield (i == 0 ? '' : ' ') + words[i];
          await Future.delayed(const Duration(milliseconds: 18));
        }
      } else if (response.statusCode == 401) {
        yield '⚠️ [Authentication Required] Please sign in via the BSAS login screen to connect to the verified AI gateway.';
      } else {
        yield '⚠️ [Gateway Notice: ${response.statusCode}] Backend AI gateway returned an unexpected response. Checking local telemetry...';
      }
    } catch (e) {
      if (!_cancelled) {
        yield '⚠️ [Connection Issue] Could not reach the BSAS AI gateway at $baseUrl.\n'
            'Ensure the backend service is running on port 8000.';
      }
    } finally {
      _activeClient?.close();
      _activeClient = null;
    }
  }

  @override
  void cancel() {
    _cancelled = true;
    _activeClient?.close();
    _activeClient = null;
  }
}
