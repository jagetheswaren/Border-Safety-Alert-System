import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:border_safety_alert/models/gis_feature_model.dart';
import 'package:border_safety_alert/services/gis_layer_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('GIS Layer Service & Global Forest Geography Tests', () {
    late GisLayerService gisService;

    setUp(() async {
      gisService = GisLayerService(factory: databaseFactoryFfi);
      await gisService.initialize();
    });

    test('seeds authoritative official forest reserves and global boundaries', () async {
      expect(gisService.features.isNotEmpty, isTrue);

      final officialForests = gisService.features.where(
        (f) => f.category == GisCategory.officialForestBoundary,
      );
      expect(officialForests.isNotEmpty, isTrue);
      expect(officialForests.any((f) => f.name.contains('Anamalai')), isTrue);
      expect(officialForests.any((f) => f.name.contains('Mudumalai')), isTrue);

      final estimatedCover = gisService.features.where(
        (f) => f.category == GisCategory.estimatedForestCover,
      );
      expect(estimatedCover.isNotEmpty, isTrue);
      expect(estimatedCover.first.isVerified, isFalse); // Modelled canopy estimate

      final countryBoundaries = gisService.features.where(
        (f) => f.category == GisCategory.adminCountry,
      );
      expect(countryBoundaries.isNotEmpty, isTrue);
    });

    test('layer toggles filter active boundaries dynamically', () {
      final initialBoundaries = gisService.getActiveBoundaries();
      expect(initialBoundaries.isNotEmpty, isTrue);

      gisService.toggleLayer(GisCategory.officialForestBoundary, false);
      final withoutForests = gisService.getActiveBoundaries();
      expect(
        withoutForests.any((b) => b.type == GisCategory.officialForestBoundary.code),
        isFalse,
      );

      gisService.toggleLayer(GisCategory.officialForestBoundary, true);
      final restored = gisService.getActiveBoundaries();
      expect(
        restored.any((b) => b.type == GisCategory.officialForestBoundary.code),
        isTrue,
      );
    });

    test('converts GIS features to valid BoundaryModel instances with coordinates', () {
      final feature = gisService.features.first;
      final boundary = feature.toBoundaryModel();

      expect(boundary.id, feature.id);
      expect(boundary.name, feature.name);
      expect(boundary.polygon.isNotEmpty, isTrue);
      expect(boundary.polygon.first.length, greaterThanOrEqualTo(3));
      expect(boundary.source, feature.sourceName);
    });
  });
}
