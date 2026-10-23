import 'lstm_runner_stub.dart'
    if (dart.library.io) 'lstm_runner_io.dart'
    if (dart.library.html) 'lstm_runner_web.dart'
    if (dart.library.js_interop) 'lstm_runner_web.dart';

abstract class LstmRunner {
  factory LstmRunner() => getLstmRunner();

  bool get isReady;
  Duration? get lastInference;
  String? get lastError;

  Future<bool> initialize();
  (double, double)? predict(List<List<double>> sequence);
  void dispose();
}
