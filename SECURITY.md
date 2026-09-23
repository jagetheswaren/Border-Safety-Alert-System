# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

The Border Safety Alert System team takes security seriously. If you discover a security vulnerability within BSAS, please follow these steps:

1. **Do not open a public GitHub issue.**
2. Send an email directly to the project maintainers with details, reproduction steps, and potential impact.
3. Allow up to 48 hours for an initial acknowledgement and triage response.

## Security Practices in BSAS

- **No Secrets in Source**: API keys, credentials, and environment-specific variables must reside exclusively in `.env` files and never be checked into version control.
- **Password Security**: Passwords are never stored in plaintext. Passwords are cryptographically salted and hashed using bcrypt.
- **JWT Authorization**: API requests utilize standard OAuth2 Bearer JWT authorization with configurable token expiry.
- **Fail-Fast Production Safeguards**: The FastAPI backend validates that in production environments, strong secret keys are configured and weak development fallbacks are rejected.
- **Safety Pipeline Isolation**: The conversational AI assistant operates read-only on safety snapshots and cannot modify core geofence, GPS, or risk engine states.
