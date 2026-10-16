param([string]$Flutter = 'C:\src\flutter\bin\flutter.bat')
$ErrorActionPreference = 'Stop'
$secretRoot = Join-Path $env:USERPROFILE '.codex\secrets\wakemate-release'
$keyStore = Join-Path $secretRoot 'wakemate-release.p12'
$credential = Import-Clixml -LiteralPath (Join-Path $secretRoot 'signing-password.xml')
if (-not (Test-Path -LiteralPath $keyStore)) { throw 'Release keystore is missing.' }
$repoRoot = Split-Path -Parent $PSScriptRoot
$env:WAKEMATE_KEYSTORE_FILE = $keyStore
$env:WAKEMATE_KEYSTORE_PASSWORD = $credential.GetNetworkCredential().Password
$env:WAKEMATE_KEY_ALIAS = 'wakemate-release'
$env:WAKEMATE_KEY_PASSWORD = $env:WAKEMATE_KEYSTORE_PASSWORD
Push-Location $repoRoot
try {
    foreach ($flavor in @('legacy', 'pvtb')) {
        $mode = if ($flavor -eq 'legacy') { 'brief' } else { 'pvtb' }
        & $Flutter build apk --release --flavor $flavor "--dart-define=WAKEMATE_ALERTNESS_MODE=$mode"
        if ($LASTEXITCODE -ne 0) { throw "APK build failed: $flavor" }
    }
} finally {
    Pop-Location
    foreach ($name in @('WAKEMATE_KEYSTORE_FILE','WAKEMATE_KEYSTORE_PASSWORD','WAKEMATE_KEY_ALIAS','WAKEMATE_KEY_PASSWORD')) {
        Remove-Item "Env:\$name" -ErrorAction SilentlyContinue
    }
}
