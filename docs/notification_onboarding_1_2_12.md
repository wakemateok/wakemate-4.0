# First-use notification setup, 1.2.12

Android first-use flow: existing welcome/baseline questionnaire prompt, then
notification setup, then login or the authenticated homepage. No setup screen is
shown on web or desktop.

- Check notification access, exact-reminder access, and the current language's
  caffeine notification channel. Create missing channels with the existing
  sound/vibration defaults; never override an existing user's channel choices.
- All checks are read-only with respect to permissions. System prompts/settings
  open only after tapping Set up reminders. Already-allowed steps are skipped.
- Android 13+ uses the notification permission dialog; older Android or a repeated
  request uses app notification settings. Exact access uses the existing plugin
  request. A disabled channel opens that channel's system settings.
- Recheck after returning from settings. Denial never grants access or prevents
  proceeding with Later. Actions stay above phone navigation while status content
  scrolls. Later is available even during a slow initial probe.
- Persist completion or deferral per installation, not per account. Logout keeps
  only this device-level flag alongside the existing language/questionnaire
  preferences, while participant data and sessions are still cleared.
- Cache failures are non-blocking; in-process deferral is remembered. Stale async
  results cannot reopen a dismissed guide or launch a subsequent permission prompt.

The temporary one-minute diagnostic remains removed. The three-minute PVT-B test,
recommendation model, backend, instant test notification, and paused brief APK are
unchanged. No battery exemption, forced screen wake, or silent permission grant
is introduced.

Automated coverage includes Android-version branches, granted/missing/denied
permissions, channels disabled by the user, returning from settings, later and
next launch, logout preservation, storage failure, async disposal, questionnaire
ordering, and Chinese/English/Indonesian layouts at small phone widths. Physical
Android permission dialogs and manufacturer-specific settings still require a
phone check; mocked widget tests do not prove OS notification delivery.
