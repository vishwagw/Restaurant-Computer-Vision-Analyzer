<#
PowerShell helper to build an NSIS installer for the one-file EXE.

Usage (from project root, after building dist\restaurant_cv_analyzer_desktop.exe):

    .\tools\build_installer.ps1 -ExePath .\dist\restaurant_cv_analyzer_desktop.exe -Version 0.1.0

Requires: NSIS (makensis.exe) on PATH.
#>

param(
    [string]$ExePath = "./dist/restaurant_cv_analyzer_desktop.exe",
    [string]$Version = "0.1.0",
    [string]$Spec = "tools/installer.nsi",
    [string]$IconPath = "",
    [string]$AppExeName = "restaurant_cv_analyzer_desktop.exe"
)

if (-not (Test-Path $ExePath)) {
    Write-Error "Executable not found: $ExePath. Build the onefile EXE first (see README)."
    exit 1
}

$makensis = "makensis"
try {
    $proc = Get-Command $makensis -ErrorAction Stop
} catch {
    Write-Error "makensis (NSIS) not found on PATH. Install NSIS (https://nsis.sourceforge.io/) and ensure makensis.exe is on your PATH."
    exit 2
}

$absExe = (Resolve-Path $ExePath).ProviderPath
$absSpec = (Resolve-Path $Spec).ProviderPath

Write-Output "Building installer from: $absExe"
Write-Output "Using spec: $absSpec"

$defineArgs = @(
    "-DINFILE=\"$absExe\"",
    "-DVERSION=\"$Version\"",
    "-DAPP_EXE_NAME=\"$AppExeName\""
)

if ($IconPath -ne "") {
    if (-not (Test-Path $IconPath)) {
        Write-Error "Icon file not found: $IconPath"
        exit 3
    }
    $absIcon = (Resolve-Path $IconPath).ProviderPath
    $iconName = [System.IO.Path]::GetFileName($absIcon)
    $defineArgs += "-DICON=\"$absIcon\""
    $defineArgs += "-DICON_NAME=\"$iconName\""
}

$args = $defineArgs + @($absSpec)

Write-Output "Calling: makensis $($args -join ' ')"

$start = Start-Process -FilePath $makensis -ArgumentList $args -NoNewWindow -Wait -PassThru
if ($start.ExitCode -ne 0) {
    Write-Error "makensis failed with exit code $($start.ExitCode)"
    exit $start.ExitCode
}

Write-Output "Installer built successfully. See the 'dist' folder for the generated Setup.exe"
