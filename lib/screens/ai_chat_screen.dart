import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_typography.dart';
import '../core/widgets/status_badge.dart';
import '../core/widgets/status_dot.dart';
import '../models/gps_snapshot.dart';
import '../models/geofence_result.dart';
import '../services/chat_memory_service.dart';
import '../services/local_chat_service.dart';
import '../services/model_manager.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({
    super.key,
    required this.chatService,
    required this.memoryService,
    required this.modelManager,
    this.gps,
    this.geoFence,
  });

  final LocalChatService chatService;
  final ChatMemoryService memoryService;
  final ModelManager modelManager;
  final GpsSnapshot? gps;
  final GeoFenceResult? geoFence;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _currentConversationId = '';
  final List<ChatMessageModel> _activeMessages = [];
  String _streamingContent = '';
  StreamSubscription<String>? _streamSub;

  @override
  void initState() {
    super.initState();
    _initConversation();
    widget.modelManager.checkModelStatus();
    widget.chatService.checkOllamaHealth().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initConversation() async {
    await widget.memoryService.initialize();
    if (widget.memoryService.conversations.isNotEmpty) {
      _currentConversationId = widget.memoryService.conversations.first.id;
      final saved = widget.memoryService.getMessages(_currentConversationId);
      setState(() => _activeMessages.addAll(saved));
    } else {
      _currentConversationId = await widget.memoryService.createConversation(
        title: 'Initial Safety Inquiry',
      );
      // Welcome assistant message
      final isOllama = widget.chatService.isOllamaConnected;
      final welcome = ChatMessageModel(
        id: 'msg_welcome',
        conversationId: _currentConversationId,
        role: 'assistant',
        content: isOllama
            ? 'Hello! I am the BSAS Safety Assistant connected to local GPU Ollama (Qwen2.5-0.5B). I can explain your telemetry, geofence status, and field guidance. How can I assist you?'
            : 'Hello. I am the BSAS Local Safety Assistant, running entirely on-device via Qwen3-0.6B GGUF. How can I help you today?',
        timestamp: DateTime.now(),
      );
      await widget.memoryService.addMessage(welcome);
      setState(() => _activeMessages.add(welcome));
    }
  }

  SafetyContextSnapshot _buildSnapshot() {
    final fix = widget.gps?.location;
    return SafetyContextSnapshot(
      gpsAvailable: fix != null,
      latitude: fix?.latitude,
      longitude: fix?.longitude,
      accuracyM: fix?.accuracy,
      speedMps: fix?.speed,
      bearingDeg: fix?.bearing,
      zoneState: widget.geoFence?.state.name.toUpperCase() ?? 'SAFE',
      riskState: widget.geoFence?.state.name.toUpperCase() ?? 'SAFE',
      activeAlertCount: 0,
      isOffline: true,
    );
  }

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    _controller.clear();
    final userMsg = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _currentConversationId,
      role: 'user',
      content: query,
      timestamp: DateTime.now(),
    );

    setState(() {
      _activeMessages.add(userMsg);
      _streamingContent = '';
    });
    await widget.memoryService.addMessage(userMsg);
    _scrollToBottom();

    final snapshot = _buildSnapshot();
    final buffer = StringBuffer();

    try {
      final stream = widget.chatService.generateResponseStream(
        userPrompt: query,
        contextSnapshot: snapshot,
      );

      _streamSub = stream.listen(
        (token) {
          buffer.write(token);
          setState(() => _streamingContent = buffer.toString());
          _scrollToBottom();
        },
        onDone: () async {
          final aiMsg = ChatMessageModel(
            id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
            conversationId: _currentConversationId,
            role: 'assistant',
            content: buffer.toString(),
            timestamp: DateTime.now(),
          );
          await widget.memoryService.addMessage(aiMsg);
          if (mounted) {
            setState(() {
              _activeMessages.add(aiMsg);
              _streamingContent = '';
            });
            _scrollToBottom();
          }
        },
        onError: (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Generation error: $e')),
            );
            setState(() => _streamingContent = '');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inference error: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOllama = widget.chatService.isOllamaConnected;
    return Scaffold(
      backgroundColor: BsasColors.darkBackground,
      appBar: AppBar(
        backgroundColor: BsasColors.darkSurface,
        title: Row(
          children: [
            StatusDot(
              state: isOllama ? StatusState.ready : StatusState.loading,
              size: 8,
            ),
            const SizedBox(width: 8),
            const Text('BSAS LOCAL AI', style: BsasTypography.headline),
          ],
        ),
        actions: [
          StatusBadge(
            label: isOllama ? 'OLLAMA GPU' : 'OFFLINE GGUF',
            state: StatusState.ready,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) async {
              if (val == 'clear') {
                await widget.memoryService.clearHistory();
                setState(() => _activeMessages.clear());
              } else if (val == 'diagnostics') {
                _showDiagnosticsModal();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'diagnostics', child: Text('Model Diagnostics')),
              PopupMenuItem(value: 'clear', child: Text('Clear History')),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.modelManager,
        builder: (context, _) {
          final state = widget.modelManager.state;

          if (state == ModelState.notInstalled) {
            return _buildFirstRunInstall();
          }

          if (state == ModelState.loading && !widget.modelManager.isModelLoaded) {
            return _buildLoadingModel();
          }

          return Column(
            children: [
              // 1. Current Safety Status Banner (Read-only)
              _buildSafetySummaryCard(),

              // 2. Quick Action Chips
              _buildQuickActionChips(),

              // 3. Conversation Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _activeMessages.length + (_streamingContent.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, idx) {
                    if (idx < _activeMessages.length) {
                      return _buildMessageBubble(_activeMessages[idx]);
                    } else {
                      return _buildStreamingBubble(_streamingContent);
                    }
                  },
                ),
              ),

              // 4. Privacy Footer
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                alignment: Alignment.center,
                child: Text(
                  '🔒 Local AI • Conversations stay private on this device',
                  style: BsasTypography.caption.copyWith(fontSize: 11, color: BsasColors.textMuted),
                ),
              ),

              // 5. Input Bar
              _buildInputBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFirstRunInstall() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.psychology_outlined, size: 64, color: BsasColors.radarCyan),
            const SizedBox(height: 16),
            const Text('Local AI Not Installed Yet', style: BsasTypography.title),
            const SizedBox(height: 8),
            const Text(
              'Model: Qwen3-0.6B Q4_0 (~429 MB)\nRuns 100% locally on this Samsung Galaxy A12s with zero internet required.',
              textAlign: TextAlign.center,
              style: BsasTypography.body,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: BsasColors.radarCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.download_for_offline),
              label: const Text('Install Local AI Model'),
              onPressed: () => widget.modelManager.installLocalModel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingModel() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: BsasColors.radarCyan),
          const SizedBox(height: 16),
          const Text('INITIALIZING LOCAL AI', style: BsasTypography.headline),
          const SizedBox(height: 8),
          Text(
            'Allocating context memory & starting Qwen3 engine...',
            style: BsasTypography.caption.copyWith(color: BsasColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetySummaryCard() {
    final fix = widget.gps?.location;
    final state = widget.geoFence?.state.name.toUpperCase() ?? 'SAFE';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BsasColors.darkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BsasColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: state == 'SAFE' ? BsasColors.safeGreen : BsasColors.warningOrange,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              state,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fix != null
                  ? 'GPS: ${fix.latitude.toStringAsFixed(4)}, ${fix.longitude.toStringAsFixed(4)} (±${fix.accuracy?.toStringAsFixed(0) ?? "15"}m)'
                  : 'GPS: Searching satellite fix...',
              style: BsasTypography.monoDiagnostics.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _actionChip('Explain Status', 'Why am I safe? Explain my current status.'),
          _actionChip('Explain Zone', 'Explain my current geofence zone and boundary conditions.'),
          _actionChip('Summarize Alerts', 'Summarize active safety alerts.'),
          _actionChip('System Health', 'Explain system health and diagnostics.'),
        ],
      ),
    );
  }

  Widget _actionChip(String label, String prompt) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12, color: BsasColors.textPrimary)),
        backgroundColor: BsasColors.darkCard,
        side: const BorderSide(color: BsasColors.darkBorder),
        onPressed: () => _sendMessage(prompt),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg) {
    final isUser = msg.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: isUser ? BsasColors.radarCyan.withValues(alpha: 0.18) : BsasColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUser ? BsasColors.radarCyan.withValues(alpha: 0.4) : BsasColors.darkBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person_outline : Icons.smart_toy_outlined,
                  size: 14,
                  color: isUser ? BsasColors.radarCyan : BsasColors.safeGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  isUser ? 'You' : 'BSAS Local AI',
                  style: BsasTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isUser ? BsasColors.radarCyan : BsasColors.safeGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(msg.content, style: BsasTypography.body),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${msg.timestamp.hour.toString().padLeft(2, "0")}:${msg.timestamp.minute.toString().padLeft(2, "0")}',
                  style: BsasTypography.caption.copyWith(fontSize: 10, color: BsasColors.textMuted),
                ),
                if (!isUser)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 14, color: BsasColors.textMuted),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: msg.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamingBubble(String content) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: BsasColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BsasColors.radarCyan.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.smart_toy_outlined, size: 14, color: BsasColors.safeGreen),
                SizedBox(width: 6),
                Text('BSAS Local AI (generating...)', style: TextStyle(color: BsasColors.safeGreen, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 6),
            Text('$content ▌', style: BsasTypography.body),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: BsasColors.darkSurface,
        border: Border(top: BorderSide(color: BsasColors.darkBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Ask the local safety AI...',
                hintStyle: TextStyle(color: BsasColors.textMuted),
                border: InputBorder.none,
              ),
              onSubmitted: (val) => _sendMessage(val),
            ),
          ),
          if (widget.chatService.isGenerating)
            IconButton(
              icon: const Icon(Icons.stop_circle, color: BsasColors.criticalRed),
              onPressed: () => widget.chatService.cancelGeneration(),
            )
          else
            IconButton(
              icon: const Icon(Icons.send, color: BsasColors.radarCyan),
              onPressed: () => _sendMessage(_controller.text),
            ),
        ],
      ),
    );
  }

  void _showDiagnosticsModal() {
    final diag = widget.modelManager.diagnostics;
    showModalBottomSheet(
      context: context,
      backgroundColor: BsasColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('LOCAL AI DIAGNOSTICS', style: BsasTypography.headline),
              const Divider(color: BsasColors.darkBorder),
              _diagRow('MODEL', diag.modelName),
              _diagRow('FORMAT', diag.format),
              _diagRow('ENGINE', diag.engine),
              _diagRow('DEVICE', diag.device),
              _diagRow('STATUS', diag.status),
              _diagRow('LOAD TIME', '${diag.loadTimeMs} ms'),
              _diagRow('TOKENS / SEC', '${diag.tokensPerSecond.toStringAsFixed(1)} tok/s'),
              _diagRow('RAM ALLOCATED', '${diag.allocatedRamMb.toStringAsFixed(1)} MB'),
              _diagRow('CONTEXT WINDOW', '${diag.contextTokens} tokens'),
              _diagRow('OFFLINE MODE', diag.isOffline ? 'YES (Verified)' : 'NO'),
            ],
          ),
        );
      },
    );
  }

  Widget _diagRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: BsasTypography.caption.copyWith(color: BsasColors.textSecondary)),
          Text(value, style: BsasTypography.monoDiagnostics.copyWith(fontSize: 13, color: Colors.white)),
        ],
      ),
    );
  }
}
