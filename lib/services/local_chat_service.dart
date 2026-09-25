import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'model_manager.dart';
import 'native_gguf_runtime.dart';

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
  onDeviceGguf,
}

/// Service handling local AI interactions for BSAS.
///
/// Architecture:
/// - Development mode (Laptop): Real Ollama neural streaming over localhost:11434.
/// - Production mode (Android): Native on-device Qwen3-0.6B GGUF inference via llama.cpp.
/// - Absolute Rule: NO fake keyword engine, NO canned responses, NO simulated delays.
///   If neither runtime is available, yields an honest diagnostic error.
class LocalChatService extends ChangeNotifier {
  LocalChatService({
    required this.modelManager,
    NativeGgufRuntime? nativeRuntime,
    this.ollamaBaseUrl = 'http://127.0.0.1:11434',
    this.ollamaModel = 'qwen2.5:0.5b',
    this.backendMode = ChatBackendMode.auto,
  }) : nativeRuntime = nativeRuntime ?? NativeGgufRuntime();

  final ModelManager modelManager;
  final NativeGgufRuntime nativeRuntime;
  final String ollamaBaseUrl;
  final String ollamaModel;
  ChatBackendMode backendMode;

  bool _isGenerating = false;
  Completer<void>? _cancelCompleter;
  bool _isOllamaConnected = false;

  bool get isGenerating => _isGenerating;
  bool get isOllamaConnected => _isOllamaConnected;

  static const String systemPrompt = '''
You are the BSAS Local Safety Assistant. You are an offline conversational assistant running locally on-device.
Your responsibilities:
- Explain BSAS official status
- Explain GPS status and coordinates
- Explain geofence boundary conditions
- Summarize alerts and system diagnostics
- Answer general field-safety questions
Important rules:
- You are not the safety decision engine.
- Never override BSAS's official risk or geofence state.
- Never invent GPS coordinates.
- Never invent alerts or incidents.
- Never claim emergency services were contacted unless confirmed.
- When data is unavailable, clearly state it is unavailable.
- Work completely offline without cloud dependencies.
''';

  Future<bool> checkOllamaHealth() async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 700);
      final req = await client.getUrl(Uri.parse('$ollamaBaseUrl/api/tags'));
      final res = await req.close().timeout(const Duration(milliseconds: 1200));
      _isOllamaConnected = res.statusCode == 200;
      client.close();
    } catch (_) {
      _isOllamaConnected = false;
    }
    notifyListeners();
    return _isOllamaConnected;
  }

  void cancelGeneration() {
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
      // 1. Laptop Development Path: check for active Ollama server
      bool tryOllama = backendMode == ChatBackendMode.ollama || backendMode == ChatBackendMode.auto;
      if (tryOllama) {
        final available = await checkOllamaHealth();
        if (available) {
          bool streamedAny = false;
          try {
            await for (final token in _streamOllama(userPrompt, contextSnapshot)) {
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

  Stream<String> _streamOllama(String userPrompt, SafetyContextSnapshot ctx) async* {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    final req = await client.postUrl(Uri.parse('$ollamaBaseUrl/api/generate'));
    req.headers.contentType = ContentType.json;

    final contextString = '''
[CURRENT SENSOR & SAFETY CONTEXT]
Official Risk State: ${ctx.riskState}
Geofence State: ${ctx.zoneState}
GPS Available: ${ctx.gpsAvailable}
Coordinates: ${ctx.latitude?.toStringAsFixed(6) ?? "N/A"}, ${ctx.longitude?.toStringAsFixed(6) ?? "N/A"}
Accuracy: ±${ctx.accuracyM?.toStringAsFixed(1) ?? "N/A"} m
Speed: ${ctx.speedMps != null ? "${(ctx.speedMps! * 3.6).toStringAsFixed(1)} km/h" : "N/A"}
Bearing: ${ctx.bearingDeg != null ? "${ctx.bearingDeg!.toStringAsFixed(0)}°" : "N/A"}
Active Alerts: ${ctx.activeAlertCount}
Offline Mode: ${ctx.isOffline}
''';

    final body = jsonEncode({
      'model': ollamaModel,
      'prompt': '$contextString\nUser Query: $userPrompt\nAssistant:',
      'system': systemPrompt,
      'stream': true,
      'options': {
        'temperature': 0.3,
        'num_predict': 180,
      }
    });

    req.write(body);
    final res = await req.close();
    if (res.statusCode != 200) {
      client.close();
      throw HttpException('Ollama HTTP error ${res.statusCode}');
    }

    final lines = res.transform(utf8.decoder).transform(const LineSplitter());
    await for (final line in lines) {
      if (_cancelCompleter != null && _cancelCompleter!.isCompleted) {
        break;
      }
      if (line.trim().isEmpty) continue;
      try {
        final data = jsonDecode(line) as Map<String, dynamic>;
        final token = data['response'] as String? ?? '';
        if (token.isNotEmpty) {
          yield token;
        }
        if (data['done'] == true) break;
      } catch (_) {}
    }
    client.close();
  }

  String _buildPrompt(String userPrompt, SafetyContextSnapshot ctx) {
    return '''
System: $systemPrompt
Context:
Official Risk State: ${ctx.riskState}
Geofence State: ${ctx.zoneState}
GPS Available: ${ctx.gpsAvailable}
Coordinates: ${ctx.latitude?.toStringAsFixed(6) ?? "N/A"}, ${ctx.longitude?.toStringAsFixed(6) ?? "N/A"}
Active Alerts: ${ctx.activeAlertCount}
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
        '• Laptop Dev Mode: Ollama server not detected at $ollamaBaseUrl\n\n'
        '🛡️ Current Authoritative Telemetry (from Risk Engine & GPS):\n'
        '• Official State: ${ctx.riskState}\n'
        '• Geofence Zone: ${ctx.zoneState}\n'
        '• GNSS Coordinates: $lat° N, $lon° E\n'
        '• Active Alerts: ${ctx.activeAlertCount}\n\n'
        'Notice: In strict compliance with BSAS safety standards, simulated keyword responses are disabled. Install the model package to activate full local conversational intelligence.';
  }
}
