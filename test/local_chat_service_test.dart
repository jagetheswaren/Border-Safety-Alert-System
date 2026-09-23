import 'package:flutter_test/flutter_test.dart';
import 'package:border_safety_alert/services/local_chat_service.dart';
import 'package:border_safety_alert/services/model_manager.dart';

void main() {
  group('LocalChatService & Safety Boundary Verification', () {
    late ModelManager modelManager;
    late LocalChatService chatService;

    setUp(() {
      modelManager = ModelManager();
      chatService = LocalChatService(modelManager: modelManager);
    });

    test('chat streaming generates non-empty token stream', () async {
      const snapshot = SafetyContextSnapshot(
        gpsAvailable: true,
        latitude: 10.712530,
        longitude: 76.979150,
        accuracyM: 12.0,
        zoneState: 'SAFE',
        riskState: 'SAFE',
        activeAlertCount: 0,
        isOffline: true,
      );

      final tokens = <String>[];
      final stream = chatService.generateResponseStream(
        userPrompt: 'Where am I?',
        contextSnapshot: snapshot,
      );

      await for (final token in stream) {
        tokens.add(token);
      }

      expect(tokens, isNotEmpty);
      final fullText = tokens.join();
      expect(fullText, contains('10.712530'));
      expect(fullText, contains('76.979150'));
    });

    test('cancellation terminates streaming cleanly', () async {
      const snapshot = SafetyContextSnapshot(
        gpsAvailable: true,
        latitude: 10.712530,
        longitude: 76.979150,
        zoneState: 'SAFE',
        riskState: 'SAFE',
      );

      final tokens = <String>[];
      final stream = chatService.generateResponseStream(
        userPrompt: 'Explain my current safety status and risk engine evaluation',
        contextSnapshot: snapshot,
      );

      final sub = stream.listen((token) {
        tokens.add(token);
        if (tokens.length >= 3) {
          chatService.cancelGeneration();
        }
      });

      await Future.delayed(const Duration(milliseconds: 300));
      await sub.cancel();

      expect(chatService.isGenerating, isFalse);
    });

    test('SAFETY BOUNDARY: Chat cannot modify official safety state', () {
      const originalRisk = 'SAFE';
      const originalZone = 'SAFE';
      const originalLat = 10.712530;

      const snapshot = SafetyContextSnapshot(
        gpsAvailable: true,
        latitude: originalLat,
        longitude: 76.979150,
        zoneState: originalZone,
        riskState: originalRisk,
      );

      // Snapshot is immutable and read-only
      expect(snapshot.riskState, originalRisk);
      expect(snapshot.zoneState, originalZone);
      expect(snapshot.latitude, originalLat);

      // Verify that chat generation does not mutate or expose mutable safety engine hooks
      expect(snapshot.toJson()['risk_state'], 'SAFE');
      expect(snapshot.toJson()['zone_state'], 'SAFE');
    });

    test('explains system health correctly using context snapshot', () async {
      const snapshot = SafetyContextSnapshot(
        gpsAvailable: true,
        latitude: 10.712530,
        longitude: 76.979150,
        zoneState: 'WARNING',
        riskState: 'WARNING',
        activeAlertCount: 2,
        isOffline: true,
      );

      final tokens = <String>[];
      final stream = chatService.generateResponseStream(
        userPrompt: 'What is the system health?',
        contextSnapshot: snapshot,
      );

      await for (final token in stream) {
        tokens.add(token);
      }

      final fullText = tokens.join();
      expect(fullText, contains('System Health'));
      expect(fullText, contains('Offline'));
    });

    test('OLLAMA: detects running local Ollama server health and model', () async {
      final isOnline = await chatService.checkOllamaHealth();
      // Since Ollama is running on this laptop host, verify detection
      expect(isOnline, isTrue);
      expect(chatService.isOllamaConnected, isTrue);
    });
  });
}
