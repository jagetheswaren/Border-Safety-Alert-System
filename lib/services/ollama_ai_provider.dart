import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'ai_provider.dart';
import 'local_chat_service.dart';
import 'safety_context_builder.dart';

class OllamaAiProvider implements AiProvider {
  OllamaAiProvider({
    String? baseUrl,
    String? modelName,
  })  : baseUrl = baseUrl ?? const String.fromEnvironment('BSAS_OLLAMA_HOST', defaultValue: 'http://127.0.0.1:11434'),
        _configuredModelName = modelName ?? const String.fromEnvironment('BSAS_OLLAMA_MODEL', defaultValue: 'qwen3:0.6b');

  String baseUrl;
  final String _configuredModelName;

  String _activeModelName = 'qwen3:0.6b';
  AiProviderStatus _status = AiProviderStatus.checking;
  HttpClientRequest? _activeRequest;
  bool _cancelled = false;

  void updateBaseUrl(String newUrl) {
    baseUrl = newUrl.trim();
  }

  @override
  String get providerName => 'Ollama Local Host';

  @override
  String get modelName => _activeModelName;

  @override
  AiProviderStatus get status => _status;

  @override
  Future<AiProviderStatus> checkHealth() async {
    _status = AiProviderStatus.checking;

    // Prioritized list of candidate endpoints to probe:
    // 1. Current configured baseUrl
    // 2. Local Wi-Fi LAN IP (for physical Android phone development)
    // 3. 127.0.0.1 (Desktop or ADB reverse)
    // 4. 10.0.2.2 (Android Emulator host bridge)
    final candidateHosts = {
      baseUrl,
      'http://172.31.92.225:11434',
      'http://127.0.0.1:11434',
      'http://10.0.2.2:11434',
    }.toList();

    for (final host in candidateHosts) {
      try {
        final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 2000);
        final req = await client.getUrl(Uri.parse('$host/api/tags'));
        final res = await req.close().timeout(const Duration(milliseconds: 3500));

        if (res.statusCode == 200) {
          final body = await res.transform(utf8.decoder).join();
          final data = jsonDecode(body) as Map<String, dynamic>;
          final models = (data['models'] as List<dynamic>?) ?? [];
          final modelNames = models.map((m) => (m['name'] as String? ?? '').toLowerCase()).toList();

          client.close();

          baseUrl = host; // Automatically adopt the verified working host

          final configLower = _configuredModelName.toLowerCase();
          if (modelNames.any((name) => name == configLower || name.startsWith(configLower.split(':').first))) {
            _activeModelName = _configuredModelName;
            _status = AiProviderStatus.ready;
          } else if (modelNames.isNotEmpty) {
            _activeModelName = models.first['name'] as String? ?? 'qwen3:0.6b';
            _status = AiProviderStatus.ready;
          } else {
            _status = AiProviderStatus.modelMissing;
          }
          return _status;
        }
        client.close();
      } catch (_) {
        // Continue probing next candidate host
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

    // Verify health / active model before streaming
    if (_status != AiProviderStatus.ready) {
      await checkHealth();
      if (_status != AiProviderStatus.ready) {
        if (_status == AiProviderStatus.offline) {
          throw const SocketException('Ollama service unreachable on development host. Ensure ollama serve is active.');
        } else if (_status == AiProviderStatus.modelMissing) {
          throw const HttpException('Configured AI model is not installed. Run "ollama pull qwen3:0.6b" in terminal.');
        } else {
          throw const HttpException('Ollama AI service encountered an error.');
        }
      }
    }

    final systemInstruction = SafetyContextBuilder.buildSystemPrompt(safetyContext);
    final payloadMessages = <Map<String, String>>[
      {'role': 'system', 'content': systemInstruction},
      ...messages,
    ];

    final requestBody = jsonEncode({
      'model': _activeModelName,
      'messages': payloadMessages,
      'stream': true,
      'options': {
        'temperature': 0.6,
        'num_predict': 512,
      },
    });

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final req = await client.postUrl(Uri.parse('$baseUrl/api/chat'));
      _activeRequest = req;
      req.headers.contentType = ContentType.json;
      req.write(requestBody);

      final res = await req.close();
      if (res.statusCode != 200) {
        final err = await res.transform(utf8.decoder).join();
        throw HttpException('Ollama chat HTTP ${res.statusCode}: $err');
      }

      await for (final line in res.transform(utf8.decoder).transform(const LineSplitter())) {
        if (_cancelled) break;
        if (line.trim().isEmpty) continue;

        try {
          final data = jsonDecode(line) as Map<String, dynamic>;
          final msg = data['message'] as Map<String, dynamic>?;
          final token = msg?['content'] as String? ?? '';
          if (token.isNotEmpty) {
            yield token;
          }
          final isDone = data['done'] as bool? ?? false;
          if (isDone) break;
        } catch (_) {
          // Continue if a chunk is malformed
        }
      }
    } finally {
      client.close(force: true);
      _activeRequest = null;
    }
  }

  @override
  void cancel() {
    _cancelled = true;
    _activeRequest?.abort();
    _activeRequest = null;
  }
}
