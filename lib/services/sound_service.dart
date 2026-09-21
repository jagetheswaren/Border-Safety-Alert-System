import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for playing local alert audio assets with cooldown debouncing.
class SoundService {
  SoundService({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ),
    );
  }

  final AudioPlayer _player;
  bool _isMuted = false;
  double _volume = 1.0;
  DateTime? _lastWarningSound;
  DateTime? _lastCriticalSound;

  static const Duration warningCooldown = Duration(seconds: 15);
  static const Duration criticalCooldown = Duration(seconds: 8);

  bool get isMuted => _isMuted;
  double get volume => _volume;

  void setMuted(bool muted) {
    _isMuted = muted;
    if (muted) {
      unawaited(_player.stop());
    }
  }

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    unawaited(_player.setVolume(_volume));
  }

  Future<void> playWarning() async {
    if (_isMuted) return;
    final now = DateTime.now();
    if (_lastWarningSound != null && now.difference(_lastWarningSound!) < warningCooldown) {
      return;
    }
    _lastWarningSound = now;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/alert_warning.wav'), volume: _volume);
    } catch (e) {
      debugPrint('[SoundService] Warning audio play error: $e');
    }
  }

  Future<void> playCritical() async {
    if (_isMuted) return;
    final now = DateTime.now();
    if (_lastCriticalSound != null && now.difference(_lastCriticalSound!) < criticalCooldown) {
      return;
    }
    _lastCriticalSound = now;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/alert_critical.wav'), volume: _volume);
    } catch (e) {
      debugPrint('[SoundService] Critical audio play error: $e');
    }
  }

  Future<void> playInfo() async {
    if (_isMuted) return;
    try {
      await _player.play(AssetSource('audio/notification_info.wav'), volume: _volume * 0.7);
    } catch (e) {
      debugPrint('[SoundService] Info audio play error: $e');
    }
  }

  Future<void> playGpsLocked() async {
    if (_isMuted) return;
    try {
      await _player.play(AssetSource('audio/gps_locked.wav'), volume: _volume * 0.6);
    } catch (e) {
      debugPrint('[SoundService] GPS locked audio play error: $e');
    }
  }

  Future<void> playSystemReady() async {
    if (_isMuted) return;
    try {
      await _player.play(AssetSource('audio/system_ready.wav'), volume: _volume * 0.6);
    } catch (e) {
      debugPrint('[SoundService] System ready audio play error: $e');
    }
  }

  Future<void> playSyncComplete() async {
    if (_isMuted) return;
    try {
      await _player.play(AssetSource('audio/sync_complete.wav'), volume: _volume * 0.6);
    } catch (e) {
      debugPrint('[SoundService] Sync complete audio play error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('[SoundService] Stop error: $e');
    }
  }

  void dispose() {
    unawaited(_player.dispose());
  }
}
