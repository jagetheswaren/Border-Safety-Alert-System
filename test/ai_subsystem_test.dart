import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:border_safety_alert/services/ai_provider.dart';
import 'package:border_safety_alert/services/local_chat_service.dart';
import 'package:border_safety_alert/services/model_manager.dart';
import 'package:border_safety_alert/services/ollama_ai_provider.dart';
import 'package:border_safety_alert/services/safety_context_builder.dart';

class MockAiProvider implements AiProvider {
  MockAiProvider({
    this.initialStatus = AiProviderStatus.ready,
    this.tokensToStream = const ['Safe ', 'transit ', 'corridor ', 'confirmed.'],
    this.shouldThrow = false,
  });

  AiProviderStatus initialStatus;
  final List<String> tokensToStream;
  final bool shouldThrow;
  bool wasCancelled = false;

  @override
  String get providerName => 'Mock Ollama Provider';

  @override
  String get modelName => 'qwen3:0.6b';

  @override
  AiProviderStatus get status => initialStatus;

  @override
  Future<AiProviderStatus> checkHealth() async {
    return initialStatus;
  }

  @override
  Stream<String> generateChatStream({
    required List<Map<String, String>> messages,
    SafetyContextSnapshot? safetyContext,
  }) async* {
    if (shouldThrow) {
      throw const SystemException('Simulated provider connection timeout');
    }
    for (final token in tokensToStream) {
      if (wasCancelled) break;
      yield token;
    }
  }

  @override
  void cancel() {
    wasCancelled = true;
  }
}

class SystemException implements Exception {
  final String message;
  const SystemException(this.message);
  @override
  String toString() => message;
}

void main() {
  group('AI Subsystem - Architecture & Safety Context Tests', () {
    test('SafetyContextBuilder constructs authoritative read-only prompt with telemetry', () {
      const snapshot = SafetyContextSnapshot(
        gpsAvailable: true,
        latitude: 10.523456,
        longitude: 76.891234,
        accuracyM: 4.5,
        speedMps: 2.5,
        bearingDeg: 180.0,
        zoneState: 'CAUTION',
        riskState: 'CAUTION',
        activeAlertCount: 2,
        isOffline: true,
      );

      final prompt = SafetyContextBuilder.buildSystemPrompt(snapshot);

      expect(prompt, contains('BSAS Local Safety Assistant'));
      expect(prompt, contains('READ-ONLY AUTHORITATIVE TELEMETRY SNAPSHOT'));
      expect(prompt, contains('10.523456'));
      expect(prompt, contains('76.891234'));
      expect(prompt, contains('4.5 meters'));
      expect(prompt, contains('9.0 km/h')); // 2.5 * 3.6
      expect(prompt, contains('180°'));
      expect(prompt, contains('CAUTION'));
      expect(prompt, contains('ACTIVE INCIDENT ALERTS: 2'));
      expect(prompt, contains('Never invent GPS coordinates'));
      expect(prompt, contains('advisory only'));
    });

    test('SafetyContextBuilder handles missing GPS lock honestly without fake coordinates', () {
      const snapshot = SafetyContextSnapshot(
        gpsAvailable: false,
        latitude: null,
        longitude: null,
        accuracyM: null,
        zoneState: 'UNKNOWN',
        riskState: 'UNKNOWN',
        activeAlertCount: 0,
        isOffline: true,
      );

      final prompt = SafetyContextBuilder.buildSystemPrompt(snapshot);

      expect(prompt, contains('GNSS FIX: Not acquired / Constellation searching'));
      expect(prompt, contains('GPS AVAILABLE: false'));
      expect(prompt, isNot(contains('10.7'))); // Must not invent fallback coordinates
    });

    test('OllamaAiProvider initializes with default environment config', () {
      final provider = OllamaAiProvider();
      expect(provider.providerName, 'Ollama Local Host');
      expect(provider.baseUrl, 'http://127.0.0.1:11434');
      expect(provider.modelName, 'qwen3:0.6b');
    });

    test('LocalChatService delegates chat generation to AiProvider stream', () async {
      final mockProvider = MockAiProvider(
        tokensToStream: ['Sector ', 'is ', 'secure.'],
      );
      final modelManager = ModelManager();
      final chatService = LocalChatService(
        modelManager: modelManager,
        aiProvider: mockProvider,
        backendMode: ChatBackendMode.ollama,
      );

      const snapshot = SafetyContextSnapshot(
        gpsAvailable: true,
        latitude: 10.7,
        longitude: 76.9,
        zoneState: 'SAFE',
        riskState: 'SAFE',
      );

      final stream = chatService.generateResponseStream(
        userPrompt: 'Is this area safe?',
        contextSnapshot: snapshot,
      );

      final receivedTokens = await stream.toList();
      expect(receivedTokens, ['Sector ', 'is ', 'secure.']);
    });

    test('LocalChatService propagates cancellation to active AiProvider', () async {
      final mockProvider = MockAiProvider(
        tokensToStream: ['Token1 ', 'Token2 ', 'Token3 ', 'Token4 '],
      );
      final modelManager = ModelManager();
      final chatService = LocalChatService(
        modelManager: modelManager,
        aiProvider: mockProvider,
        backendMode: ChatBackendMode.ollama,
      );

      const snapshot = SafetyContextSnapshot(gpsAvailable: true);

      final stream = chatService.generateResponseStream(
        userPrompt: 'Test prompt',
        contextSnapshot: snapshot,
      );

      final completer = Completer<void>();
      final tokens = <String>[];

      stream.listen((token) {
        tokens.add(token);
        if (tokens.length == 2) {
          chatService.cancelGeneration();
          completer.complete();
        }
      });

      await completer.future;
      expect(mockProvider.wasCancelled, isTrue);
      expect(chatService.isGenerating, isFalse);
    });

    test('LocalChatService yields honest unavailable notice when all backends offline', () async {
      final mockProvider = MockAiProvider(
        initialStatus: AiProviderStatus.offline,
      );
      final modelManager = ModelManager();
      final chatService = LocalChatService(
        modelManager: modelManager,
        aiProvider: mockProvider,
        backendMode: ChatBackendMode.ollama,
      );

      const snapshot = SafetyContextSnapshot(
        gpsAvailable: true,
        latitude: 10.712530,
        longitude: 76.979150,
        zoneState: 'SAFE',
        riskState: 'SAFE',
      );

      final stream = chatService.generateResponseStream(
        userPrompt: 'Hello',
        contextSnapshot: snapshot,
      );

      final response = (await stream.toList()).join();
      expect(response, contains('BSAS LOCAL AI: NOT_CONFIGURED'));
      expect(response, contains('Official State: SAFE'));
      expect(response, contains('10.712530'));
      expect(response, contains('simulated keyword responses are disabled'));
    });
  });
}
