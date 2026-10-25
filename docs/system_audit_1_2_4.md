# System Audit 1.2.4+9

## Reproduced and Fixed

1. Legacy create/history-edit APIs could save overlapping records of the same kind. They now
   serialize validation per user and reject overlaps before invalidating the old record. Adjacent
   periods and inactive history remain valid. The app translates the rejection instead of showing
   an unexplained HTTP code, and allows more time for Render cold starts/calculation.
2. Baseline and personalization circadian hours used the timestamp's representation rather than
   Taipei civil time. The same instant could produce different values when represented as UTC or
   +08:00. Both paths now use Taipei hours; PVT distinct-day counts also use Taipei dates.
3. The existing 300 mg daily recommendation budget reset for each target window. It is now shared
   across all windows on the same Taipei date. Midnight starts a separate daily budget, and dose
   merging no longer transfers tomorrow's amount into yesterday's entry. Earlier planned doses
   are included when modeling later windows. Elapsed, unissued hypothetical doses are not charged
   against future recommendations or simulated as if the participant actually took them.
4. Repeated PVT uploads could reapply trait learning despite reusing the same saved measurement.
   The existing last-trait-update marker now prevents duplicate learning. Per-user locking
   serializes the update. New PVT/parameter versions and deleted source records now participate in
   derived-data freshness checks, so a changed input cannot be skipped as already processed.
5. Successful secure login/token rotation could be reported failed when optional account-cache
   writes failed. Secure storage remains mandatory and authoritative; display-cache failures do
   not invalidate a securely saved session. Secure-storage failures still fail closed.
6. Recommendation-history cache failures could leave a spinner, hide a confirmed result, or
   resurrect unconfirmed cached future recommendations. Confirmed results are passed in memory;
   cache-only entries are historical, not fresh future instructions. Unreadable history offers
   retry, and the empty screen now scrolls safely above the phone navigation area in all 3 languages.
7. Optional homepage/questionnaire caches no longer raise uncaught async errors. OS reminder
   cancellation uses the OS pending list even when its local cache cannot be read or updated.

## Meaning of the Calculation Changes

Model coefficients, the 270 ms target, 25 mg dose step, 6-hour pre-sleep exclusion and 300 mg
recommendation limit are unchanged. However, correcting civil-time interpretation, cross-window
effects and daily accounting can change recommended times/amounts relative to older releases.
The medical/research team must review the changed outputs; automated tests are not clinical
validation. Existing learned parameters are not silently reset or retroactively relearned.

The 300 mg budget retains the existing code's meaning: newly recommended amount. Actual intake
continues to affect the pharmacodynamic model, but this release does not redefine the budget as
an all-source clinical intake limit. That policy needs a separate explicit research decision.

After installing, explicitly recalculate unfinished/future periods to obtain results using the
corrected implementation. Previously issued results are not silently rewritten at deployment.

## Verification and Boundaries

The audit includes injected storage failures, same-kind and sleep/wake conflicts, owner isolation,
100 equivalent-instant comparisons, daily/cross-midnight budgets, PVT retry learning, stale-source
refresh, notification cancellation, and three-language 320px/large-text layouts. Existing full
suites are rerun for both flavors. Production smoke tests use a synthetic account only.

No real participant sleep/wake records or passwords are edited. No physical phone is attached;
lock-screen delivery, vendor battery management and actual participant interaction still require
device acceptance. Email verification/reset and research cross-account roles remain disabled as
previously requested; this release does not turn them on or change paid Render plans.
