# Build script for Windows (PowerShell) - one-file PyInstaller bundle
# Run this from the project root inside the activated virtualenv.

# Ensure pyinstaller is installed: pip install pyinstaller

$spec = "restaurant_cv_analyzer.spec"
if (-not (Test-Path $spec)) {
    Write-Error "Spec file not found: $spec"
    exit 1
}

pyinstaller --onefile --noconfirm $spec

if ($LASTEXITCODE -ne 0) {
    Write-Error "PyInstaller failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Output "Build finished. Bundled executable located in the 'dist' directory." 
Write-Output "Example: .\dist\restaurant_cv_analyzer_desktop.exe" 
