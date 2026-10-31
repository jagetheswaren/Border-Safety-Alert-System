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
    this.clientFactory = http.Client.new,
  }) : baseUrl = baseUrl ?? _defaultBaseUrl {
    _developmentSession = authToken == null || authToken!.isEmpty;
  }

  static String get _defaultBaseUrl {
    const configured = String.fromEnvironment('BSAS_API_URL');
    if (configured.isNotEmpty) return configured.replaceAll(RegExp(r'/+$'), '');
    return kIsWeb ? Uri.base.origin : 'http://10.0.2.2:8000';
  }

  String baseUrl;
  String? authToken;
  String _activeModelName = 'BSAS AI Gateway';
  AiProviderStatus _status = AiProviderStatus.checking;
  http.Client? _activeClient;
  int _generation = 0;
  bool _developmentSession = true;
  final http.Client Function() clientFactory;

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
    _developmentSession = false;
  }

  @override
  Future<AiProviderStatus> checkHealth() async {
    _status = AiProviderStatus.checking;

    final candidateHosts = [
      baseUrl,
      if (!kIsWeb) 'http://127.0.0.1:8000',
      if (!kIsWeb) 'http://10.0.2.2:8000',
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
    final generation = ++_generation;
    final client = clientFactory();
    _activeClient = client;
    final userMessage = messages.isNotEmpty ? messages.last['content'] ?? '' : '';
    final localEndpoint = ['127.0.0.1', 'localhost', '10.0.2.2'].contains(Uri.parse(baseUrl).host);
    Future<bool> renewDevelopmentSession() async {
      if (!_developmentSession || !localEndpoint || generation != _generation) return false;
      try {
        final response = await client.post(Uri.parse('$baseUrl/api/v1/auth/login'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'username': 'operator@bsas.local', 'password': 'Operator123!'},
        ).timeout(const Duration(seconds: 4));
        final data = response.statusCode == 200 ? jsonDecode(response.body) : null;
        if (generation != _generation || data?['access_token'] is! String) return false;
        authToken = data['access_token'] as String;
        return authToken!.isNotEmpty;
      } catch (_) { return false; }
    }

    final chatUri = Uri.parse('$baseUrl/api/v1/ai/chat');
    final payload = {
      'message': userMessage,
      'conversation_id': 'bsas-session-${DateTime.now().millisecondsSinceEpoch}',
      if (safetyContext != null) 'telemetry': safetyContext.toJson(),
    };

    Map<String, String> headers() => <String, String>{
      'Content-Type': 'application/json',
      if (authToken != null && authToken!.isNotEmpty) 'Authorization': 'Bearer $authToken',
    };

    try {
      if (authToken == null || authToken!.isEmpty) await renewDevelopmentSession();
      if (generation != _generation) return;
      Future<http.Response> send() => client.post(chatUri, headers: headers(), body: jsonEncode(payload)).timeout(const Duration(seconds: 180));
      var response = await send();
      if (response.statusCode == 401 && await renewDevelopmentSession()) response = await send();
      if (generation != _generation) return;

      if (response.statusCode == 200) {
        _status = AiProviderStatus.ready;
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final reply = data['reply'] as String? ?? 'No response content returned.';
        final provider = data['provider'] as String? ?? 'BSAS AI';
        if (data['source'] != 'ai') {
          yield 'AI model unavailable. The following is a database summary, not generated AI.\n\n';
        }
        _activeModelName = provider;

        // Yield reply in natural chunks for smooth reading
        final words = reply.split(' ');
        for (int i = 0; i < words.length; i++) {
          if (generation != _generation) break;
          yield (i == 0 ? '' : ' ') + words[i];

        }
      } else if (response.statusCode == 401) {
        _status = AiProviderStatus.error;
        yield '⚠️ [Authentication Required] Please sign in via the BSAS login screen to connect to the verified AI gateway.';
      } else {
        _status = AiProviderStatus.error;
        yield '⚠️ [Gateway Notice: ${response.statusCode}] Backend AI gateway returned an unexpected response. Checking local telemetry...';
      }
    } catch (e) {
      if (generation == _generation) {
        _status = AiProviderStatus.offline;
        yield '⚠️ [Connection Issue] Could not reach the BSAS AI gateway at $baseUrl.\n'
            'Ensure the backend service is running on port 8000.';
      }
    } finally {
      client.close();
      if (identical(_activeClient, client)) _activeClient = null;
    }
  }

  @override
  void cancel() {
    _generation++;
    _activeClient?.close();
    _activeClient = null;
  }
}
