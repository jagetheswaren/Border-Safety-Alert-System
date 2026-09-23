import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.model = 'Qwen3-0.6B-Q4_0',
  });

  final String id;
  final String conversationId;
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  final DateTime timestamp;
  final String model;

  Map<String, dynamic> toMap() => {
        'id': id,
        'conversation_id': conversationId,
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'model': model,
      };

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) => ChatMessageModel(
        id: map['id'] as String,
        conversationId: map['conversation_id'] as String,
        role: map['role'] as String,
        content: map['content'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        model: (map['model'] ?? 'Qwen3-0.6B-Q4_0') as String,
      );
}

class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.title,
    required this.updatedAt,
    this.messageCount = 0,
  });

  final String id;
  final String title;
  final DateTime updatedAt;
  final int messageCount;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'updated_at': updatedAt.toIso8601String(),
        'message_count': messageCount,
      };

  factory ConversationSummary.fromMap(Map<String, dynamic> map) =>
      ConversationSummary(
        id: map['id'] as String,
        title: map['title'] as String,
        updatedAt: DateTime.parse(map['updated_at'] as String),
        messageCount: (map['message_count'] ?? 0) as int,
      );
}

class ChatMemoryService extends ChangeNotifier {
  ChatMemoryService({this.historyEnabled = true});

  bool historyEnabled;
  final Map<String, List<ChatMessageModel>> _conversations = {};
  final List<ConversationSummary> _summaries = [];
  bool _initialized = false;
  File? _storageFile;

  bool get isInitialized => _initialized;
  List<ConversationSummary> get conversations => List.unmodifiable(_summaries);

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _storageFile = File('${dir.path}/chat_history.json');
      if (await _storageFile!.exists()) {
        final text = await _storageFile!.readAsString();
        final data = jsonDecode(text) as Map<String, dynamic>;
        final convList = data['conversations'] as List<dynamic>? ?? [];
        _summaries.clear();
        for (final item in convList) {
          _summaries.add(ConversationSummary.fromMap(item as Map<String, dynamic>));
        }

        final msgMap = data['messages'] as Map<String, dynamic>? ?? {};
        _conversations.clear();
        msgMap.forEach((convId, msgs) {
          _conversations[convId] = (msgs as List<dynamic>)
              .map((m) => ChatMessageModel.fromMap(m as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {
      // Initialize with empty memory
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    if (!historyEnabled || _storageFile == null) return;
    try {
      final data = {
        'conversations': _summaries.map((s) => s.toMap()).toList(),
        'messages': _conversations.map((k, v) => MapEntry(k, v.map((m) => m.toMap()).toList())),
      };
      await _storageFile!.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  Future<String> createConversation({String title = 'Safety Inquiry'}) async {
    final id = 'conv_${DateTime.now().millisecondsSinceEpoch}';
    final summary = ConversationSummary(
      id: id,
      title: title,
      updatedAt: DateTime.now(),
      messageCount: 0,
    );
    _summaries.insert(0, summary);
    _conversations[id] = [];
    await _persist();
    notifyListeners();
    return id;
  }

  List<ChatMessageModel> getMessages(String conversationId) {
    return List.unmodifiable(_conversations[conversationId] ?? []);
  }

  Future<void> addMessage(ChatMessageModel message) async {
    if (!historyEnabled) return;
    final list = _conversations.putIfAbsent(message.conversationId, () => []);
    list.add(message);

    final idx = _summaries.indexWhere((s) => s.id == message.conversationId);
    if (idx != -1) {
      final old = _summaries[idx];
      _summaries[idx] = ConversationSummary(
        id: old.id,
        title: old.title,
        updatedAt: DateTime.now(),
        messageCount: list.length,
      );
    } else {
      _summaries.insert(
        0,
        ConversationSummary(
          id: message.conversationId,
          title: 'Safety Chat',
          updatedAt: DateTime.now(),
          messageCount: list.length,
        ),
      );
    }

    await _persist();
    notifyListeners();
  }

  Future<void> renameConversation(String conversationId, String newTitle) async {
    final idx = _summaries.indexWhere((s) => s.id == conversationId);
    if (idx != -1) {
      final old = _summaries[idx];
      _summaries[idx] = ConversationSummary(
        id: old.id,
        title: newTitle,
        updatedAt: DateTime.now(),
        messageCount: old.messageCount,
      );
      await _persist();
      notifyListeners();
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    _conversations.remove(conversationId);
    _summaries.removeWhere((s) => s.id == conversationId);
    await _persist();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _conversations.clear();
    _summaries.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> clearMessages(String conversationId) async {
    _conversations[conversationId] = [];
    final idx = _summaries.indexWhere((s) => s.id == conversationId);
    if (idx != -1) {
      final old = _summaries[idx];
      _summaries[idx] = ConversationSummary(
        id: old.id,
        title: old.title,
        updatedAt: DateTime.now(),
        messageCount: 0,
      );
    }
    await _persist();
    notifyListeners();
  }

  List<ChatMessageModel> searchMessages(String query) {
    final q = query.toLowerCase();
    final results = <ChatMessageModel>[];
    for (final messages in _conversations.values) {
      for (final msg in messages) {
        if (msg.content.toLowerCase().contains(q)) {
          results.add(msg);
        }
      }
    }
    return results;
  }
}
