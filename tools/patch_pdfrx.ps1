$ErrorActionPreference = 'Stop'

# Correctif syntaxique complet pour pdfrx 1.3.2 : remplace les deux lignes
# concernées en entier afin de conserver toutes les parenthèses et le point-virgule.
$cacheRoots = @()
if ($env:PUB_CACHE) { $cacheRoots += $env:PUB_CACHE }
if ($env:LOCALAPPDATA) { $cacheRoots += (Join-Path $env:LOCALAPPDATA 'Pub\Cache') }
$cacheRoots = $cacheRoots | Select-Object -Unique

$targets = @()
foreach ($root in $cacheRoots) {
    $hosted = Join-Path $root 'hosted\pub.dev'
    if (Test-Path $hosted) {
        $targets += Get-ChildItem -Path $hosted -Directory -Filter 'pdfrx-1.3.2' -ErrorAction SilentlyContinue
    }
}
if (-not $targets) { throw 'pdfrx 1.3.2 introuvable. Lance d abord : flutter pub get' }

foreach ($target in $targets) {
    $file = Join-Path $target.FullName 'lib\src\pdfium\pdf_file_cache.dart'
    if (-not (Test-Path $file)) { throw "Fichier introuvable : $file" }

    $lines = [System.Collections.Generic.List[string]]::new()
    [System.IO.File]::ReadAllLines($file) | ForEach-Object { $lines.Add($_) }
    $readEndIndex = -1
    $readIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match 'final\s+readEnd\s*=\s*min\(') { $readEndIndex = $i }
        if ($lines[$i] -match 'await\s+cache!?\.read\(') { $readIndex = $i }
    }
    if ($readEndIndex -lt 0 -or $readIndex -lt 0) {
        if (($lines -join "`n") -match 'cache!\.blockSize' -and ($lines -join "`n") -match 'cache!\.read\(') {
            Write-Host 'Les accès cache sont déjà corrigés.' -ForegroundColor Green
            continue
        }
        throw 'Structure pdfrx inattendue : impossible de repérer les deux lignes. Aucun changement effectué.'
    }

    $indent1 = ([regex]::Match($lines[$readEndIndex], '^\s*')).Value
    $indent2 = ([regex]::Match($lines[$readIndex], '^\s*')).Value
    $lines[$readEndIndex] = $indent1 + 'final readEnd = min(p + size, (blockId + 1) * cache!.blockSize);'
    $lines[$readIndex] = $indent2 + 'await cache!.read(buffer, bufferPosition, p, sizeToRead);'

    [System.IO.File]::WriteAllLines($file, $lines, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Correctif pdfrx appliqué : $file" -ForegroundColor Green
}
