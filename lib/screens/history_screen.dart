import 'package:flutter/material.dart';

/// Trip/alert history placeholder. SQLite-backed trip storage (Phase 4/15)
/// will populate this screen; Phase 2 shows the empty state.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('screen-history'),
      appBar: AppBar(title: const Text('History')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48),
            SizedBox(height: 8),
            Text('No trips yet'),
            Text(
              'Trip history arrives with local storage in a later phase.',
              style: TextStyle(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
