import 'package:flutter_tts/flutter_tts.dart';

abstract interface class VoiceAlertOutput {
  Future<void> speak(String message);
  Future<void> stop();
}

class VoiceAlertService implements VoiceAlertOutput {
  VoiceAlertService({FlutterTts? textToSpeech}) : _textToSpeech = textToSpeech ?? FlutterTts();

  final FlutterTts _textToSpeech;
  String? _lastMessage;

  Future<void> initialize() async {
    try {
      await _textToSpeech.setLanguage('en-US');
      await _textToSpeech.setSpeechRate(0.48);
      await _textToSpeech.setVolume(1.0);
      await _textToSpeech.setPitch(1.0);
    } catch (_) {}
  }

  @override
  Future<void> speak(String message) async {
    if (message.isEmpty || message == _lastMessage) return;
    try {
      _lastMessage = message;
      await _textToSpeech.speak(message);
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    try {
      await _textToSpeech.stop();
      _lastMessage = null;
    } catch (_) {}
  }
}
