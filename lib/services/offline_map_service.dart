import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';

enum OfflineMapStatus {
  notAvailable,
  downloading,
  verifying,
  ready,
  outdated,
  corrupted,
  error,
}

class OfflineRegion {
  const OfflineRegion({
    required this.id,
    required this.name,
    required this.description,
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
    required this.minZoom,
    required this.maxZoom,
    required this.version,
  });

  final String id;
  final String name;
  final String description;
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;
  final int minZoom;
  final int maxZoom;
  final String version;

  String toBoundsGeoJson() {
    return jsonEncode({
      'type': 'Polygon',
      'coordinates': [
        [
          [minLon, minLat],
          [maxLon, minLat],
          [maxLon, maxLat],
          [minLon, maxLat],
          [minLon, minLat],
        ]
      ]
    });
  }
}

class OfflineRegionRecord {
  final String id;
  final String name;
  final int minZoom;
  final int maxZoom;
  final String boundsGeoJson;
  final int tileCount;
  final int sizeBytes;
  final String status;
  final String? downloadedAt;
  final String? checksum;

  const OfflineRegionRecord({
    required this.id,
    required this.name,
    required this.minZoom,
    required this.maxZoom,
    required this.boundsGeoJson,
    required this.tileCount,
    required this.sizeBytes,
    required this.status,
    this.downloadedAt,
    this.checksum,
  });

  double get sizeMb => sizeBytes / (1024 * 1024);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'min_zoom': minZoom,
        'max_zoom': maxZoom,
        'bounds_geojson': boundsGeoJson,
        'tile_count': tileCount,
        'size_bytes': sizeBytes,
        'status': status,
        'downloaded_at': downloadedAt,
        'checksum': checksum,
      };

  factory OfflineRegionRecord.fromMap(Map<String, dynamic> map) => OfflineRegionRecord(
        id: map['id'] as String,
        name: map['name'] as String,
        minZoom: (map['min_zoom'] as num).toInt(),
        maxZoom: (map['max_zoom'] as num).toInt(),
        boundsGeoJson: map['bounds_geojson'] as String,
        tileCount: (map['tile_count'] as num?)?.toInt() ?? 0,
        sizeBytes: (map['size_bytes'] as num?)?.toInt() ?? 0,
        status: map['status'] as String,
        downloadedAt: map['downloaded_at'] as String?,
        checksum: map['checksum'] as String?,
      );
}

class OfflineMapService extends ChangeNotifier {
  OfflineMapService({Database? db}) {
    _db = db;
  }

  static const defaultRegion = OfflineRegion(
    id: 'pollachi_coimbatore',
    name: 'Pollachi / Coimbatore Border Sector',
    description: 'Western Ghats corridor operational region',
    minLat: 10.50,
    maxLat: 11.10,
    minLon: 76.70,
    maxLon: 77.20,
    minZoom: 8,
    maxZoom: 13,
    version: '2026.09-v1',
  );

  static const maritimeRegion = OfflineRegion(
    id: 'palk_strait_maritime',
    name: 'Palk Bay & IMBL Maritime Sector',
    description: 'India - Sri Lanka International Boundary Line',
    minLat: 9.00,
    maxLat: 10.20,
    minLon: 78.80,
    maxLon: 79.90,
    minZoom: 8,
    maxZoom: 13,
    version: '2026.09-m1',
  );

