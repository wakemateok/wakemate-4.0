# UI and Feedback Release 1.2.5+10

## Changes

- Home calendar caffeine and sleep metrics are blank when no corresponding record exists. Recorded values, aggregation and recommendation calculations are unchanged.
- Selected-day summaries omit missing metrics rather than implying zero intake or zero sleep. Calendar row geometry is preserved.
- The home WakeMate title is larger and heavier. Getting-started tasks remain available in the drawer.
- Problem reporting is available from the home toolbar and drawer in Chinese, English and Indonesian.
- Reports support a category, optional subject, required description and optional app-version/test-mode diagnostics.
- The recipient is wakemateok@gmail.com, configurable at build time with WAKEMATE_FEEDBACK_EMAIL.
- Open email launches the device email composer. The user must review and press Send there. The app cannot determine whether the message was sent and never reports successful delivery.
- If a mail app is unavailable, the report can be copied for manual sending. Both launcher and clipboard failures have explicit localized messages.
- Reports do not automatically include account IDs, email addresses, credentials, health records or server logs. A privacy warning discourages including sensitive patient information. Unsent text is kept only in memory, with confirmation before leaving.
- Four logo concepts are saved in design/logo-options-20261026. They have NOT replaced the launcher or official brand assets.

## Scope

No backend, database, calculation coefficients, clinical thresholds, notification timing or account authorization changes are included. Email verification and password-reset delivery remain outside this release.

## Verification

- Legacy/brief: all 238 Flutter tests passed.
- PVT-B: all 238 Flutter tests passed.
- Focused visual run: all 18 feedback/home tests passed, including 320px width, 1.5x text scale, keyboard insets and a 48px navigation reserve.
- Flutter analysis completed with no errors or warnings; 58 pre-existing informational style/deprecation notices remain outside this scope.
- Calendar tests now wait for completed scroll layout before verifying that a day can be hit and selected.
- Mail URI tests cover Unicode, punctuation, line breaks, subject sanitization, recipient isolation and percent-encoded spaces.
- Launcher unavailable/exception, clipboard failure, metadata opt-out, repeated taps, drawer routing and unsent-draft confirmation are covered.
- No real device was attached during these checks. Gmail/other mail-app handoff and actual delivery must still be checked on a phone with a configured email account.

## Distribution

Build both signed universal release flavors using scripts/build_signed_apks.ps1. Preserve the production signing identity and the existing Drive file IDs. Version code 10 updates code 9 without uninstalling when signatures match.

Logo selection and final Android icon preparation require a separate team decision.
