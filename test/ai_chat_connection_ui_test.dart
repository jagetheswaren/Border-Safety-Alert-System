import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:border_safety_alert/screens/ai_chat_screen.dart';
import 'package:border_safety_alert/services/ai_provider.dart';
import 'package:border_safety_alert/services/backend_ai_provider.dart';
import 'package:border_safety_alert/services/local_chat_service.dart';
import 'package:border_safety_alert/services/model_manager.dart';
import 'package:border_safety_alert/services/chat_memory_service.dart';

class OfflineGateway extends BackendAiProvider {
  @override AiProviderStatus get status => AiProviderStatus.offline;
  @override Future<AiProviderStatus> checkHealth() async => AiProviderStatus.offline;
}
class OfflineProvider implements AiProvider {
  @override String get modelName => 'offline';
  @override String get providerName => 'offline';
  @override AiProviderStatus get status => AiProviderStatus.offline;
  @override Future<AiProviderStatus> checkHealth() async => AiProviderStatus.offline;
  @override void cancel() {}
  @override Stream<String> generateChatStream({required List<Map<String,String>> messages,SafetyContextSnapshot? safetyContext}) => const Stream.empty();
}
class IdleModels extends ModelManager {
  @override Future<void> checkModelStatus() async {}
}
void main() {
  testWidgets('offline AI is labelled OFFLINE and narrow header does not overflow', (tester) async {
    tester.view.physicalSize = const Size(360,800); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final models = IdleModels();
    final chat = LocalChatService(modelManager:models,backendAiProvider:OfflineGateway(),aiProvider:OfflineProvider());
    await tester.pumpWidget(MaterialApp(home:AiChatScreen(chatService:chat,memoryService:ChatMemoryService(),modelManager:models)));
    await tester.pumpAndSettle();
    expect(find.text('OFFLINE'),findsOneWidget);
    expect(find.text('READY'),findsNothing);
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
