import 'boundary_import.dart';
import 'boundary_repository.dart';

/// One-time demo seed (Phase 4).
///
/// Inserts the bundled GeoJSON only when the table is empty, so restarts
/// never duplicate rows (upsert ids make even forced re-seeds safe).
/// Throws [BoundaryException] on empty input instead of seeding nothing
/// silently. Designed to be replaced by a real offline dataset later:
/// callers just swap the GeoJSON string.
Future<int> ensureDemoBoundariesSeeded(
  BoundaryRepository repository,
  String geoJson,
) async {
  if (await repository.countBoundaries() > 0) return 0;
  final boundaries = parseBoundariesFromGeoJson(geoJson);
  if (boundaries.isEmpty) {
    throw BoundaryException(
      'Seed GeoJSON contains no boundaries; refusing to seed an empty dataset.',
    );
  }
  await repository.insertBoundaries(boundaries);
  return boundaries.length;
}
