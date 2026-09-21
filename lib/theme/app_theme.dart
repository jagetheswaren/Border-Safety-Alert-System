import 'package:flutter/material.dart';

/// Consistent Material 3 theme for the safety application.
///
/// Semantic risk/safety colors live next to the widgets that render them
/// ([RiskBadge], [StatusIndicator]) so Phase 3+ services can reuse the same
/// mapping without touching the theme.
class AppTheme {
  AppTheme._();

  static const _seed = Colors.teal;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: _seed);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: const CardThemeData(margin: EdgeInsets.all(8)),
      listTileTheme: const ListTileThemeData(dense: false),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: const CardThemeData(margin: EdgeInsets.all(8)),
      listTileTheme: const ListTileThemeData(dense: false),
    );
  }
}
