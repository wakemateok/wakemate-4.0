# WakeMate 1.2.8 reminder refresh correction

## Reproduced defect

The previous replacement routine cancelled every native caffeine alarm before
recreating the schedule. When Android had not yet delivered an overdue inexact
alarm, refreshing the app cancelled it. Its history then prevented a duplicate
immediate notification, so the valid reminder disappeared from the native queue.
The regression test fails on 1.2.7: one pending reminder is expected but zero remain.

This is a reproduced code path, not proof of the cause of a particular participant's
missed notification. That diagnosis still needs the phone model, Android version,
expected time, and on-device notification status.

## Change

Preserve a native pending caffeine reminder when its account-specific stable ID,
time, dose text and language still match the current recommendation. A reminder
that is overdue by at most the existing ten-minute grace period can remain queued
for Android delivery. Only changed, removed or stale reminders are cancelled.
Explicit logout, input invalidation and empty replacement still cancel reminders.
History continues to distinguish scheduling from unconfirmed delivery.
Future reminders are re-armed using the same ID, without first cancelling an
unchanged entry. This repairs lost system alarms when reopening the app; the
plugin's pending list is persisted metadata, not proof of an active AlarmManager
entry or actual notification delivery.

## Scope and verification

- Only the three-minute PVT-B APK is rebuilt and uploaded. The brief APK is paused.
- No backend, recommendation model, dose or password-policy changes.
- Test the reproduced delayed-delivery case, 100 unchanged refreshes, reopening,
  changed dose/language/account, equivalent timezone formats, cancellation,
  permission denial and inexact fallback.
- Native queue behavior is simulated through the plugin method channel in tests.
  Lock-screen delivery, phone reboot and manufacturer battery restrictions still
  require an actual device; passing these tests does not prove OS delivery.
