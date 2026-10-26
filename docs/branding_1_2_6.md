# WakeMate Branding Release 1.2.6+11

## Scope

Only the three-minute PVT-B APK is released in this update. Its launcher name is now WakeMate and its symbol is the approved orange/brown W with a coffee bean. The package remains com.example.my_app.pvtb, with the existing production signing identity, so existing signed three-minute installs can update in place.

The brief/legacy build is paused at the user's request. Its main Android resources and existing APK are retained. Its Drive file is not replaced. New Flutter branding is gated by the PVT-B mode.

## Changes

- Five density-specific launcher PNG sets are scoped to android/app/src/pvtb/res.
- Adaptive icon variants support Android 8 and later; Android 13 themed icons receive a monochrome layer.
- Foreground sizing checks the complete alpha silhouette against the 66dp adaptive safe circle, keeping the bean visible through circular masks.
- The three-minute home toolbar includes the new symbol and orange WakeMate wordmark. The login screen uses the approved full logo.
- On the three-minute login page, the register link wraps instead of overflowing on narrow phones with large text. The paused legacy login layout is unchanged.
- The signed APK helper defaults to PVT-B only. Use -Flavors pvtb for this release; legacy must be explicitly requested if resumed later.
- The two-page user guide is updated to WakeMate 1.2.6, includes the new symbol and keeps three-minute instructions only.

## Verification

- Complete PVT-B Flutter suite: 246 tests.
- Focused branding/visual suite: 8 tests, with image decode checks and Chinese/English/Indonesian small-phone layouts.
- The legacy isolation suite checks that the new mark is not enabled in brief mode; PVT-B-only login tests do not apply there.
- Native resource dimensions, transparent assets, adaptive and monochrome references, package suffix and version consistency are covered.
- Circle and rounded-square launcher previews are inspected separately from Flutter UI screenshots.
- No backend, recommendation algorithm, test duration, scoring threshold, account permission or notification scheduling changes are included.
- No physical phone was attached. Real launcher cache refresh and in-place phone installation still need device confirmation.
- Static analysis completed without errors or warnings; 58 pre-existing informational style/deprecation notices remain.
- APK inspection confirms label WakeMate, package com.example.my_app.pvtb, version code 11, and arm64-v8a/armeabi-v7a/x86_64 support.
- Production certificate SHA-256 remains c30c7e6f904f3699583a7f4ec6533c7843e21b1b7d18c6a82a5094b53fda56b7.
- The preserved legacy APK SHA-256 remains 8c21682d70dd170307b8ace3d425321c7fb664c667b6c876c1dac37c74467f95.

## Build

```powershell
.\scripts\build_signed_apks.ps1 -Flavors pvtb
```

Preserve the existing PVT-B Drive file ID and the existing user-guide ID on upload. Do not replace the legacy Drive APK.
