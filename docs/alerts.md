# Phase 6 Alert Manager

## Architecture

The alert layer consumes the single deterministic `GeoFenceResult` produced by the existing GPS and GeoFence pipeline:

```text
GpsService -> LocationModel -> GeoFenceService -> GeoFenceResult -> AlertService
                                                              |-> visual banner
                                                              |-> voice
                                                              |-> vibration
                                                              `-> notification
```

`AlertService` performs no geographic calculations and does not create a second GPS stream.

## Severity mapping

- `UNKNOWN` and `SAFE`: no alert.
- `CAUTION`: low-priority alert.
- `WARNING`: strong warning.
- `CRITICAL`: critical alert.
- `INSIDE_RESTRICTED_AREA`: critical restricted-area alert.

Alert text is centralized in `alert_message.dart`.

## Channels

`VoiceAlertService` uses Flutter TTS and safely ignores unavailable engines or speak failures. `VibrationAlertService` uses short severity-specific patterns and safely handles unsupported hardware. `NotificationService` creates the `safety_alerts` Android channel and ignores initialization or delivery failures.

The visual `SafetyAlertBanner` renders the existing GeoFence result. It never makes a new safety decision.

## Cooldown and escalation

The default cooldown is 30 seconds per severity. Repeated alerts of the same severity inside that window are suppressed. Escalation is immediate, including entry into `INSIDE_RESTRICTED_AREA`. De-escalation does not emit a new alert, which prevents oscillating GPS readings from spamming the user. A repeated state can alert again after the cooldown expires.

## Settings

Voice, vibration, and notification switches default to enabled. `AlertPreferencesStore` persists them with `shared_preferences`; failures fall back to defaults and never stop alert processing.

## Failure handling

Platform services are dependency-injected through small output interfaces in tests. Every platform operation is isolated behind error handling, so missing TTS, vibration hardware, notification permissions, or plugin initialization cannot crash the app.

## Testing

`test/alert_service_test.dart` covers severity mapping, no-alert states, cooldown, escalation, de-escalation, channel preferences, repeated alerts after cooldown, and platform failures without hardware or internet.

## Limitations

Alerts currently run while the foreground Flutter application is active. Background execution, richer notification actions, localization, and persistent alert history belong to later work.

> Phase 6 alerts are driven by the deterministic GeoFence result. No machine-learning model is involved yet.
