$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot
Write-Host "Importing Arabic hadith and Quran corpora..." -ForegroundColor Cyan
python tools/import_corpora.py
if ($LASTEXITCODE -ne 0) { throw "Corpus import failed. See the Python error above." }
Write-Host "Running Flutter dependency setup..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed." }
Write-Host "Corpora imported. You can now run: flutter run" -ForegroundColor Green