  static const Set<String> bundledTileKeys = {
    '8/182/120',
    '9/365/240',
    '10/730/480', '10/730/481', '10/731/480', '10/731/481',
    '11/1460/960', '11/1460/961', '11/1460/962', '11/1460/963',
    '11/1461/960', '11/1461/961', '11/1461/962', '11/1461/963',
    '11/1462/960', '11/1462/961', '11/1462/962', '11/1462/963',
    '11/1463/960', '11/1463/961', '11/1463/962', '11/1463/963',
    '12/2920/1920', '12/2920/1921', '12/2920/1922', '12/2920/1923', '12/2920/1924', '12/2920/1925', '12/2920/1926', '12/2920/1927',
    '12/2921/1920', '12/2921/1921', '12/2921/1922', '12/2921/1923', '12/2921/1924', '12/2921/1925', '12/2921/1926', '12/2921/1927',
    '12/2922/1920', '12/2922/1921', '12/2922/1922', '12/2922/1923', '12/2922/1924', '12/2922/1925', '12/2922/1926', '12/2922/1927',
    '12/2923/1920', '12/2923/1921', '12/2923/1922', '12/2923/1923', '12/2923/1924', '12/2923/1925', '12/2923/1926', '12/2923/1927',
    '12/2924/1920', '12/2924/1921', '12/2924/1922', '12/2924/1923', '12/2924/1924', '12/2924/1925', '12/2924/1926', '12/2924/1927',
    '12/2925/1920', '12/2925/1921', '12/2925/1922', '12/2925/1923', '12/2925/1924', '12/2925/1925', '12/2925/1926', '12/2925/1927',
    '12/2926/1920', '12/2926/1921', '12/2926/1922', '12/2926/1923', '12/2926/1924', '12/2926/1925', '12/2926/1926', '12/2926/1927',
  };

  static const osmUserAgent =
      'BSAS-offline-map/1.0 (border-safety-alert; educational field app)';

  Database? _db;
  OfflineMapStatus _status = OfflineMapStatus.notAvailable;
  double _downloadProgress = 0.0;
  String? _storagePath;
  String? _errorMessage;
  int _tileCount = 0;
  double _storageMb = 0;
  String? _manifestChecksum;

  OfflineMapStatus get status => _status;
  bool get isReady => _status == OfflineMapStatus.ready;
  bool get isAvailable => isReady;
  double get downloadProgress => _downloadProgress;
  String? get storagePath => _storagePath;
  String? get errorMessage => _errorMessage;
  int get tileCount => _tileCount;
  double get storageMb => _storageMb;
  String? get mapVersion => isReady ? defaultRegion.version : null;
  String? get manifestChecksum => _manifestChecksum;

  List<OfflineRegion> getAvailableRegions() => const [defaultRegion, maritimeRegion];

  Future<Database?> _getDatabase({DatabaseFactory? factory}) async {
    if (_db != null && _db!.isOpen) return _db;
    try {
      final selected = factory ?? databaseFactory;
      final path = p.join(await selected.getDatabasesPath(), 'border_safety.db');
      _db = (await AppDatabase.open(factory: selected, path: path)).db;
      return _db;
    } catch (e) {
      debugPrint('OfflineMapService: SQLite open warning: $e');
      return null;
    }
  }

