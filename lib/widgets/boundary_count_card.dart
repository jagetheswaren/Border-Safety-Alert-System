import 'package:flutter/material.dart';

import '../services/boundary_summary.dart';

/// Phase 4 proof-of-storage card: how many offline boundaries exist and
/// whether they are demo data. Renders loading/error states honestly and
/// performs no safety math (Phase 5).
class BoundaryCountCard extends StatelessWidget {
  const BoundaryCountCard({super.key, required this.summary});

  final Future<BoundarySummary>? summary;

  @override
  Widget build(BuildContext context) {
    final future = summary;
    if (future == null) return const SizedBox.shrink();
    return FutureBuilder<BoundarySummary>(
      future: future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final Object? error = snapshot.error ?? data?.error;
        final String title;
        final String subtitle;
        if (snapshot.connectionState == ConnectionState.waiting) {
          title = 'Loading offline boundaries…';
          subtitle = 'Reading the on-device database.';
        } else if (error != null) {
          title = 'Offline boundaries unavailable';
          subtitle = '$error';
        } else if (data == null) {
          title = 'Offline boundaries unavailable';
          subtitle = 'No boundary data returned.';
        } else {
          title = 'Offline boundaries: ${data.count}';
          subtitle = data.allDemo
              ? 'Demo data — non-authoritative'
              : 'Local boundary dataset';
        }
        return Card(
          key: const Key('boundary-count-card'),
          child: ListTile(
            leading: const Icon(Icons.storage),
            title: Text(title),
            subtitle: Text(subtitle),
          ),
        );
      },
    );
  }
}
