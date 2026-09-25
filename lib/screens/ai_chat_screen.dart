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
      backgroundColor: isDark ? BsasColors.darkBackground : BsasColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Unified Tactical Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: BsasSpacing.screenMargin,
                vertical: BsasSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isDark ? BsasColors.darkSurface : BsasColors.lightSurface,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const BsasLogo(size: 24, animated: false),
                      const SizedBox(width: BsasSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LOCAL AI TERMINAL',
                              style: BsasTypography.caption.copyWith(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Air-Gapped Field Assistant',
                              style: BsasTypography.caption.copyWith(
                                color: BsasColors.radarCyan,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: _statusLabel,
                        state: _statusState,
                        isPulsing: isGenerating,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 22),
                        tooltip: 'Clear Session',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: isGenerating ? null : _clearChat,
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.data_object, size: 22),
                        tooltip: 'Model Diagnostics',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _showModelDiagnosticsDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: BsasSpacing.sm),
                  _buildSensorTicker(context),
                ],
              ),
            ),

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
    ));
  }

  Widget _buildSensorTicker(BuildContext context) {
    final snapshot = _buildSnapshot();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.sm, vertical: BsasSpacing.xs),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: BsasColors.darkBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.cable, size: 14, color: BsasColors.warningOrange),
          const SizedBox(width: BsasSpacing.xs),
          Expanded(
            child: Text(
              'ATTACHED CONTEXT: ${snapshot.riskState} | GPS: ${snapshot.gpsAvailable ? "LOCKED" : "NONE"} | ZONE: ${snapshot.zoneState}',
              style: BsasTypography.monoDiagnostics.copyWith(
                fontSize: 10,
                color: BsasColors.warningOrange,
                fontWeight: FontWeight.bold,
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
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        padding: const EdgeInsets.all(BsasSpacing.md),
        decoration: BoxDecoration(
          color: isUser
              ? BsasColors.darkSurface
              : (isDark ? BsasColors.darkCard : BsasColors.lightCard),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isUser
                ? BsasColors.safeGreen.withValues(alpha: 0.5)
                : BsasColors.radarCyan.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isUser ? BsasColors.safeGreen : BsasColors.radarCyan).withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person_outline : Icons.memory,
                  size: 14,
                  color: isUser ? BsasColors.safeGreen : BsasColors.radarCyan,
                ),
                const SizedBox(width: BsasSpacing.xs),
                Text(
                  isUser ? 'FIELD OPERATOR' : 'SYS.AI',
                  style: BsasTypography.monoDiagnostics.copyWith(
                    color: isUser ? BsasColors.safeGreen : BsasColors.radarCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                Text(
                  timeStr,
                  style: BsasTypography.monoDiagnostics.copyWith(
                    fontSize: 10,
                    color: isDark ? BsasColors.textLightMuted : BsasColors.textDarkMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: BsasSpacing.sm),
            Text(
              msg.content,
              style: isUser 
                  ? BsasTypography.body.copyWith(color: Colors.white, height: 1.4)
                  : BsasTypography.monoDiagnostics.copyWith(
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.5,
                      fontSize: 13,
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
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        padding: const EdgeInsets.all(BsasSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? BsasColors.darkCard : BsasColors.lightCard,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: BsasColors.radarCyan.withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: BsasColors.radarCyan.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 0),
            ),
          ],
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: BsasColors.radarCyan),
                ),
                const SizedBox(width: BsasSpacing.xs),
                Text(
                  'SYS.AI :: SYNTHESIZING RESPONSE...',
                  style: BsasTypography.monoDiagnostics.copyWith(
                    color: BsasColors.radarCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: BsasSpacing.sm),
            Text(
              _streamingContent.isEmpty ? 'Reading context snapshot...' : '$_streamingContent█',
              style: BsasTypography.monoDiagnostics.copyWith(
                color: isDark ? Colors.white : Colors.black87,
                height: 1.5,
                fontSize: 13,
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
      'System health?',
      'Evacuation steps',
    ];

    return Container(
      height: 32,
      margin: const EdgeInsets.only(bottom: BsasSpacing.sm),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.screenMargin),
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (context, index) => const SizedBox(width: BsasSpacing.sm),
        itemBuilder: (context, idx) {
          final prompt = suggestions[idx];
          return ActionChip(
            backgroundColor: BsasColors.darkSurface.withValues(alpha: 0.5),
            side: const BorderSide(color: BsasColors.darkBorder),
            label: Text(
              prompt, 
              style: BsasTypography.monoDiagnostics.copyWith(fontSize: 10, color: Colors.white70),
            ),
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
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder),
                ),
                child: TextField(
                  controller: _controller,
                  enabled: !isGenerating,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _sendMessage,
                  style: BsasTypography.monoDiagnostics.copyWith(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.terminal,
                      size: 16,
                      color: isGenerating ? BsasColors.textLightMuted : BsasColors.safeGreen,
                    ),
                    hintText: isGenerating
                        ? 'Processing request...'
                        : 'Enter query parameter...',
                    hintStyle: BsasTypography.monoDiagnostics.copyWith(
                      color: BsasColors.textLightMuted,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: BsasSpacing.sm),
            if (isGenerating)
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BsasColors.criticalRed.withValues(alpha: 0.2),
                    foregroundColor: BsasColors.criticalRed,
                    side: const BorderSide(color: BsasColors.criticalRed),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.md),
                  ),
                  icon: const Icon(Icons.stop_circle_outlined, size: 16),
                  label: Text('HALT', style: BsasTypography.monoDiagnostics.copyWith(fontWeight: FontWeight.bold)),
                  onPressed: _stopGeneration,
                ),
              )
            else
              SizedBox(
                height: 44,
                width: 44,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: BsasColors.safeGreen.withValues(alpha: 0.2),
                    foregroundColor: BsasColors.safeGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: const BorderSide(color: BsasColors.safeGreen),
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  onPressed: () => _sendMessage(_controller.text),
                ),
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
