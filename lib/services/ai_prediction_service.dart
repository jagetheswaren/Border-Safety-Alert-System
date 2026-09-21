// lib/services/ai_prediction_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/location_model.dart';
import '../models/ai_prediction_result.dart';

class AiPredictionService {
  static const int _sequenceLength = 5;
  final List<LocationModel> _locationBuffer = [];
  
  Interpreter? _lstmInterpreter;
  Map<String, dynamic>? _rfModel;
  Map<String, dynamic>? _scalerParams;
  bool _isInitialized = false;
  bool _lstmReady = false;
  bool _rfReady = false;
  bool _scalerReady = false;
  Duration? _lastInference;
  String? _lastError;

  bool get isInitialized => _isInitialized;
  bool get lstmReady => _lstmReady;
  bool get rfReady => _rfReady;
  bool get scalerReady => _scalerReady;
  Duration? get lastInference => _lastInference;
  String? get lastError => _lastError;

  Future<void> initialize() async {
    try {
      _lstmInterpreter = await Interpreter.fromAsset('assets/models/phase7-lstm-v1.tflite');
      _lstmReady = true;

      final rfJson = await rootBundle.loadString('assets/models/phase7-rf-v1.json');
      _rfModel = jsonDecode(rfJson);
      _rfReady = _rfModel != null && _rfModel!['trees'] is List;

      final scalerJson = await rootBundle.loadString('assets/models/scaler_params.json');
      _scalerParams = jsonDecode(scalerJson);
      _scalerReady = _scalerParams != null &&
          _scalerParams!['means'] is List &&
          _scalerParams!['scales'] is List;

      _isInitialized = _lstmReady && _rfReady && _scalerReady;
      _lastError = _isInitialized ? null : 'Incomplete model bundle';
    } catch (e) {
      debugPrint('AiPredictionService init error: $e');
      _isInitialized = false;
      _lastError = '$e';
    }
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000;
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final deltaPhi = (lat2 - lat1) * pi / 180;
    final deltaLambda = (lon2 - lon1) * pi / 180;

    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _initialBearing(double lat1, double lon1, double lat2, double lon2) {
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final lambda1 = lon1 * pi / 180;
    final lambda2 = lon2 * pi / 180;

    final y = sin(lambda2 - lambda1) * cos(phi2);
    final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(lambda2 - lambda1);
    final theta = atan2(y, x);
    return (theta * 180 / pi + 360) % 360;
  }

  Future<AiPredictionResult> predict(LocationModel currentLocation, double boundaryLat, double boundaryLon) async {
    if (!_isInitialized || _lstmInterpreter == null || _rfModel == null || _scalerParams == null) {
      return AiPredictionResult.unavailable();
    }

    _locationBuffer.add(currentLocation);
    if (_locationBuffer.length > _sequenceLength) {
      _locationBuffer.removeAt(0);
    }

    if (_locationBuffer.length < _sequenceLength) {
      return AiPredictionResult.unavailable();
    }

    // Build feature sequence
    List<List<double>> sequence = [];
    for (var loc in _locationBuffer) {
      final dist = _haversineDistance(loc.latitude, loc.longitude, boundaryLat, boundaryLon);
      final bearTo = _initialBearing(loc.latitude, loc.longitude, boundaryLat, boundaryLon);
      
      double bearingDiff = ((loc.bearing ?? 0.0) - bearTo).abs();
      if (bearingDiff > 180) bearingDiff = 360 - bearingDiff;

      // Unscaled features: [lat, lon, speed, bearing, dist, bearing_diff]
      List<double> rawFeatures = [
        loc.latitude,
        loc.longitude,
        (loc.speed ?? 0.0),
        (loc.bearing ?? 0.0),
        dist,
        bearingDiff
      ];

      // Scale features
      List<double> scaledFeatures = [];
      List<dynamic> means = _scalerParams!['means'];
      List<dynamic> scales = _scalerParams!['scales'];
      for (int i = 0; i < 6; i++) {
        scaledFeatures.add((rawFeatures[i] - means[i]) / scales[i]);
      }
      sequence.add(scaledFeatures);
    }

    // Run LSTM
    // Input shape [1, 5, 6]
    var input = [sequence];
    var output = List.filled(1 * 2, 0.0).reshape([1, 2]);
    
    final sw = Stopwatch()..start();
    _lstmInterpreter!.run(input, output);
    sw.stop();
    _lastInference = sw.elapsed;
    final dLat = output[0][0] as double;
    final dLon = output[0][1] as double;
    
    final predictedLat = currentLocation.latitude + dLat;
    final predictedLon = currentLocation.longitude + dLon;

    // Run Random Forest
    // Features for RF: [speed, bearing, distance, bearing_diff] (Scaled)
    final rfFeatures = sequence.last.sublist(2);
    
    int classIdx = 0; // Default LOW
    
    // Evaluate RF Trees (Majority voting)
    Map<int, int> votes = {0: 0, 1: 0, 2: 0};
    List<dynamic> trees = _rfModel!['trees'];
        
    for (var tree in trees) {
      final vote = _evaluateTree(tree, rfFeatures);
      votes[vote] = (votes[vote] ?? 0) + 1;
    }
    
    int maxVotes = -1;
    for (var entry in votes.entries) {
      if (entry.value > maxVotes) {
        maxVotes = entry.value;
        classIdx = entry.key;
      }
    }
    
    RiskClass risk;
    if (classIdx == 2) { risk = RiskClass.high; }
    else if (classIdx == 1) { risk = RiskClass.medium; }
    else { risk = RiskClass.low; }

    return AiPredictionResult(
      predictedLatitude: predictedLat,
      predictedLongitude: predictedLon,
      riskClass: risk,
    );
  }

  int _evaluateTree(Map<String, dynamic> node, List<double> features) {
    if (node['type'] == 'leaf') {
      return node['class'] as int;
    }
    
    int fIdx = node['feature_idx'] as int;
    double threshold = (node['threshold'] as num).toDouble();
    
    if (features[fIdx] <= threshold) {
      return _evaluateTree(node['left'], features);
    } else {
      return _evaluateTree(node['right'], features);
    }
  }
}
