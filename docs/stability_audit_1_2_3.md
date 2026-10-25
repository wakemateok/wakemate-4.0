# Stability Audit 1.2.3+8

## Corrected Scope

The local preflight previously blocked all recommendations if any effective sleep/wake records
overlapped, even when that wake period ended months earlier. It now matches the backend rule:
only unfinished wake windows can block current/future calculations. Historical entries remain
visible and unchanged. Ongoing cross-midnight windows are not discarded by date filtering.

Manual calculation still blocks genuine current/future conflicts, and newly entered overlapping
records are still rejected atomically by the backend. Error messages continue to show the relevant
periods in Taipei time in Chinese, English and Indonesian. No numeric model constants, drink
catalog values or alertness-test protocols changed.

The backend also forces explicit manual retries through calculation instead of relying on an old
processed-source marker. It serializes per-user recommendation writes across devices.

## Coverage

Added regression tests cover old conflicts plus valid new recommendations (including leaving and
reopening), 100 mixed old/current conflict cases, adjoining boundaries, offset timestamps and
ongoing cross-midnight periods. Existing save, history, notification, ownership and layout suites
are rerun for both modes. Backend tests additionally compare 100 numeric future results with and
without unrelated historical wake conflicts, including forced retries.

No teacher/participant data is modified for verification. Production smoke tests use a synthetic
account only. No physical phone was attached; lock-screen delivery and vendor battery policies
remain physical-device acceptance checks.
