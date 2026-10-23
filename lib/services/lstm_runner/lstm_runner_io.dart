import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'lstm_runner.dart';

LstmRunner getLstmRunner() => LstmRunnerIo();

class LstmRunnerIo implements LstmRunner {
  Interpreter? _interpreter;
  bool _isReady = false;
  Duration? _lastInference;
  String? _lastError;

  @override
  bool get isReady => _isReady;

  @override
  Duration? get lastInference => _lastInference;

  @override
  String? get lastError => _lastError;

  @override
  Future<bool> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/phase7-lstm-v1.tflite');
      final input = _interpreter!.getInputTensor(0);
      final output = _interpreter!.getOutputTensor(0);
      if (input.shape.join(',') != '1,5,6' || output.shape.join(',') != '1,2') {
        throw StateError('Unexpected LSTM tensor schema');
      }
      _isReady = true;
      return true;
    } catch (tfliteErr) {
      debugPrint('TFLite interpreter not available on this platform: $tfliteErr');
      _isReady = false;
      _lastError = '$tfliteErr';
      return false;
    }
  }

  @override
  (double, double)? predict(List<List<double>> sequence) {
    if (!_isReady || _interpreter == null) return null;
    final input = [sequence];
    final output = List.filled(1 * 2, 0.0).reshape([1, 2]);

    final sw = Stopwatch()..start();
    try {
      _interpreter!.run(input, output);
      sw.stop();
      _lastInference = sw.elapsed;
      final dLat = (output[0][0] as num).toDouble();
      final dLon = (output[0][1] as num).toDouble();
      return (dLat, dLon);
    } catch (e) {
      sw.stop();
      _lastError = '$e';
      _isReady = false;
      return null;
    }
  }

  @override
  void dispose() {
    _interpreter?.close();
  }
}
