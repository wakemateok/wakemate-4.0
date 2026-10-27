# Retire the temporary one-minute diagnostic, 1.2.11

The user confirmed receiving a phone notification and requested removing the
temporary one-minute reminder test. This does not remove the three-minute PVT-B
assessment or update the paused brief-assessment APK.

- Remove the timed-test button, scheduling method, and follow-up instructions in
  Chinese, English, and Indonesian.
- On notification initialization, cancel only the old diagnostic alarms and
  remove their history entries. Keep caffeine schedules, notification channels,
  permissions, recommendation history, and participant records unchanged.
- Keep the instant notification test, exact-alarm permission check, permission
  request action, inexact-schedule warning, and positive tray confirmation.
- Cleanup errors are optional and must not prevent normal notification setup.

No backend or recommendation-model change is included. The signed universal
PVT-B APK uses the existing production key and replaces the same Drive file.
