# Stability Audit 1.2.2+7

This audit rechecked the 1.2.1 recommendation-consistency fix and the surrounding save/history flow.
The numeric recommendation model and both alertness-test protocols are unchanged.

## Reproduced Issues

- Server-confirmed caffeine, sleep or wake saves could be presented as failures if a subsequent
  local preference write threw. This could encourage users to submit the same record again.
- History GET failures were converted into empty lists, so a network/server error could look
  like missing data. Malformed results were also accepted as empty histories.

Regression tests reproduced these failures before the fixes were applied.

## Fixes

- Remove unused caffeine/sleep local-total writes. The homepage already aggregates server records.
- Treat wake draft-cache reads/writes as optional. A cache failure cannot change a confirmed server
  save into a reported network failure, and an unreadable cache cannot leave the wake form blank.
- History propagates unsuccessful/malformed responses, offers a retry action and only displays
  the empty-state message after successful reads of all three record types.
- Validate history record ownership in the client as an additional guard; the deployed backend
  continues to enforce ownership independently. No real cross-account leak was observed.
- Preserve bottom navigation space for history controls.
- Add injectable HTTP clients for deterministic form/history tests; normal app traffic still uses
  the existing authenticated client.

The preference platform interface is a test-only direct dependency at its already locked version;
no runtime dependency was upgraded. No backend or email-delivery feature changed in this release.

## Verification

- Brief mode: 207 automated tests passed.
- PVT-B mode: 207 automated tests passed.
- Backend: 50 tests passed in the isolated deployed-source checkout.
- Live synthetic-account smoke test: 14 checks passed, including ownership, conflict diagnostics,
  source-record cleanup, stale-result blocking and session revocation.
- Static analysis reported no errors or warnings; existing informational style/deprecation notices
  remain. Ten new regression tests cover the additional failure paths and small-phone layouts.

## Scope and Limits

The audit covers automated failure injection, normal save/read flows, conflicts, date boundaries,
both test flavors and existing notification tests. Passing these tests is not proof of clinical
efficacy, all-device compatibility or lock-screen delivery under vendor battery restrictions.
No physical device was attached during the audit.

The fixes do not assert that every lost non-idempotent HTTP response can be retried without risk;
the removed local-cache failure path is distinct from a connection lost before save confirmation.
