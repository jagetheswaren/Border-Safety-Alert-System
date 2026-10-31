import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/geofence_result.dart';
import '../models/gps_snapshot.dart';
import '../models/safety_state.dart';
import 'gis_layer_service.dart';
import 'local_chat_service.dart';
import 'offline_map_service.dart';
import 'sos_service.dart';
import 'voice_alert_service.dart';

class AiOrchestrator extends ChangeNotifier {
  AiOrchestrator({
    required this.chatService,
    required this.voiceService,
    this.gisLayerService,
    this.sosService,
    this.offlineMapService,
  });

  final LocalChatService chatService;
  final VoiceAlertService voiceService;
  final GisLayerService? gisLayerService;
  final SosService? sosService;
  final OfflineMapService? offlineMapService;

  bool _voiceResponseEnabled = false;
  bool get voiceResponseEnabled => _voiceResponseEnabled;

  void setVoiceResponseEnabled(bool enabled) {
    _voiceResponseEnabled = enabled;
    notifyListeners();
  }

  /// Builds complete live application context across all modules
  SafetyContextSnapshot buildGlobalContext({
    required GpsSnapshot gps,
    required GeoFenceResult geoFence,
    int activeAlertCount = 0,
  }) {
    final location = gps.location;
    final nearest = geoFence.nearestBoundary;

    // Check SOS status
    final hasActiveSos = sosService?.hasActiveEmergency ?? false;

    return SafetyContextSnapshot(
      gpsAvailable: gps.location != null && gps.fix == GpsFixState.locked,
      latitude: location?.latitude,
      longitude: location?.longitude,
      accuracyM: location?.accuracy,
      speedMps: location?.speed,
      bearingDeg: location?.bearing,
      zoneState: nearest != null ? '${nearest.name} (${nearest.riskLevel.name.toUpperCase()})' : 'NO_CONFIGURED_ZONE',
      riskState: hasActiveSos ? 'EMERGENCY_SOS' : geoFence.state.name.toUpperCase(),
      activeAlertCount: activeAlertCount,
      isOffline: true,
      nearestBoundaryName: nearest?.name,
      distanceToBoundaryM: geoFence.distanceToBoundaryMeters,
    );
  }

  /// Executes AI query with complete context and optional TTS speech
  Stream<String> askAi({
    required String prompt,
    required GpsSnapshot gps,
    required GeoFenceResult geoFence,
    int activeAlertCount = 0,
  }) async* {
    final ctx = buildGlobalContext(
      gps: gps,
      geoFence: geoFence,
      activeAlertCount: activeAlertCount,
    );

    final buffer = StringBuffer();
    await for (final token in chatService.generateResponseStream(
      userPrompt: prompt,
      contextSnapshot: ctx,
    )) {
      buffer.write(token);
      yield token;
    }

    if (_voiceResponseEnabled && buffer.isNotEmpty) {
      final fullText = buffer.toString();
      // Speak brief summary or first sentence
      final firstSentence = fullText.split('\n').firstWhere(
            (l) => l.trim().isNotEmpty && !l.startsWith('⚠️'),
            orElse: () => fullText.substring(0, fullText.length.clamp(0, 120)),
          );
      unawaited(voiceService.speak(firstSentence));
    }
  }
}
