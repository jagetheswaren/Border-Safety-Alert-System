import 'dart:async';
import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_spacing.dart';
import '../core/theme/bsas_typography.dart';
import '../core/widgets/bsas_logo.dart';
import '../core/widgets/status_badge.dart';
import '../models/gps_snapshot.dart';
import '../models/geofence_result.dart';
import '../services/ai_provider.dart';
import '../services/chat_memory_service.dart';
import '../services/local_chat_service.dart';
import '../services/model_manager.dart';

/// Clean, modern BSAS AI Assistant.
///
/// Communicates genuine model state, offers real streaming with stop action,
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
  String? _lastError;
  String? _lastUserPrompt;
  StreamSubscription<String>? _streamSub;

  @override
  void initState() {
    super.initState();
    _initConversation();
    widget.modelManager.checkModelStatus();
    _refreshAiHealth();
  }

  Future<void> _refreshAiHealth() async {
    await widget.chatService.checkOllamaHealth();
    if (mounted) setState(() {});
  }

  Future<void> _initConversation() async {
    await widget.memoryService.initialize();
    if (widget.memoryService.conversations.isNotEmpty) {
      _currentConversationId = widget.memoryService.conversations.first.id;
      final saved = widget.memoryService.getMessages(_currentConversationId);
      setState(() => _activeMessages.addAll(saved));
    } else {
      _currentConversationId = await widget.memoryService.createConversation(
        title: 'Safety Session',
      );
      final isOllama = widget.chatService.isOllamaConnected;
      final isGguf = widget.modelManager.isModelLoaded;

      String welcomeText;
      if (isOllama) {
        welcomeText = 'BSAS AI connected locally via Ollama (${widget.chatService.aiProvider.modelName}). Real-time telemetry context is attached. How can I assist with your safety in this sector?';
      } else if (isGguf) {
        welcomeText = 'BSAS AI active via on-device Qwen3-0.6B GGUF. Local safety and boundary assistance ready.';
      } else {
        welcomeText = 'BSAS AI Assistant initialized. Local AI server is offline on development host; real-time sensor status and deterministic safety boundaries remain fully active.';
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
    _lastUserPrompt = query;
    _lastError = null;

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
              _lastError = null;
            });
            _scrollToBottom();
          }
        },
        onError: (err) {
          if (mounted) {
            setState(() {
              _lastError = err.toString();
              _streamingContent = '';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Generation error: $err'),
                backgroundColor: BsasColors.criticalRed,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastError = e.toString();
          _streamingContent = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inference error: $e'),
            backgroundColor: BsasColors.criticalRed,
          ),
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

  void _retryLast() {
    if (_lastUserPrompt != null) {
      _sendMessage(_lastUserPrompt!);
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

  String get _providerSubtitle {
    final isOllama = widget.chatService.isOllamaConnected;
    final modelName = widget.chatService.aiProvider.modelName;
    if (isOllama) {
      return '$modelName Local via Ollama';
    } else if (widget.modelManager.isModelLoaded) {
      return 'Qwen3 0.6B On-Device GGUF';
    } else {
      return 'Local AI Unavailable (Host Offline)';
    }
  }

  String get _statusLabel {
    final isGenerating = widget.chatService.isGenerating;
    final isOllama = widget.chatService.isOllamaConnected;
    final mm = widget.modelManager;

    if (isGenerating) return 'GENERATING';
    if (isOllama) return 'READY';
    if (mm.isModelLoaded) return 'READY';
    if (widget.chatService.aiProvider.status == AiProviderStatus.checking) {
      return 'CHECKING';
    }
    return 'OFFLINE';
  }

  StatusState get _statusState {
    if (widget.chatService.isGenerating) return StatusState.loading;
    if (widget.chatService.isOllamaConnected || widget.modelManager.isModelLoaded) {
      return StatusState.ready;
    }
    if (widget.chatService.aiProvider.status == AiProviderStatus.checking) {
      return StatusState.loading;
    }
    return StatusState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isGenerating = widget.chatService.isGenerating;

    return Scaffold(
      key: const Key('screen-ai-chat'),
      backgroundColor: BsasColors.background(isDark),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Navigation Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: BsasSpacing.lg,
                vertical: BsasSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: BsasColors.surface(isDark),
                border: Border(
                  bottom: BorderSide(color: BsasColors.border(isDark)),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const BsasLogo(size: 26, animated: false),
                      const SizedBox(width: BsasSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BSAS AI',
                              style: BsasTypography.heading.copyWith(
                                color: BsasColors.text(isDark),
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _providerSubtitle,
                              style: BsasTypography.caption.copyWith(
                                color: BsasColors.radarCyan,
                                fontSize: 11,
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
                      const SizedBox(width: BsasSpacing.xs),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        tooltip: 'Check Connection',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: isGenerating ? null : _refreshAiHealth,
                      ),
                      const SizedBox(width: BsasSpacing.sm),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        tooltip: 'Clear Chat',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: isGenerating ? null : _clearChat,
                      ),
                      const SizedBox(width: BsasSpacing.sm),
                      IconButton(
                        icon: const Icon(Icons.info_outline_rounded, size: 20),
                        tooltip: 'Diagnostics',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _showModelDiagnosticsDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: BsasSpacing.sm),
                  _buildSafetyContextPill(isDark),
                ],
              ),
            ),

            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: BsasSpacing.lg,
                  vertical: BsasSpacing.md,
                ),
                itemCount: _activeMessages.length +
                    (isGenerating ? 1 : 0) +
                    (_lastError != null ? 1 : 0),
                itemBuilder: (context, idx) {
                  if (idx < _activeMessages.length) {
                    return _buildMessageBubble(_activeMessages[idx], isDark);
                  }
                  if (isGenerating && idx == _activeMessages.length) {
                    return _buildStreamingBubble(isDark);
                  }
                  return _buildErrorCard(isDark);
                },
              ),
            ),

            // Prompt suggestions
            if (!isGenerating && _activeMessages.length <= 2)
              _buildPromptSuggestions(isDark),

            // Input bar
            _buildInputBar(context, isGenerating, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyContextPill(bool isDark) {
    final snapshot = _buildSnapshot();
    final riskColor = snapshot.riskState == 'CRITICAL'
        ? BsasColors.criticalRed
        : (snapshot.riskState == 'WARNING'
            ? BsasColors.warningOrange
            : (snapshot.riskState == 'CAUTION'
                ? BsasColors.cautionYellow
                : BsasColors.safeGreen));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.grey.shade100).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
        border: Border.all(color: BsasColors.border(isDark)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 14, color: riskColor),
          const SizedBox(width: BsasSpacing.xs),
          Expanded(
            child: Text(
              'TELEMETRY: ${snapshot.riskState} | GPS: ${snapshot.gpsAvailable ? "Locked" : "Acquiring"} | Zone: ${snapshot.zoneState}',
              style: BsasTypography.caption.copyWith(
                fontSize: 10,
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.w600,
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
          maxWidth: MediaQuery.of(context).size.width * 0.86,
        ),
        padding: const EdgeInsets.all(BsasSpacing.md),
        decoration: BoxDecoration(
          color: isUser
              ? (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE3F2FD))
              : BsasColors.surface(isDark),
          borderRadius: BorderRadius.circular(12).copyWith(
            bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(12),
            bottomLeft: isUser ? const Radius.circular(12) : const Radius.circular(2),
          ),
          border: Border.all(
            color: isUser
                ? (isDark ? const Color(0xFF2A558C) : const Color(0xFFBBDEFB))
                : BsasColors.border(isDark),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 6,
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
                  isUser ? Icons.person_outline : Icons.auto_awesome,
                  size: 13,
                  color: isUser ? (isDark ? Colors.white70 : BsasColors.primaryBlue) : BsasColors.radarCyan,
                ),
                const SizedBox(width: BsasSpacing.xs),
                Text(
                  isUser ? 'YOU' : 'BSAS AI',
                  style: BsasTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                    color: isUser ? (isDark ? Colors.white70 : BsasColors.primaryBlue) : BsasColors.radarCyan,
                  ),
                ),
                const Spacer(),
                Text(
                  timeStr,
                  style: BsasTypography.caption.copyWith(
                    fontSize: 10,
                    color: BsasColors.textSec(isDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BsasSpacing.sm),
            SelectableText(
              msg.content,
              style: BsasTypography.body.copyWith(
                color: BsasColors.text(isDark),
                fontSize: 13.5,
                height: 1.45,
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
          maxWidth: MediaQuery.of(context).size.width * 0.86,
        ),
        padding: const EdgeInsets.all(BsasSpacing.md),
        decoration: BoxDecoration(
          color: BsasColors.surface(isDark),
          borderRadius: BorderRadius.circular(12).copyWith(
            bottomLeft: const Radius.circular(2),
          ),
          border: Border.all(
            color: BsasColors.radarCyan.withValues(alpha: 0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: BsasColors.radarCyan.withValues(alpha: 0.1),
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
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: BsasColors.radarCyan,
                  ),
                ),
                const SizedBox(width: BsasSpacing.xs),
                Text(
                  'BSAS AI STREAMING...',
                  style: BsasTypography.caption.copyWith(
                    color: BsasColors.radarCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: BsasSpacing.sm),
            Text(
              _streamingContent.isEmpty ? 'Reading sensor telemetry...' : '$_streamingContent▌',
              style: BsasTypography.body.copyWith(
                color: BsasColors.text(isDark),
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: BsasSpacing.md),
      padding: const EdgeInsets.all(BsasSpacing.md),
      decoration: BoxDecoration(
        color: BsasColors.criticalRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BsasColors.criticalRed.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: BsasColors.criticalRed, size: 16),
              const SizedBox(width: BsasSpacing.xs),
              Text(
                'Local AI Service Alert',
                style: BsasTypography.title.copyWith(
                  color: BsasColors.criticalRed,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: BsasSpacing.xs),
          Text(
            _lastError ?? 'Connection error',
            style: BsasTypography.caption.copyWith(color: BsasColors.text(isDark)),
          ),
          const SizedBox(height: BsasSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _retryLast,
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text('Retry Prompt'),
                style: TextButton.styleFrom(
                  foregroundColor: BsasColors.criticalRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromptSuggestions(bool isDark) {
    final suggestions = [
      'Where am I right now?',
      'Explain my safety risk',
      'Nearest safe boundary distance?',
      'Evacuation protocol',
    ];

    return Container(
      height: 36,
      margin: const EdgeInsets.only(bottom: BsasSpacing.sm),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (context, index) => const SizedBox(width: BsasSpacing.sm),
        itemBuilder: (context, idx) {
          final prompt = suggestions[idx];
          return ActionChip(
            backgroundColor: BsasColors.surface(isDark),
            side: BorderSide(color: BsasColors.border(isDark)),
            label: Text(
              prompt,
              style: BsasTypography.caption.copyWith(
                fontSize: 11,
                color: BsasColors.text(isDark),
              ),
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
        horizontal: BsasSpacing.lg,
        vertical: BsasSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: BsasColors.surface(isDark),
        border: Border(
          top: BorderSide(color: BsasColors.border(isDark)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141922) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: BsasColors.border(isDark)),
                ),
                child: TextField(
                  controller: _controller,
                  enabled: !isGenerating,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _sendMessage,
                  style: BsasTypography.body.copyWith(
                    color: BsasColors.text(isDark),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: BsasColors.textSec(isDark),
                    ),
                    hintText: isGenerating
                        ? 'Synthesizing response...'
                        : 'Ask BSAS AI...',
                    hintStyle: BsasTypography.caption.copyWith(
                      color: BsasColors.textSec(isDark),
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
                height: 42,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BsasColors.criticalRed.withValues(alpha: 0.15),
                    foregroundColor: BsasColors.criticalRed,
                    side: const BorderSide(color: BsasColors.criticalRed),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  icon: const Icon(Icons.stop_rounded, size: 16),
                  label: const Text('Stop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: _stopGeneration,
                ),
              )
            else
              SizedBox(
                height: 42,
                width: 42,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: const CircleBorder(),
                  ),
                  icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showModelDiagnosticsDialog() {
    final isOllama = widget.chatService.isOllamaConnected;
    final modelName = widget.chatService.aiProvider.modelName;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('BSAS AI Subsystem Architecture', style: BsasTypography.heading),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _diagRow('Provider', isOllama ? 'Ollama Local Host' : 'On-Device GGUF'),
            _diagRow('Active Model', modelName),
            _diagRow('Ollama Endpoint', widget.chatService.activeBaseUrl),
            _diagRow('Connection Status', isOllama ? 'CONNECTED' : 'OFFLINE'),
            _diagRow('Safety Boundary', 'Read-Only Telemetry Isolation'),
            const SizedBox(height: BsasSpacing.sm),
            Text(
              isOllama
                  ? 'Active development path: streaming over Ollama REST API with Qwen model. Safety context is strictly read-only.'
                  : 'Ollama is currently unreachable on this host. Run "ollama serve" and ensure your device is connected.',
              style: BsasTypography.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('CONFIGURE HOST'),
            onPressed: () {
              Navigator.pop(ctx);
              _showConfigureHostDialog();
            },
          ),
          TextButton(
            child: const Text('CLOSE'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _showConfigureHostDialog() {
    final textController = TextEditingController(text: widget.chatService.activeBaseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configure Ollama Host', style: BsasTypography.heading),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the Ollama server URL (e.g., http://172.31.92.225:11434 for LAN or http://127.0.0.1:11434 for ADB reverse):',
              style: BsasTypography.caption,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                labelText: 'Host URL',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('CANCEL'),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('PROBE & SAVE'),
            onPressed: () {
              final newUrl = textController.text.trim();
              if (newUrl.isNotEmpty) {
                widget.chatService.updateOllamaBaseUrl(newUrl);
              }
              Navigator.pop(ctx);
              unawaited(_refreshAiHealth());
            },
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
          Text(label, style: BsasTypography.caption),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: BsasTypography.caption.copyWith(fontWeight: FontWeight.bold),
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
