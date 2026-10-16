# Hospital Feedback Release 1.2.0+5

Source: the 13-page `wakemate測試.pdf` hospital usage report.
Scope: phone-relevant improvements. Emulator-only OS notification limitations are deferred.

## Report Coverage

| Report | Phone behavior in this release |
| --- | --- |
| p3: readability and first steps | Larger home headings, responsive labels, account-specific task checklist for profile, sleep, wake period and alertness test. The checklist can be dismissed and reopened. |
| p3: calendar summary | Active server records provide daily caffeine mg and sleep hours. Color intensity is relative to that month's records, not a clinical safe/unsafe threshold. Sleep is grouped by wake-up date; overlapping intervals are not counted twice. |
| p3/p7: selected-day recommendations | Home displays that date's current recommendations directly. No fallback to another date. A history icon preserves access to earlier locally retained recommendations. |
| p4: date-driven entry | Tapping a calendar day opens record options already scoped to that date. |
| p6: time entry | Shared 24-hour scrolling date/time picker in caffeine, sleep, wake and history editors. Direct text entry remains available. |
| p7: automatic updates | Returning after a successful record save refreshes records and calculates recommendations automatically. Returning from profile/history also refreshes calculations. An optional refresh icon remains available for recovery. |
| p7: finding a suitable drink | Official-label catalog items are converted to full, 3/4, 1/2 or 1/4 cup portions, ranked by closeness without exceeding the target. Brand filtering is available. The user must explicitly confirm actual consumption before a record is sent. |
| p9: duplicated reminder list | Existing notification deduplication and bounded history are retained; a refresh replaces the schedule rather than appending another copy. |
| p10: held-button shortcut | Existing pointer-down response timing and false-start checks are retained in both tests. |
| p11: test completion | Existing save-and-exit/retry behavior is retained. New localized feedback explains valid responses, false starts, slow responses and self-reported sleepiness without diagnosing disease. |
| p13: saving errors | Existing atomic/idempotent day replacement, duplicate-submit guards and preserved input after failure are retained. If recommendation calculation/readback fails, calendar records remain visible, old recommendations are not presented as current, and the user is told to refresh later. |

All new interface text is available in Traditional Chinese, English and Indonesian.
The recommendation equations, personalization defaults, PVT timing and scoring thresholds were not changed.
Drink conversions use the existing dated official-label catalog, not a live inventory or an extra caffeine prescription.

## Distribution

- Legacy: package `com.example.my_app`, brief alertness test.
- PVT-B: package `com.example.my_app.pvtb`, version label `1.2.0-pvtb`, three-minute alertness test.
- Both: base version `1.2.0`, version code `5`, universal release APK, existing production signing key.
- The apps can coexist. Both can update the corresponding signed 1.1.0 release in place.
- This is a frontend release against the existing authenticated backend. No backend email changes are included.
- Email verification/password-reset delivery remains paused at the user's request.
- No paid cron service is added.

## Verification

```powershell
flutter analyze --no-pub --no-fatal-infos
flutter test --no-pub --dart-define=WAKEMATE_ALERTNESS_MODE=brief --reporter expanded
flutter test --no-pub --dart-define=WAKEMATE_ALERTNESS_MODE=pvtb --reporter expanded
flutter test --no-pub test/hospital_review_widget_test.dart --dart-define=WAKEMATE_ALERTNESS_MODE=brief --dart-define=WAKEMATE_CAPTURE_QA=true
powershell -File scripts/build_signed_apks.ps1
```

The suite includes 100 target-dose portion-conversion cases, Taipei-midnight grouping,
inactive/deleted/edited records, record ownership, missing prerequisites, calculation failure,
three-language small-screen/large-text layouts, date/time wheel selection, explicit intake saving,
KSS-dependent feedback, reminder deduplication and both flavor-specific menus.
The 100 conversion cases are not 100 clinical validations of the recommendation model.

Release checks on 2026-10-16: 189 tests passed in each flavor; static analysis had no errors
or warnings (existing/style informational lints remain). Both APKs passed `apksigner verify`,
with the existing certificate SHA-256
`c30c7e6f904f3699583a7f4ec6533c7843e21b1b7d18c6a82a5094b53fda56b7`.
Both include `armeabi-v7a`, `arm64-v8a` and `x86_64`, with minSdk 24 and targetSdk 36.
The deployed API root returned 200; anonymous recommendation and sleep reads returned 401.

Visual QA capture is opt-in and uses local Windows fonts; normal tests remain portable.
Screenshots are written outside the repository under the local Codex temporary directory.

No physical phone was attached during this release. Lock-screen delivery, battery-vendor
restrictions, real-device touch latency and clinical interpretation still require device/user testing.
Passing automated tests does not establish medical efficacy or guarantee the absence of all bugs.

## Feedback References

- [PsyToolkit PVT-B](https://us.psytoolkit.org/experiment-library/pvtb.html)
- [CDC/NIOSH driver fatigue](https://www.cdc.gov/niosh/motor-vehicle/driver-fatigue/)

The new feedback is descriptive and uses the participant's sleepiness report for a general rest
reminder. It adds no clinical pass/fail cutoff or new caffeine dosing rule.
