# WakeMate 1.2.9 notification release resource repair

## Artifact evidence

The signed 1.2.8 PVT-B APK does not contain a resource-table entry named
`drawable/ic_notification`, although NotificationService initializes the native
plugin with that name. The plugin resolves it with Android `getIdentifier` and
returns `invalid_icon` when it is absent. This prevents initialization, including
reading pending reminders and showing immediate test notifications. It matches
the reported screen, but no device log has been collected to prove the precise
exception on that phone.

The previous Flutter unit tests mocked successful plugin initialization and did
not inspect resource shrinking in the release artifact. A valid app signature and
passing mocked tests were not sufficient to catch this packaging defect.

## Changes

- Add a PVT-B-specific resource keep rule for the dynamically named small icon.
- Run `scripts/verify_release_apk.ps1` after every signed PVT-B build. Inspect the
  final resource table and its actual ZIP entry, not just the source drawable.
  The check rejects the old 1.2.8 APK before this fix.
- Treat a false native initialization result as a retryable failure.
- Show unknown pending counts on read failure instead of the default zero.
- Preserve successfully read history when the native pending-list call fails.
- Display a bounded error code, including a specific invalid-icon explanation,
  rather than attributing every failure to disabled notification permissions.
- Describe pending counts as registered reminders, not proof of OS delivery.

Only the three-minute PVT-B APK is rebuilt and uploaded. The brief APK remains
paused. The backend and recommendation algorithm are unchanged, and existing
accounts/data are not reset. Real-phone immediate and lock-screen scheduled
notification delivery must still be verified after updating.
