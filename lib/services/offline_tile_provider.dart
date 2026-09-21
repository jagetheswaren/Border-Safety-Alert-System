import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

import 'offline_map_service.dart';

/// Serves locally stored OSM raster tiles. Falls back to a bundled missing-tile
/// image when the requested tile is not on disk. Never reports success without
/// a real local file.
class OfflineTileProvider extends TileProvider {
  OfflineTileProvider({
    required this.mapService,
    this.allowNetworkFallback = false,
  });

  final OfflineMapService mapService;
  final bool allowNetworkFallback;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final file = mapService.tileFile(coordinates.z, coordinates.x, coordinates.y);
    if (file.existsSync()) {
      return FileImage(file);
    }
    if (allowNetworkFallback) {
      return NetworkImage(
        'https://tile.openstreetmap.org/${coordinates.z}/${coordinates.x}/${coordinates.y}.png',
        headers: const {HttpHeaders.userAgentHeader: OfflineMapService.osmUserAgent},
      );
    }
    return const AssetImage('assets/maps/missing_tile.png');
  }
}
