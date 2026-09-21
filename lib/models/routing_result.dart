import 'package:flutter/foundation.dart';
import 'location_model.dart';

enum RoutingStatus {
  available,
  unavailable,
  unknown,
  alreadySafe
}

@immutable
class RoutingResult {
  const RoutingResult({
    required this.status,
    this.routePoints,
    this.totalDistanceMeters,
    this.initialBearing,
    this.destination,
    this.message = '',
  });

  final RoutingStatus status;
  final List<LocationModel>? routePoints;
  final double? totalDistanceMeters;
  final double? initialBearing;
  final LocationModel? destination;
  final String message;
  
  factory RoutingResult.unavailable({String message = ''}) {
    return RoutingResult(status: RoutingStatus.unavailable, message: message);
  }
  
  factory RoutingResult.unknown({String message = ''}) {
    return RoutingResult(status: RoutingStatus.unknown, message: message);
  }
  
  factory RoutingResult.alreadySafe({String message = ''}) {
    return RoutingResult(status: RoutingStatus.alreadySafe, message: message);
  }
}