  Future<Directory> _tileDir() async {
    if (_storagePath != null) return Directory(_storagePath!);
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final tileDir = Directory('${docDir.path}/offline_tiles');
      if (!await tileDir.exists()) {
        await tileDir.create(recursive: true);
      }
      _storagePath = tileDir.path;
      return tileDir;
    } catch (_) {
      final tileDir = Directory(
        '${Directory.systemTemp.path}/bsas_offline_tiles',
      );
      if (!await tileDir.exists()) {
        await tileDir.create(recursive: true);
      }
      _storagePath = tileDir.path;
      return tileDir;
    }
  }

  Future<File> _manifestFile() async {
    final dir = await _tileDir();
    return File('${dir.path}/manifest.json');
  }

  Future<void> initialize({DatabaseFactory? factory}) async {
    final dir = await _tileDir();
    final manifest = await _manifestFile();
    if (!await manifest.exists()) {
      await _seedBundledTiles(dir);
    }
    await verifyRegion(defaultRegion.id);
    await _syncMetadataWithDatabase(factory: factory);
  }

  Future<void> _syncMetadataWithDatabase({DatabaseFactory? factory}) async {
    try {
      final db = await _getDatabase(factory: factory);
      if (db == null) return;

      final count = _tileCount > 0 ? _tileCount : bundledTileKeys.length;
      final sizeBytes = (count * 18 * 1024); // Estimated bundled/cached size

      final defaultRecord = OfflineRegionRecord(
        id: defaultRegion.id,
        name: defaultRegion.name,
        minZoom: defaultRegion.minZoom,
        maxZoom: defaultRegion.maxZoom,
        boundsGeoJson: defaultRegion.toBoundsGeoJson(),
        tileCount: count,
        sizeBytes: sizeBytes,
        status: isReady ? 'READY' : 'AVAILABLE',
        downloadedAt: DateTime.now().toUtc().toIso8601String(),
        checksum: _manifestChecksum ?? 'bundled-v1',
      );

      final maritimeRecord = OfflineRegionRecord(
        id: maritimeRegion.id,
        name: maritimeRegion.name,
        minZoom: maritimeRegion.minZoom,
        maxZoom: maritimeRegion.maxZoom,
        boundsGeoJson: maritimeRegion.toBoundsGeoJson(),
        tileCount: 0,
        sizeBytes: 0,
        status: 'AVAILABLE',
        downloadedAt: null,
        checksum: null,
      );

      await db.insert(
        AppDatabase.tableOfflineRegions,
        defaultRecord.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await db.insert(
        AppDatabase.tableOfflineRegions,
        maritimeRecord.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      debugPrint('OfflineMapService: syncMetadata error: $e');
    }
  }

  Future<List<OfflineRegionRecord>> getStoredRegions({DatabaseFactory? factory}) async {
    try {
      final db = await _getDatabase(factory: factory);
      if (db == null) {
        return [
          OfflineRegionRecord(
            id: defaultRegion.id,
            name: defaultRegion.name,
            minZoom: defaultRegion.minZoom,
            maxZoom: defaultRegion.maxZoom,
            boundsGeoJson: defaultRegion.toBoundsGeoJson(),
            tileCount: _tileCount,
            sizeBytes: (_tileCount * 18 * 1024),
            status: isReady ? 'READY' : 'AVAILABLE',
            downloadedAt: DateTime.now().toUtc().toIso8601String(),
          ),
          OfflineRegionRecord(
            id: maritimeRegion.id,
            name: maritimeRegion.name,
            minZoom: maritimeRegion.minZoom,
            maxZoom: maritimeRegion.maxZoom,
            boundsGeoJson: maritimeRegion.toBoundsGeoJson(),
            tileCount: 0,
            sizeBytes: 0,
            status: 'AVAILABLE',
          ),
        ];
      }
      final rows = await db.query(AppDatabase.tableOfflineRegions);
      if (rows.isEmpty) {
        await _syncMetadataWithDatabase(factory: factory);
        final freshRows = await db.query(AppDatabase.tableOfflineRegions);
        return freshRows.map(OfflineRegionRecord.fromMap).toList();
      }
      return rows.map(OfflineRegionRecord.fromMap).toList();
    } catch (e) {
      debugPrint('OfflineMapService: getStoredRegions error: $e');
      return [];
    }
  }

  Future<bool> isRegionAvailable() async {
    await verifyRegion(defaultRegion.id);
    return isReady;
  }

  Future<bool> _seedBundledTiles(Directory dir) async {
    try {
      String manifestJson;
      try {
        manifestJson = await rootBundle.loadString('assets/maps/offline_tiles/manifest.json');
      } catch (_) {
        return false;
      }
      final manifestFile = File('${dir.path}/manifest.json');
      await manifestFile.writeAsString(manifestJson, flush: true);

      // Extract each bundled tile from assets to disk
      int extractedCount = 0;
      for (final key in bundledTileKeys) {
        final dest = File('${dir.path}/$key.png');
        if (!dest.existsSync()) {
          dest.parent.createSync(recursive: true);
          try {
            final byteData = await rootBundle.load('assets/maps/offline_tiles/$key.png');
            final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
            if (bytes.length >= 64) {
              await dest.writeAsBytes(bytes, flush: true);
              extractedCount++;
            }
          } catch (_) {
            // Asset load fails if file does not exist
          }
        } else if (dest.lengthSync() >= 64) {
          extractedCount++;
        }
      }
      return extractedCount > 0;
    } catch (e) {
      debugPrint('OfflineMapService: seed bundled tiles notice: $e');
      return false;
    }
  }

  Future<void> verifyRegion(String regionId) async {
    _status = OfflineMapStatus.verifying;
    notifyListeners();
    try {
      final dir = await _tileDir();
      final manifest = await _manifestFile();
      if (!await manifest.exists()) {
        await _seedBundledTiles(dir);
      }

      final counted = await _countTiles(dir);
      _tileCount = counted;
      _storageMb = await getStorageUsageMb();

      if (!await manifest.exists() || counted == 0) {
        _status = OfflineMapStatus.notAvailable;
        _errorMessage = 'No verified local tile files on disk.';
        notifyListeners();
        return;
      }

      final data = jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
      final version = data['version'] as String? ?? '';
      final expected = (data['expected_tiles'] as num?)?.toInt() ?? bundledTileKeys.length;
      _manifestChecksum = data['checksum'] as String?;

      if (version != defaultRegion.version && version != maritimeRegion.version) {
        _status = OfflineMapStatus.outdated;
        _errorMessage = 'Local offline map version ($version) is outdated.';
      } else if (counted < (expected * 0.9).floor()) {
        // Honest partial / corrupted status: actual tiles are significantly missing
        _status = OfflineMapStatus.corrupted;
        _errorMessage = 'Incomplete tile bundle: found $counted of $expected expected tiles.';
      } else {
        _status = OfflineMapStatus.ready;
        _errorMessage = null;
      }
    } catch (e) {
      _status = OfflineMapStatus.error;
      _errorMessage = '$e';
    }
    notifyListeners();
  }

  Future<void> cacheTile(int z, int x, int y, Uint8List bytes) async {
    try {
      final dir = await _tileDir();
      final file = File('${dir.path}/$z/$x/$y.png');
      if (!file.existsSync()) {
        file.parent.createSync(recursive: true);
        await file.writeAsBytes(bytes, flush: true);
        _tileCount += 1;
      }
    } catch (_) {}
  }

  int estimateTileCount(OfflineRegion region, {int? minZoom, int? maxZoom}) {
    return _enumerateTiles(region, minZoom: minZoom, maxZoom: maxZoom).length;
  }

  double estimateMb(int tileCount) {
    return (tileCount * 18.0) / 1024.0;
  }

  Future<void> downloadRegion(String regionId, {int? minZoom, int? maxZoom}) async {
    final region = getAvailableRegions().firstWhere(
      (r) => r.id == regionId,
      orElse: () => defaultRegion,
    );
    _status = OfflineMapStatus.downloading;
    _downloadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      final db = await _getDatabase();
      if (db != null) {
        await db.update(
          AppDatabase.tableOfflineRegions,
          {'status': 'DOWNLOADING'},
          where: 'id = ?',
          whereArgs: [regionId],
        );
      }

      final dir = await _tileDir();
      final tiles = _enumerateTiles(region, minZoom: minZoom, maxZoom: maxZoom);
      if (tiles.isEmpty) {
        throw StateError('Region produced zero tiles.');
      }
      final client = HttpClient()..userAgent = osmUserAgent;
      var completed = 0;
      for (final tile in tiles) {
        final file = File('${dir.path}/${tile.$1}/${tile.$2}/${tile.$3}.png');
        if (!await file.exists()) {
          await file.parent.create(recursive: true);
          // Use ArcGIS World Street Map licensed raster tiles ({z}/{y}/{x})
          final uri = Uri.parse(
            'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/${tile.$1}/${tile.$3}/${tile.$2}',
          );
          final req = await client.getUrl(uri);
          req.headers.set(HttpHeaders.userAgentHeader, osmUserAgent);
          final res = await req.close();
          if (res.statusCode != 200) {
            throw HttpException('Map tile HTTP ${res.statusCode} for $uri');
          }
          final bytes = await consolidateHttpClientResponseBytes(res);
          if (bytes.length < 64) {
            throw StateError('Rejected empty tile ${tile.$1}/${tile.$2}/${tile.$3}');
          }
          await file.writeAsBytes(bytes, flush: true);
        }
        completed += 1;
        _downloadProgress = completed / tiles.length;
        if (completed % 8 == 0 || completed == tiles.length) {
          notifyListeners();
        }
      }
      client.close(force: true);

      final counted = await _countTiles(dir);
      final checksum = sha256.convert(utf8.encode('$regionId:${region.version}:$counted')).toString();
      final manifest = {
        'id': region.id,
        'version': region.version,
        'min_zoom': minZoom ?? region.minZoom,
        'max_zoom': maxZoom ?? region.maxZoom,
        'expected_tiles': tiles.length,
        'actual_tiles': counted,
        'checksum': checksum,
        'prepared_at': DateTime.now().toUtc().toIso8601String(),
      };
      await (await _manifestFile()).writeAsString(jsonEncode(manifest));
      _manifestChecksum = checksum;
      await verifyRegion(region.id);

      final usageBytes = (await getStorageUsageMb() * 1024 * 1024).toInt();
      if (db != null) {
        final record = OfflineRegionRecord(
          id: region.id,
          name: region.name,
          minZoom: minZoom ?? region.minZoom,
          maxZoom: maxZoom ?? region.maxZoom,
          boundsGeoJson: region.toBoundsGeoJson(),
          tileCount: counted,
          sizeBytes: usageBytes,
          status: 'READY',
          downloadedAt: DateTime.now().toUtc().toIso8601String(),
          checksum: checksum,
        );
        await db.insert(
          AppDatabase.tableOfflineRegions,
          record.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      _status = OfflineMapStatus.error;
      _errorMessage = '$e';
      final db = await _getDatabase();
      if (db != null) {
        await db.update(
          AppDatabase.tableOfflineRegions,
          {'status': 'ERROR'},
          where: 'id = ?',
          whereArgs: [regionId],
        );
      }
      notifyListeners();
    }
  }

  Future<void> updateRegion(String regionId) => downloadRegion(regionId);

  Future<void> deleteRegion(String regionId) async {
    try {
      final dir = await _tileDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
      _tileCount = 0;
      _storageMb = 0;
      _manifestChecksum = null;
      _status = OfflineMapStatus.notAvailable;

      final db = await _getDatabase();
      if (db != null) {
        await db.update(
          AppDatabase.tableOfflineRegions,
          {
            'status': 'AVAILABLE',
            'tile_count': 0,
            'size_bytes': 0,
            'downloaded_at': null,
            'checksum': null,
          },
          where: 'id = ?',
          whereArgs: [regionId],
        );
      }
    } catch (e) {
      _status = OfflineMapStatus.error;
      _errorMessage = '$e';
    }
    notifyListeners();
  }

  Future<double> getStorageUsageMb() async {
    final dir = await _tileDir();
    if (!await dir.exists()) return 0.0;
    var bytes = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        bytes += await entity.length();
      }
    }
    return bytes / (1024 * 1024);
  }

  File tileFile(int z, int x, int y) {
    final root = _storagePath ?? Directory.systemTemp.path;
    return File('$root/$z/$x/$y.png');
  }

  List<(int, int, int)> _enumerateTiles(OfflineRegion region, {int? minZoom, int? maxZoom}) {
    final tiles = <(int, int, int)>[];
    final zStart = minZoom ?? region.minZoom;
    final zEnd = maxZoom ?? region.maxZoom;
    for (var z = zStart; z <= zEnd; z++) {
      final xMin = _lonToTileX(region.minLon, z);
      final xMax = _lonToTileX(region.maxLon, z);
      final yMin = _latToTileY(region.maxLat, z);
      final yMax = _latToTileY(region.minLat, z);
      for (var x = math.min(xMin, xMax); x <= math.max(xMin, xMax); x++) {
        for (var y = math.min(yMin, yMax); y <= math.max(yMin, yMax); y++) {
          tiles.add((z, x, y));
        }
      }
    }
    return tiles;
  }

  static int _lonToTileX(double lon, int z) {
    final n = 1 << z;
    return (((lon + 180.0) / 360.0) * n).floor().clamp(0, n - 1);
  }

  static int _latToTileY(double lat, int z) {
    final n = 1 << z;
    final latRad = lat * math.pi / 180.0;
    final y =
        ((1.0 -
                math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) /
                    math.pi) /
            2.0) *
        n;
    return y.floor().clamp(0, n - 1);
  }

  Future<int> _countTiles(Directory dir) async {
    var count = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.png')) count += 1;
    }
    return count;
  }
}
