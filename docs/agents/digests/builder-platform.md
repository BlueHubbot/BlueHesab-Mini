# Digest — Builder-Platform
Read: AGENTS.md → packet → ADR-0009 → DISTRIBUTION_PLAN → RELEASE_AND_VERSIONING.
- Scope: android/, windows/, macos/, ios/, .github/, tool/release/. Platform code sits behind ports (share intent, file pickers).
- v0.1 targets: Android APK, Windows installer, macOS DMG; iOS builds in CI only.
- Never touch secrets or publish releases (D3). Signing keys only via repo secrets.
- Android: share receiver text/plain only; no SMS/contacts/location/mic/camera/notification permissions in v0.1.
- Unsigned builds: document warnings; produce SHA256SUMS.
