# Security Policy

## Supported Versions

Security updates and bug fixes are actively provided for the latest published version of `flutter_notification_flow`.

| Version | Supported |
| :--- | :---: |
| Latest published version | ✅ |
| Older versions | ❌ |

---

## Security Scope

`flutter_notification_flow` is a lightweight, provider-independent routing and interaction layer for Flutter.

### Architecture & Scope Boundaries:
- **No Credentials**: The package does not collect, store, or manage API keys, tokens, or credentials.
- **No Direct Network Access**: The package does not perform HTTP requests, socket connections, or remote data fetching.
- **No Authentication Management**: User authentication and session management remain solely the responsibility of the host application.
- **Provider-Independent**: The package does not interact directly with push notification servers or provider APIs.

### Areas of Interest:
We welcome responsible security reports involving:
- Malformed, deeply nested, or adversarial notification payload processing.
- Notification routing resolution vulnerabilities.
- Race conditions or bypasses in duplicate protection guards.
- Denial of service or memory exhaustion via the pending notification queue.
- Unexpected application behavior triggered by untrusted notification payloads.

---

## Reporting a Vulnerability

Please **do NOT report security vulnerabilities through public GitHub Issues or discussions.**

To report a vulnerability responsibly:

1. **GitHub Private Vulnerability Reporting (Preferred)**:
   Navigate to the repository's **Security** tab ➔ **Advisories** ➔ **[Report a vulnerability](https://github.com/sapanlabs/flutter_notification_flow/security/advisories/new)**.

2. **Direct Contact**:
   If private vulnerability reporting is unavailable, reach out privately to the repository maintainer through their GitHub profile ([@sapanlabs](https://github.com/sapanlabs)).

### What to Include in Your Report:
- A clear description of the vulnerability and its potential impact.
- Steps to reproduce or a minimal proof-of-concept Flutter code snippet / payload sample.
- Affected versions of `flutter_notification_flow`, Flutter SDK, and Dart SDK.

### Response Process:
We will review reported vulnerabilities as soon as reasonably possible and work toward a fix before public disclosure when appropriate.
