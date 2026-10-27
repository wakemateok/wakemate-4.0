# Reminder diagnostics, 1.2.10

The October 27 phone report confirms that the 17:00 reminder was not visible
in the notification tray at approximately 17:01. The plugin still reported one
pending request. This metadata does not prove that Android holds or delivers
the alarm. No device log was available, so the phone-specific cause remains
unconfirmed.

Confirmed application gaps addressed:

- Exact-alarm errors previously fell back to inexact alarms with the same
  `scheduled` label. The fallback now records `scheduled_inexact` explicitly.
- The notification page checks notification and exact-alarm permissions
  separately, including whether the current language's caffeine notification
  channel is disabled. Special access is requested only after an explicit button press.
- Granting special access retries future pending reminders with their existing
  IDs, without cancelling them first. Overdue reminders are not resurrected.
- A one-minute diagnostic uses the same native `zonedSchedule` path and channel
  as caffeine reminders, without recording intake or recommending a dose.
- A matching Android active notification can provide positive tray confirmation.
  Missing pending metadata, elapsed time, or a successful scheduling call cannot.
- Refresh and resume reload diagnostics. Unknown state remains unknown. This is
  not a claim that a notification was seen by the participant.

The backend, recommendation algorithm, and paused brief app are unchanged.
No automatic battery-policy bypass, full-screen alarm, or persistent background
service was added. Manufacturer battery restrictions and forced-stop behavior
still require a physical-device check.

Phone acceptance: install the signed PVT-B update, open Notifications, allow exact
reminders if offered, schedule the one-minute test, then go to the home screen or
lock the phone. Check the actual notification tray before returning to WakeMate.
If absent, report both permission values, Android version, and phone model.
