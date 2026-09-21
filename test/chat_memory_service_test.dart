import 'package:flutter_test/flutter_test.dart';
import 'package:border_safety_alert/services/chat_memory_service.dart';

void main() {
  group('ChatMemoryService', () {
    late ChatMemoryService memoryService;

    setUp(() {
      memoryService = ChatMemoryService(historyEnabled: true);
    });

    test('initial state is empty', () {
      expect(memoryService.conversations, isEmpty);
    });

    test('creates conversation, adds messages, and retrieves history', () async {
      final convId = await memoryService.createConversation(title: 'Patrol 1 Chat');
      expect(memoryService.conversations.length, 1);
      expect(memoryService.conversations.first.id, convId);
      expect(memoryService.conversations.first.title, 'Patrol 1 Chat');

      final msg1 = ChatMessageModel(
        id: 'm1',
        conversationId: convId,
        role: 'user',
        content: 'Why is the risk level warning?',
        timestamp: DateTime.now(),
      );
      await memoryService.addMessage(msg1);

      final msg2 = ChatMessageModel(
        id: 'm2',
        conversationId: convId,
        role: 'assistant',
        content: 'You are within 250m of Sector 7 restricted perimeter.',
        timestamp: DateTime.now(),
      );
      await memoryService.addMessage(msg2);

      final messages = memoryService.getMessages(convId);
      expect(messages.length, 2);
      expect(messages[0].content, 'Why is the risk level warning?');
      expect(messages[1].role, 'assistant');
    });

    test('searches messages across conversations', () async {
      final convId = await memoryService.createConversation(title: 'Search Test');
      await memoryService.addMessage(
        ChatMessageModel(
          id: 'm_search',
          conversationId: convId,
          role: 'user',
          content: 'Where are the GPS coordinates located?',
          timestamp: DateTime.now(),
        ),
      );

      final results = memoryService.searchMessages('coordinates');
      expect(results.length, 1);
      expect(results.first.id, 'm_search');

      final emptyResults = memoryService.searchMessages('nonexistent_word');
      expect(emptyResults, isEmpty);
    });

    test('renames and deletes conversation', () async {
      final convId = await memoryService.createConversation(title: 'Old Title');
      await memoryService.renameConversation(convId, 'New Title');
      expect(memoryService.conversations.first.title, 'New Title');

      await memoryService.deleteConversation(convId);
      expect(memoryService.conversations, isEmpty);
      expect(memoryService.getMessages(convId), isEmpty);
    });

    test('clears all history', () async {
      final c1 = await memoryService.createConversation(title: 'Chat 1');
      final c2 = await memoryService.createConversation(title: 'Chat 2');
      expect(memoryService.conversations.length, 2);

      await memoryService.clearHistory();
      expect(memoryService.conversations, isEmpty);
      expect(memoryService.getMessages(c1), isEmpty);
      expect(memoryService.getMessages(c2), isEmpty);
    });
  });
}
