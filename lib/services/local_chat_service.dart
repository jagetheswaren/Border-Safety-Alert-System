import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ai_provider.dart';
import 'backend_ai_provider.dart';
import 'model_manager.dart';
import 'native_gguf_runtime.dart';
import 'ollama_ai_provider.dart';
import 'safety_context_builder.dart';

/// Immutable read-only sensor and safety context snapshot provided to the AI.
///
/// Under the BSAS Safety Isolation Boundary, the AI has zero mutable access
/// to the RiskEngine, GPS hardware, AlertService, or Geofencing subsystem.
class SafetyContextSnapshot {
  const SafetyContextSnapshot({
    this.gpsAvailable = false,
    this.latitude,
    this.longitude,
    this.accuracyM,
    this.speedMps,
    this.bearingDeg,
    this.zoneState = 'SAFE',
    this.riskState = 'SAFE',
    this.activeAlertCount = 0,
    this.isOffline = true,
  });

  final bool gpsAvailable;
  final double? latitude;
  final double? longitude;
  final double? accuracyM;
  final double? speedMps;
  final double? bearingDeg;
  final String zoneState;
  final String riskState;
  final int activeAlertCount;
  final bool isOffline;

  Map<String, dynamic> toJson() => {
        'gps_available': gpsAvailable,
        'latitude': latitude,
        'longitude': longitude,
        'gps_accuracy_m': accuracyM,
        'speed_mps': speedMps,
        'bearing_deg': bearingDeg,
        'zone_state': zoneState,
        'risk_state': riskState,
        'active_alert_count': activeAlertCount,
        'is_offline': isOffline,
      };
}

enum ChatBackendMode {
  auto,
  ollama,
  backendGateway,
  onDeviceGguf,
}

/// Service handling AI interactions for BSAS.
///
/// Architecture:
/// - Online Gateway Mode: Authenticated FastAPI AI Gateway (/api/v1/ai/chat) with Gemini / OpenAI / DB Grounding.
/// - Development mode (Laptop/LAN): Real Ollama neural streaming over localhost:11434.
/// - Production mode (Android): Native on-device Qwen3-0.6B GGUF inference via llama.cpp.
/// - Absolute Rule: NO fake keyword engine, NO canned responses, NO simulated delays.
///   If neither runtime is available, yields an honest diagnostic error.
class LocalChatService extends ChangeNotifier {
  LocalChatService({
    required this.modelManager,
    NativeGgufRuntime? nativeRuntime,
    AiProvider? aiProvider,
    BackendAiProvider? backendAiProvider,
    this.ollamaBaseUrl = 'http://127.0.0.1:11434',
    this.ollamaModel = 'qwen3:0.6b',
    this.backendMode = ChatBackendMode.auto,
  })  : nativeRuntime = nativeRuntime ?? NativeGgufRuntime(),
        backendAiProvider = backendAiProvider ?? BackendAiProvider(),
        aiProvider = aiProvider ??
            OllamaAiProvider(
              baseUrl: ollamaBaseUrl,
              modelName: ollamaModel,
            );

  final ModelManager modelManager;
  final NativeGgufRuntime nativeRuntime;
  final AiProvider aiProvider;
  final BackendAiProvider backendAiProvider;
  final String ollamaBaseUrl;
  final String ollamaModel;
  ChatBackendMode backendMode;

  bool _isGenerating = false;
  Completer<void>? _cancelCompleter;
  bool _isOllamaConnected = false;
  bool _isGatewayConnected = false;

  bool get isGenerating => _isGenerating;
  bool get isOllamaConnected => _isOllamaConnected;
  bool get isGatewayConnected => _isGatewayConnected;
  String get activeBaseUrl => (aiProvider is OllamaAiProvider) ? (aiProvider as OllamaAiProvider).baseUrl : ollamaBaseUrl;

  void updateOllamaBaseUrl(String newUrl) {
    if (aiProvider is OllamaAiProvider) {
      (aiProvider as OllamaAiProvider).updateBaseUrl(newUrl);
    }
    unawaited(checkOllamaHealth());
  }

  Future<bool> checkGatewayHealth() async {
    try {
      final status = await backendAiProvider.checkHealth();
      _isGatewayConnected = status == AiProviderStatus.ready;
    } catch (_) {
      _isGatewayConnected = false;
    }
    notifyListeners();
    return _isGatewayConnected;
  }

  Future<bool> checkOllamaHealth() async {
    try {
      final status = await aiProvider.checkHealth();
      _isOllamaConnected = status == AiProviderStatus.ready;
    } catch (_) {
      _isOllamaConnected = false;
    }
    notifyListeners();
    return _isOllamaConnected;
  }

