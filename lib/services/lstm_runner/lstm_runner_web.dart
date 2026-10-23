import 'lstm_runner.dart';

LstmRunner getLstmRunner() => LstmRunnerWeb();

class LstmRunnerWeb implements LstmRunner {
  @override
  bool get isReady => false;

  @override
  Duration? get lastInference => null;

  @override
  String? get lastError => null;

  @override
  Future<bool> initialize() async {
    // TFLite native FFI is omitted on Web. Fallback to deterministic and RF heuristics.
    return false;
  }

  @override
  (double, double)? predict(List<List<double>> sequence) => null;

  @override
  void dispose() {}
}
