import 'dart:async';
import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_spacing.dart';
import '../core/theme/bsas_typography.dart';
import '../core/widgets/bsas_logo.dart';
import '../core/widgets/status_badge.dart';
import '../models/gps_snapshot.dart';
import '../models/geofence_result.dart';
import '../services/chat_memory_service.dart';
import '../services/local_chat_service.dart';
import '../services/model_manager.dart';

/// Redesigned dedicated BSAS Field AI Assistant.
///
/// Designed with an original civilian safety identity (NOT a ChatGPT clone).
/// Strictly communicates genuine model state, offers real streaming with stop action,
/// and operates within the read-only safety snapshot isolation boundary.
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
        title: 'Field Safety Session',
      );
      final isOllama = widget.chatService.isOllamaConnected;
      final isGguf = widget.modelManager.isModelLoaded;

      String welcomeText;
      if (isGguf) {
        welcomeText = 'BSAS Field AI Assistant active (On-Device Qwen3-0.6B). I can explain your sensor telemetry, boundary conditions, and evacuation protocols.';
      } else if (isOllama) {
        welcomeText = 'BSAS Field AI Assistant connected to local GPU Ollama (Qwen2.5-0.5B). Ready for civilian safety inquiries.';
      } else {
        welcomeText = 'BSAS Field AI Assistant initialized. The on-device Qwen3 model is pending installation; sensor status and deterministic telemetry explanations remain available.';
      }

      final welcome = ChatMessageModel(
        id: 'msg_welcome',
        conversationId: _currentConversationId,
        role: 'assistant',
        content: welcomeText,
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
        onError: (err) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Generation error: $err')),
            );
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

  void _stopGeneration() {
    _streamSub?.cancel();
    widget.chatService.cancelGeneration();
    if (_streamingContent.isNotEmpty) {
      final partialMsg = ChatMessageModel(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: _currentConversationId,
        role: 'assistant',
        content: '$_streamingContent [Generation Stopped]',
        timestamp: DateTime.now(),
      );
      widget.memoryService.addMessage(partialMsg);
      setState(() {
        _activeMessages.add(partialMsg);
        _streamingContent = '';
      });
    }
  }

  void _clearChat() async {
    await widget.memoryService.clearMessages(_currentConversationId);
    setState(() => _activeMessages.clear());
    await _initConversation();
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

  String get _statusLabel {
    final mm = widget.modelManager;
    final isOllama = widget.chatService.isOllamaConnected;
    if (widget.chatService.isGenerating) return 'GENERATING';
    if (isOllama) return 'OLLAMA READY';
    if (mm.isModelLoaded) return 'LOCAL AI READY';
    switch (mm.state) {
      case ModelState.checking:
        return 'CHECKING';
      case ModelState.loading:
        return 'LOADING';
      case ModelState.verifying:
        return 'VERIFYING';
      case ModelState.error:
        return 'AI ERROR';
      case ModelState.corrupted:
        return 'CORRUPTED';
      case ModelState.notInstalled:
      default:
        return 'MODEL NOT FOUND';
    }
  }

  StatusState get _statusState {
    final mm = widget.modelManager;
    final isOllama = widget.chatService.isOllamaConnected;
    if (widget.chatService.isGenerating) return StatusState.loading;
    if (isOllama || mm.isModelLoaded) return StatusState.ready;
    if (mm.state == ModelState.error || mm.state == ModelState.corrupted) return StatusState.critical;
    return StatusState.warning;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isGenerating = widget.chatService.isGenerating;

    return Scaffold(
      key: const Key('screen-ai-chat'),
      appBar: AppBar(
        title: Row(
          children: [
            const BsasLogo(size: 22, animated: false),
            const SizedBox(width: BsasSpacing.sm),
            Text('Field Assistant', style: BsasTypography.heading.copyWith(fontSize: 16)),
          ],
        ),
        actions: [
          StatusBadge(
            label: _statusLabel,
            state: _statusState,
            isPulsing: isGenerating,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, size: 20),
            tooltip: 'Clear Conversation',
            onPressed: isGenerating ? null : _clearChat,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, size: 20),
            tooltip: 'Model Information',
            onPressed: _showModelDiagnosticsDialog,
          ),
          const SizedBox(width: BsasSpacing.xs),
        ],
      ),
      body: Column(
        children: [
          // Authoritative Sensor Snapshot Strip
          _buildSensorTicker(context),

          // Conversation Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: BsasSpacing.screenMargin,
                vertical: BsasSpacing.md,
              ),
              itemCount: _activeMessages.length + (isGenerating ? 1 : 0),
              itemBuilder: (context, idx) {
                if (idx < _activeMessages.length) {
                  return _buildMessageBubble(_activeMessages[idx], isDark);
                }
                return _buildStreamingBubble(isDark);
              },
            ),
          ),

          // Suggested Prompts (when inactive)
          if (!isGenerating && _activeMessages.length <= 2)
            _buildPromptSuggestions(),

          // Input / Stop Controls
          _buildInputBar(context, isGenerating, isDark),
        ],
      ),
    );
  }

  Widget _buildSensorTicker(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final snapshot = _buildSnapshot();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.screenMargin, vertical: BsasSpacing.xs),
      decoration: BoxDecoration(
        color: isDark ? BsasColors.darkSurface : BsasColors.lightBorderSubtle,
        border: Border(
          bottom: BorderSide(
            color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.sensors, size: 14, color: BsasColors.primaryBlue),
          const SizedBox(width: BsasSpacing.xs),
          Expanded(
            child: Text(
              'Read-Only Sensor Snapshot: ${snapshot.riskState} • GPS: ${snapshot.gpsAvailable ? "Active" : "None"} • Zone: ${snapshot.zoneState} • Offline Mode',
              style: BsasTypography.caption.copyWith(
                fontSize: 11,
                color: isDark ? BsasColors.textLightSecondary : BsasColors.textDarkSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg, bool isDark) {
    final isUser = msg.role == 'user';
    final timeStr =
        '${msg.timestamp.hour.toString().padLeft(2, "0")}:${msg.timestamp.minute.toString().padLeft(2, "0")}';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: BsasSpacing.md),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.all(BsasSpacing.md),
        decoration: BoxDecoration(
          color: isUser
              ? BsasColors.primaryBlue
              : (isDark ? BsasColors.darkCard : BsasColors.lightCard),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(BsasSpacing.cardRadius),
            topRight: const Radius.circular(BsasSpacing.cardRadius),
            bottomLeft: Radius.circular(isUser ? BsasSpacing.cardRadius : 2),
            bottomRight: Radius.circular(isUser ? 2 : BsasSpacing.cardRadius),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder,
                  width: 1,
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BsasLogo(size: 14, animated: false),
                  const SizedBox(width: BsasSpacing.xs),
                  Text(
                    'BSAS AI',
                    style: BsasTypography.caption.copyWith(
                      color: BsasColors.primaryBlueLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BsasSpacing.xs),
            ],
            Text(
              msg.content,
              style: BsasTypography.body.copyWith(
                color: isUser
                    ? Colors.white
                    : (isDark ? BsasColors.textLightPrimary : BsasColors.textDarkPrimary),
                height: 1.4,
              ),
            ),
            const SizedBox(height: BsasSpacing.xs),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                timeStr,
                style: BsasTypography.caption.copyWith(
                  fontSize: 10,
                  color: isUser
                      ? Colors.white70
                      : (isDark ? BsasColors.textLightMuted : BsasColors.textDarkMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamingBubble(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: BsasSpacing.md),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.all(BsasSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? BsasColors.darkCard : BsasColors.lightCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(BsasSpacing.cardRadius),
            topRight: Radius.circular(BsasSpacing.cardRadius),
            bottomRight: Radius.circular(BsasSpacing.cardRadius),
          ),
          border: Border.all(
            color: BsasColors.primaryBlue.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: BsasColors.primaryBlue),
                ),
                const SizedBox(width: BsasSpacing.xs),
                Text(
                  'GENERATING ADVISORY...',
                  style: BsasTypography.caption.copyWith(
                    color: BsasColors.primaryBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: BsasSpacing.xs),
            Text(
              _streamingContent.isEmpty ? 'Processing context snapshot...' : _streamingContent,
              style: BsasTypography.body.copyWith(
                color: isDark ? BsasColors.textLightPrimary : BsasColors.textDarkPrimary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptSuggestions() {
    final suggestions = [
      'Where am I?',
      'Explain my safety status',
      'What is the system health?',
      'Emergency evacuation steps',
    ];

    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: BsasSpacing.xs),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.screenMargin),
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (context, index) => const SizedBox(width: BsasSpacing.sm),
        itemBuilder: (context, idx) {
          final prompt = suggestions[idx];
          return ActionChip(
            label: Text(prompt, style: const TextStyle(fontSize: 11)),
            onPressed: () => _sendMessage(prompt),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, bool isGenerating, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BsasSpacing.screenMargin,
        vertical: BsasSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? BsasColors.darkSurface : BsasColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !isGenerating,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                decoration: InputDecoration(
                  hintText: isGenerating
                      ? 'AI response generating...'
                      : 'Ask field safety question...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: BsasSpacing.md,
                    vertical: BsasSpacing.sm,
                  ),
                ),
              ),
            ),
            const SizedBox(width: BsasSpacing.sm),
            if (isGenerating)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BsasColors.criticalRed,
                  padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.md),
                  minimumSize: const Size(64, 42),
                ),
                onPressed: _stopGeneration,
                child: const Text('STOP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              )
            else
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: BsasColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                onPressed: () => _sendMessage(_controller.text),
              ),
          ],
        ),
      ),
    );
  }

  void _showModelDiagnosticsDialog() {
    final mm = widget.modelManager;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Local AI Architecture', style: BsasTypography.heading),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _diagRow('Model Target', ModelManager.modelFilename),
            _diagRow('Target SHA-256', '${ModelManager.expectedSha256.substring(0, 16)}...'),
            _diagRow('Runtime State', mm.state.name.toUpperCase()),
            _diagRow('Ollama Bridge', widget.chatService.isOllamaConnected ? 'Connected (GPU)' : 'Offline'),
            _diagRow('Safety Mode', 'Read-Only Context (Deterministic Isolated)'),
            const SizedBox(height: BsasSpacing.sm),
            Text(
              'Offline GGUF model must be located at models/qwen/ to run inference with zero network connectivity.',
              style: BsasTypography.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('CLOSE'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Widget _diagRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: BsasTypography.bodyMuted),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: BsasTypography.monoDiagnostics.copyWith(fontSize: 11),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