  void cancelGeneration() {
    aiProvider.cancel();
    backendAiProvider.cancel();
    if (_isGenerating && _cancelCompleter != null && !_cancelCompleter!.isCompleted) {
      _cancelCompleter!.complete();
    }
    _isGenerating = false;
    modelManager.setGenerating(false);
    notifyListeners();
  }

  Stream<String> generateResponseStream({
    required String userPrompt,
    required SafetyContextSnapshot contextSnapshot,
  }) async* {
    if (_isGenerating) {
      throw StateError('Inference already in progress. Only one generation at a time.');
    }

    _isGenerating = true;
    modelManager.setGenerating(true);
    _cancelCompleter = Completer<void>();
    notifyListeners();

    try {
      // 1. FastAPI AI Gateway Path (Backend Online Mode)
      bool tryGateway = backendMode == ChatBackendMode.backendGateway || backendMode == ChatBackendMode.auto;
      if (tryGateway) {
        final gatewayAvailable = await checkGatewayHealth();
        if (gatewayAvailable) {
          bool streamedAny = false;
          try {
            await for (final token in backendAiProvider.generateChatStream(
              messages: [
                {'role': 'user', 'content': userPrompt}
              ],
              safetyContext: contextSnapshot,
            )) {
              if (_cancelCompleter != null && _cancelCompleter!.isCompleted) break;
              streamedAny = true;
              yield token;
            }
          } catch (_) {
            streamedAny = false;
          }
          if (streamedAny) return;
        }
      }

      // 2. Laptop Development Path: check for active Ollama server
      bool tryOllama = backendMode == ChatBackendMode.ollama || backendMode == ChatBackendMode.auto;
      if (tryOllama) {
        final available = await checkOllamaHealth();
        if (available) {
          bool streamedAny = false;
          try {
            await for (final token in aiProvider.generateChatStream(
              messages: [
                {'role': 'user', 'content': userPrompt}
              ],
              safetyContext: contextSnapshot,
            )) {
              if (_cancelCompleter != null && _cancelCompleter!.isCompleted) {
                break;
              }
              streamedAny = true;
              yield token;
            }
          } catch (_) {
            streamedAny = false;
          }
          if (streamedAny) return;
        }
      }

      // 2. Android On-Device GGUF Path: Native llama.cpp inference
      await nativeRuntime.loadNativeLibrary();

      if (!modelManager.isModelLoaded) {
        try {
          await modelManager.loadModel();
        } catch (_) {}
      }

      if (modelManager.isModelLoaded && nativeRuntime.isAvailable) {
        // Native model is loaded and native library is bound
        final promptWithContext = _buildPrompt(userPrompt, contextSnapshot);
        final path = await modelManager.modelFilePath;
        await for (final token in nativeRuntime.generateTokens(
          modelPath: path,
          prompt: promptWithContext,
        )) {
          if (_cancelCompleter != null && _cancelCompleter!.isCompleted) break;
          yield token;
        }
        return;
      }

      // 3. Honest Status: Neither Ollama nor Native GGUF is available
      // Strictly NO fake keyword responses or artificial delays.
      yield _buildUnavailableNotice(contextSnapshot);

    } finally {
      _isGenerating = false;
      modelManager.setGenerating(false);
      notifyListeners();
    }
  }

  String _buildPrompt(String userPrompt, SafetyContextSnapshot ctx) {
    final systemPrompt = SafetyContextBuilder.buildSystemPrompt(ctx);
    return '''
System: $systemPrompt

User: $userPrompt
Assistant:''';
  }

  String _buildUnavailableNotice(SafetyContextSnapshot ctx) {
    final modelState = modelManager.state.name.toUpperCase();
    final modelDiag = modelManager.diagnostics.status;
    final lat = ctx.latitude?.toStringAsFixed(6) ?? 'N/A';
    final lon = ctx.longitude?.toStringAsFixed(6) ?? 'N/A';

    return '⚠️ [BSAS LOCAL AI: NOT_CONFIGURED]\n\n'
        'On-device neural inference requires the Qwen3 GGUF model and native runtime:\n'
        '• Model File: Qwen3-0.6B-Q4_0.gguf (~429 MB)\n'
        '• Model State: $modelState ($modelDiag)\n'
        '• Native Runtime: llama.cpp (${nativeRuntime.unavailableReason ?? "libllama.so missing"})\n'
        '• Laptop Dev Mode: Ollama server not detected at $activeBaseUrl\n\n'
        '🛡️ Current Authoritative Telemetry (from Risk Engine & GPS):\n'
        '• Official State: ${ctx.riskState}\n'
        '• Geofence Zone: ${ctx.zoneState}\n'
        '• GNSS Coordinates: $lat° N, $lon° E\n'
        '• Active Alerts: ${ctx.activeAlertCount}\n\n'
        'Notice: In strict compliance with BSAS safety standards, simulated keyword responses are disabled. Install the model package to activate full local conversational intelligence.';
  }
}
