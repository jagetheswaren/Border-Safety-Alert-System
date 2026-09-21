import 'dart:async';
import 'package:flutter/material.dart';
import '../models/gps_snapshot.dart';
import '../models/boundary_model.dart';
import '../models/routing_result.dart';
import '../services/routing_service.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({
    super.key,
    required this.gps,
    required this.loadBoundaries,
  });

  final GpsSnapshot gps;
  final Future<List<BoundaryModel>> Function() loadBoundaries;

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final RoutingService _routingService = RoutingService();
  RoutingResult? _result;
  bool _isLoading = false;

  Future<void> _calculateRoute() async {
    final loc = widget.gps.location;
    if (loc == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No GPS location available.')));
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final boundaries = await widget.loadBoundaries();
      final result = await _routingService.calculateSafeRoute(loc, boundaries);
      if (mounted) {
        setState(() => _result = result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error calculating route: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('screen-route'),
      appBar: AppBar(title: const Text('Safe Route')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_result != null) ...[
            Card(
              child: ListTile(
                leading: Icon(_result!.status == RoutingStatus.alreadySafe
                    ? Icons.check_circle
                    : (_result!.status == RoutingStatus.available
                        ? Icons.route
                        : Icons.warning)),
                title: Text(
                  _result!.status == RoutingStatus.alreadySafe
                      ? 'You are safe.'
                      : (_result!.status == RoutingStatus.available
                          ? 'Safe Route Found'
                          : 'No Route Available'),
                ),
                subtitle: Text(_result!.message),
              ),
            ),
            if (_result!.status == RoutingStatus.available &&
                _result!.totalDistanceMeters != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Distance: ${_result!.totalDistanceMeters!.toStringAsFixed(1)} m'),
                      if (_result!.initialBearing != null)
                        Text('Initial Bearing: ${_result!.initialBearing!.toStringAsFixed(1)}°'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ] else ...[
            const Card(
              child: ListTile(
                leading: Icon(Icons.route),
                title: Text('No route calculated'),
                subtitle: Text('Tap the button below to find a safe escape route.'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          FilledButton.icon(
            onPressed: _isLoading ? null : _calculateRoute,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.navigation),
            label: Text(_isLoading ? 'Calculating...' : 'Calculate safe route'),
          ),
        ],
      ),
    );
  }
}
