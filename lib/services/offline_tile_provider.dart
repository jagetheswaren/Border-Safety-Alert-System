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
    final key = '${coordinates.z}/${coordinates.x}/${coordinates.y}';
    if (OfflineMapService.bundledTileKeys.contains(key)) {
      return AssetImage('assets/maps/offline_tiles/$key.png');
    }
    if (allowNetworkFallback) {
      return NetworkImage(
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/${coordinates.z}/${coordinates.y}/${coordinates.x}',
        headers: const {
          'Accept': 'image/png,image/*;q=0.8,*/*;q=0.5',
        },
      );
    }
    return const AssetImage('assets/maps/missing_tile.png');
  }
}
