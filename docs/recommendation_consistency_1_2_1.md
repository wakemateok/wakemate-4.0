# Recommendation Consistency Fix 1.2.1+6

Reported symptom: a target wake period appeared to save, a calculation screen reported
HTTP 400 `sleep_wake_overlap`, but returning home still showed a recommendation.

The screenshot alone does not identify the participant's conflicting sleep record.
No participant records were inspected, deleted or automatically corrected for this fix.

## Cause

- Explicit calculation validated all active sleep and wake records, including prior dates.
- Save-triggered and scheduled calculations did not enforce the same precondition.
- Reading recommendations could return active results despite a failed input-consistency check.
- The older calculation page displayed raw API JSON instead of actionable localized information.

## Changes

- Use one half-open interval rule: overlap is invalid, while sleep ending exactly at wake-start is valid.
- Apply the same consistency check to manual calculation, save-triggered calculation,
  scheduled recommendation processing and recommendation reads.
- Block invalid derived results; invalidate future recommendations when calculation is blocked.
- Return the precise conflicting sleep/wake IDs and timestamps, scoped to the signed-in account.
- Keep saving and calculation separate: a valid new record remains saved if older contradictory
  records prevent calculation. A newly conflicting input is rejected without changing original records.
- Preflight active records in the app and refuse stale recommendations after a failed calculation,
  including after navigating away and reopening home.
- Show conflict timestamps in Taipei time and provide an Input history action.
- Localize error messages in Chinese, English and Indonesian; do not expose raw JSON.
- Make the calculation/error view scrollable with safe bottom spacing on small phones.
- Clear future cached recommendations/reminders before an explicit recalculation.

The numeric recommendation equations, doses, thresholds and PVT protocols are unchanged.
Backend changes were made in an isolated checkout so the previously paused email-verification
and password-reset implementation was not included in the deployed code.

## Verification

- Backend: 50 unit/integration tests passed, including the historical-conflict reproduction,
  atomic save rejection, invalidated records, exact boundaries and scheduled-core safety.
- Frontend: 197 tests passed in each alertness flavor; an additional visual run covered the
  localized conflict page at 320px with 1.5x text and 48px bottom navigation space.
- Cloud: 14 checks passed using a separate synthetic account; its sleep and wake source records
  were cleaned up and its session logged out. No participant data was altered.
- The live API exposes `X-WakeMate-Validation: sleep-wake-v2` to confirm the deployed fix.
- Static analysis: no errors or warnings; informational style lints remain.
- Both universal APKs use version code 6 and the existing production signing certificate.

Physical-device notification delivery is not established by these tests. The researcher still
needs to review any actual conflicting records identified by the app; the fix does not invent
or silently change sleep times to obtain a recommendation.
