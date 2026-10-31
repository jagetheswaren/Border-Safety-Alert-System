import 'package:latlong2/latlong.dart';
import 'boundary_model.dart';
import 'safety_state.dart';

enum GisCategory {
  officialForestBoundary,
  estimatedForestCover,
  adminCountry,
  adminState,
  adminDistrict,
}

extension GisCategoryExtension on GisCategory {
  String get displayName {
    switch (this) {
      case GisCategory.officialForestBoundary:
        return 'Official Forest Reserve';
      case GisCategory.estimatedForestCover:
        return 'Estimated Forest Canopy (JRC/Model)';
      case GisCategory.adminCountry:
        return 'International Country Boundary';
      case GisCategory.adminState:
        return 'State / Province Boundary';
      case GisCategory.adminDistrict:
        return 'District Administrative Boundary';
    }
  }

  String get code {
    switch (this) {
      case GisCategory.officialForestBoundary:
        return 'OFFICIAL_FOREST_BOUNDARY';
      case GisCategory.estimatedForestCover:
        return 'ESTIMATED_FOREST_COVER';
      case GisCategory.adminCountry:
        return 'ADMIN_COUNTRY';
      case GisCategory.adminState:
        return 'ADMIN_STATE';
      case GisCategory.adminDistrict:
        return 'ADMIN_DISTRICT';
    }
  }

  static GisCategory fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'OFFICIAL_FOREST_BOUNDARY':
        return GisCategory.officialForestBoundary;
      case 'ESTIMATED_FOREST_COVER':
        return GisCategory.estimatedForestCover;
      case 'ADMIN_COUNTRY':
        return GisCategory.adminCountry;
      case 'ADMIN_STATE':
        return GisCategory.adminState;
      case 'ADMIN_DISTRICT':
      default:
        return GisCategory.adminDistrict;
    }
  }
}

class GisFeatureModel {
  const GisFeatureModel({
    required this.id,
    required this.name,
    required this.category,
    required this.sourceName,
    this.sourceUrl,
    this.license,
    this.version,
    this.publicationDate,
    required this.polygon,
    this.isVerified = true,
    required this.cachedAt,
  });

  final String id;
  final String name;
  final GisCategory category;
  final String sourceName;
  final String? sourceUrl;
  final String? license;
  final String? version;
  final String? publicationDate;
  final List<List<LatLng>> polygon;
  final bool isVerified;
  final DateTime cachedAt;

  BoundaryModel toBoundaryModel() {
    return BoundaryModel(
      id: id,
      name: name,
      riskLevel: category == GisCategory.officialForestBoundary
          ? RiskLevel.high
          : category == GisCategory.estimatedForestCover
              ? RiskLevel.medium
              : RiskLevel.low,
      type: category.code,
      country: 'Global / Regional',
      description: '$name [Source: $sourceName, License: ${license ?? "Public"}]',
      source: sourceName,
      version: version,
      polygon: polygon
          .map((ring) => ring
              .map((pt) => BoundaryPosition(
                    latitude: pt.latitude,
                    longitude: pt.longitude,
                  ))
              .toList())
          .toList(),
    );
  }
}
