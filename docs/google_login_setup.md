# Google login setup (Android PVT-B)

Status: backend verification deployed; Android OAuth registration and a
real-device Google login are still required. The teacher-tested Drive APK has
not been replaced while those setup and verification steps are pending.

Local verification on 2026-10-28:

- Flutter PVT-B suite: 337 passed (22 Google service/UI tests included).
- Backend suite: 86 passed (17 Google tests, including local RSA-signed JWTs).
- Analyzer: no errors or warnings, 58 existing informational items.
- Signed universal PVT-B candidate: 1.2.13-pvtb, versionCode 18; Android API 24+;
  arm64-v8a / armeabi-v7a / x86_64; notification drawable guard passed.
- Candidate size: 60,127,163 bytes; SHA-256:
  `F28A65CD0ED8B22FBD6AEEC50FDFA25F72B378D97B31CCEA14A7BB698A33CAB8`.
- Backend commit `a7544f9` deployed live to the existing Render API. The
  team-provided Web OAuth client ID was merged into the existing service
  configuration without replacing other environment variables.
- Production checks: configuration enabled with the expected public ID;
  root 200; anonymous intake/link requests 401; forged Google token 401.
  These checks created no participant accounts.
- No real Google-account authentication or Drive replacement has been done yet.

## Ownership and prerequisites

- Project: `wakemate-513005`, created by the project team.
- Display name: WakeMate.
- Project contact: `wakemateok@gmail.com`.
- Use project-owned admin accounts with MFA and a backup administrator.
- No Gmail, Google Drive, contacts, calendar or health-data API permissions.
- No Firebase, Identity Platform subscription, new database or billing activation
  is required by this implementation.

## Google Auth Platform

1. Open https://console.cloud.google.com/auth/overview?project=wakemate-513005
2. Complete app information, support email, External audience and contact email.
3. While testing, add each tester's Google account under Audience / Test users.
4. Create an OAuth client of type **Web application**, called
   `WakeMate backend`. Its client ID is the Android SDK's `serverClientId` and
   the backend's expected ID-token audience. This native ID-token flow does not
   need a web redirect URL. Do not use a made-up URL or share a client secret.
5. Create an OAuth client of type **Android**, called `WakeMate Android PVT-B`:
   - Package: `com.example.my_app.pvtb`
   - Existing production APK signing certificate SHA-1:
     `3F:15:C0:DB:F8:E6:A7:C8:F7:C3:8D:F2:CE:19:31:D4:53:E8:C0:C0`
6. When publishing through Google Play, register the Play **app signing** SHA-1
   too; it may differ from the directly distributed APK's signing certificate.
   Do not replace the existing signing key or change the Android package name.
7. Before allowing the wider participant group, finish production OAuth/branding
   requirements, privacy notice, applicable website/domain verification and
   audience publishing. Google Play publishing is a separate process.

## Backend activation

Set the Render service's `WAKEMATE_GOOGLE_WEB_CLIENT_ID` to the Web application's
client ID, ending in `.apps.googleusercontent.com`. Do not use the Android
client ID, a project ID, an API key or a client secret. No client secret is needed.

- `GET /auth/google/config`: public, contains only enabled state and public ID.
- Missing/invalid configuration disables Google without affecting password login.
- `POST /auth/google/login`: validates signature, audience, issuer, time claims,
  verified email and Google subject using Google's maintained `google-auth`.
- `POST /auth/google/link`: requires a current WakeMate bearer session AND the
  existing account's password, plus a Google account with the same email.
- Google subject is the account key; a matching email never merges accounts.
- New Google users have no WakeMate password; password login is disabled for
  them, and the password-change entry is hidden. Existing passwords remain valid.
- Existing backend owner scopes, rate limits, secure opaque sessions, refresh
  rotation and logout revocation remain in effect.
- Google ID tokens are not stored in app preferences or returned by the backend.
- Only a new `auth_google_identities` table is added by `create_all`; no existing
  participant records are rewritten. No researcher cross-account access is added.
- No unlink endpoint is offered until account recovery is designed, to prevent
  locking Google-only participants out of their account.

## Required release gates

1. Backend unit/security regression suite and Flutter unit/widget suite pass.
2. Build and verify the signed universal PVT-B APK; legacy stays paused.
3. Actual phone: new Google account, chooser cancellation, existing-account
   collision, explicit linking, password login after linking, restart, sign-out
   and Google re-login. Verify the same WakeMate user ID and old records remain.
4. Verify absence/outage of Google Play services shows a recoverable message.
5. Verify the new Google user can save sleep/wake/intake, calculate and schedule
   reminders. Google sign-in must not reset previously granted permissions.
6. Only then push/redeploy and update the existing Drive APK file, verifying
   size, version, certificate and metadata. Do not claim a real Google login was
   tested based only on mocked SDK calls or locally signed test JWTs.

## References

- https://codelabs.developers.google.com/sign-in-with-google-android
- https://pub.dev/packages/google_sign_in_android
- https://developers.google.com/identity/gsi/web/guides/verify-google-id-token
- https://developers.google.com/identity/branding-guidelines
