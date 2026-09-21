// lib/models/ai_prediction_result.dart
enum RiskClass {
  low,
  medium,
  high,
}

class AiPredictionResult {
  final double predictedLatitude;
  final double predictedLongitude;
  final RiskClass riskClass;
  final bool isAvailable;

  const AiPredictionResult({
    required this.predictedLatitude,
    required this.predictedLongitude,
    required this.riskClass,
    this.isAvailable = true,
  });

  factory AiPredictionResult.unavailable() {
    return const AiPredictionResult(
      predictedLatitude: 0.0,
      predictedLongitude: 0.0,
      riskClass: RiskClass.low,
      isAvailable: false,
    );
  }
}
