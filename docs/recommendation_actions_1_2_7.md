# WakeMate 1.2.7

## Scope

Only the PVT-B APK is rebuilt and published. The paused brief APK, package IDs,
production signing key, recommendation algorithm, and existing data are unchanged.

## Recommendation Actions

The home screen now has three explicitly labeled commands in Chinese, English,
and Indonesian:

- Generate: manually recalculates, disabled while loading or prerequisites are absent.
- History: opens the selected date's confirmed recommendation records.
- View drinks: opens portion conversions for the selected dose and time.

Saving input still automatically recalculates when returning home. Generation is
an optional manual retry, not an additional required step. Repeated taps during
calculation cannot start another calculation through this button.

## Password Policy Exception

At the project owner's explicit request, registration and password changes no
longer require a minimum character count or mixed character classes. Empty and
whitespace-only passwords remain invalid. The existing 72 UTF-8 byte ceiling
remains, with no silent trimming or truncation of accepted passwords.

This is a usability-driven security relaxation, not a security improvement or a
claim of NIST compliance. Very short passwords are easier to guess. Longer unique
passwords are still recommended, particularly for research data. The existing
Argon2id hashing, database-backed rate limiting, session rotation/revocation, and
per-account data authorization remain in place. Existing passwords are not reset.
New logins with valid short passwords do not require a length-based password
change. Existing sessions already marked for change can sign out and sign in
again to refresh their status; whitespace-only legacy passwords still require change.

The backend change is shared by both app clients, but the paused brief APK's
existing registration UI is not updated by this release.

## Verification

Widget tests exercise 320px and 390px widths with enlarged text and phone navigation
insets in all three languages, distinct destinations, disabled prerequisites, and
repeated calculation taps. Password tests cover one-character values, Unicode,
preserved surrounding spaces, blank inputs, and byte boundaries. The backend
authorization suite continues to cover cross-account blocking and rate limiting.
Physical phone installation and actual OS notification delivery still require a device check.
