import 'package:flutter/material.dart';
import 'bsas_colors.dart';

/// Centralized typographic scale for BSAS.
///
/// Designed to be balanced, legible in outdoor field glare, and well-proportioned.
class BsasTypography {
  BsasTypography._();

  // Display (Splash / Main State HUD)
  static const TextStyle display = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.25,
    color: BsasColors.textLightPrimary,
  );

  // Heading (Screen titles / Key telemetry headers)
  static const TextStyle heading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
    color: BsasColors.textLightPrimary,
  );

  // Section Heading (Card titles / Category dividers)
  static const TextStyle sectionHeading = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.1,
    height: 1.4,
    color: BsasColors.primaryBlueLight,
  );

  // Title (Card primary row / item title)
  static const TextStyle title = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.0,
    height: 1.35,
    color: BsasColors.textLightPrimary,
  );

  // Body (Primary readable paragraphs & descriptions)
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.45,
    color: BsasColors.textLightPrimary,
  );

  // Body Muted (Secondary metadata / timestamps)
  static const TextStyle bodyMuted = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.4,
    color: BsasColors.textLightSecondary,
  );

  // Caption (Badges, sub-labels, fine print)
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.35,
    color: BsasColors.textLightSecondary,
  );

  // Label (Buttons, tabs, status pills)
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.2,
    color: BsasColors.textLightPrimary,
  );

  // Monospace (Coordinates, telemetry, SHA-256 hashes, diagnostic logs)
  static const TextStyle monospace = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.4,
    color: BsasColors.textLightPrimary,
  );

  static const TextStyle monoDiagnostics = monospace;

  // Backward compatible alias
  static const TextStyle headline = heading;
}
