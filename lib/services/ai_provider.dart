import 'local_chat_service.dart';

enum AiProviderStatus {
  checking,
  connected,
  ready,
  offline,
  modelMissing,
  error,
}

abstract class AiProvider {
  String get providerName;
  String get modelName;
  AiProviderStatus get status;

  Future<AiProviderStatus> checkHealth();

  Stream<String> generateChatStream({
    required List<Map<String, String>> messages,
    SafetyContextSnapshot? safetyContext,
  });

  void cancel();
}
