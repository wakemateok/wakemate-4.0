$ErrorActionPreference = 'Stop'
$secretRoot = Join-Path $env:USERPROFILE '.codex\secrets\wakemate-release'
$keyStore = Join-Path $secretRoot 'wakemate-release.p12'
$credentials = Join-Path $secretRoot 'signing-password.xml'
if ((Test-Path -LiteralPath $keyStore) -or (Test-Path -LiteralPath $credentials)) {
    throw 'Signing material already exists. Do not replace a published signing key.'
}
New-Item -ItemType Directory -Path $secretRoot -Force | Out-Null
$identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
& icacls.exe $secretRoot /inheritance:r /grant:r "${identity}:(OI)(CI)F" 'SYSTEM:(OI)(CI)F' | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Cannot restrict signing directory permissions.' }
$bytes = New-Object byte[] 36
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
$password = [Convert]::ToBase64String($bytes)
$secure = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential('wakemate-release', $secure)
$credential | Export-Clixml -LiteralPath $credentials
$env:WAKEMATE_KEYSTORE_PASSWORD = $password
try {
    & 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe' -genkeypair -noprompt `
        -keystore $keyStore -storetype PKCS12 -alias 'wakemate-release' `
        -storepass:env WAKEMATE_KEYSTORE_PASSWORD -keypass:env WAKEMATE_KEYSTORE_PASSWORD `
        -keyalg RSA -keysize 3072 -sigalg SHA256withRSA -validity 10000 `
        -dname 'CN=WakeMate Release, OU=Application Signing, O=WakeMate, C=TW'
    if ($LASTEXITCODE -ne 0) { throw 'Signing key generation failed.' }
} finally {
    Remove-Item Env:\WAKEMATE_KEYSTORE_PASSWORD -ErrorAction SilentlyContinue
    $password = $null
}
Write-Output "Signing key created in $secretRoot. Password is protected by Windows DPAPI for this user."
Write-Output 'Keep a separate secure backup of BOTH the private key and its password. Do not put either in Git or the APK sharing folder.'
