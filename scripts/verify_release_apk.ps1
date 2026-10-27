param(
    [Parameter(Mandatory = $true)]
    [string]$ApkPath,
    [string]$Aapt2 = ''
)
$ErrorActionPreference = 'Stop'
$apk = (Resolve-Path -LiteralPath $ApkPath).Path
if (-not $Aapt2) {
    $sdk = $env:ANDROID_HOME
    if (-not $sdk) { $sdk = $env:ANDROID_SDK_ROOT }
    if (-not $sdk) { $sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
    $buildTools = Get-ChildItem -LiteralPath (Join-Path $sdk 'build-tools') -Directory |
        Where-Object { $_.Name -match '^\d+\.\d+\.\d+$' } |
        Sort-Object { [version]$_.Name } -Descending |
        Select-Object -First 1
    if (-not $buildTools) { throw 'Android build-tools are required to verify the release APK.' }
    $Aapt2 = Join-Path $buildTools.FullName 'aapt2.exe'
}
$resources = & $Aapt2 dump resources $apk 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect release APK resources.' }
$resource = [regex]::Match($resources, '(?ms)^\s*resource\s+0x[0-9a-fA-F]+\s+drawable/ic_notification[^\r\n]*\r?\n(?<details>.*?)(?=^\s*resource\s+0x|^\s*type\s|\z)')
if (-not $resource.Success) {
    throw 'Release APK is missing drawable/ic_notification. Notification initialization would fail.'
}
$file = [regex]::Match($resource.Groups['details'].Value, '\(file\)\s+(?<path>\S+)')
if (-not $file.Success) { throw 'Notification icon has no packaged drawable file.' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead($apk)
try {
    if (-not $zip.GetEntry($file.Groups['path'].Value)) {
        throw 'Notification icon resource points to a missing APK entry.'
    }
} finally {
    $zip.Dispose()
}
Write-Output 'Release notification resource verified: drawable/ic_notification.'
