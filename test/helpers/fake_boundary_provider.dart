import 'package:border_safety_alert/services/boundary_summary.dart';
import 'package:border_safety_alert/models/boundary_model.dart';

/// Deterministic [BoundarySummaryProvider] for widget tests (no SQLite).
class FakeBoundarySummaryProvider implements BoundarySummaryProvider {
  FakeBoundarySummaryProvider({
    this.count = 2,
    this.allDemo = true,
    this.error,
  });

  final int count;
  final bool allDemo;
  final String? error;

  @override
  Future<BoundarySummary> load() async =>
      BoundarySummary(count: count, allDemo: allDemo, error: error);

  @override
  Future<List<BoundaryModel>> loadEnabledBoundaries() async => const [];
}
