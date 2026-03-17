[CmdletBinding()]
param(
    [switch]$Delete,
    [switch]$IncludeWindowsTemp
)

$targets = @(
    [pscustomobject]@{ Name = 'UserTemp'; Path = $env:TEMP }
)

if ($IncludeWindowsTemp) {
    $targets += [pscustomobject]@{ Name = 'WindowsTemp'; Path = Join-Path $env:WINDIR 'Temp' }
}

$summary = foreach ($target in $targets) {
    if (-not (Test-Path -LiteralPath $target.Path)) {
        [pscustomobject]@{
            Location = $target.Name
            Path     = $target.Path
            Files    = 0
            SizeMB   = 0
            Status   = 'Missing'
        }
        continue
    }

    $files = Get-ChildItem -LiteralPath $target.Path -File -Recurse -Force -ErrorAction SilentlyContinue
    $sizeBytes = ($files | Measure-Object -Property Length -Sum).Sum
    if (-not $sizeBytes) {
        $sizeBytes = 0
    }

    [pscustomobject]@{
        Location = $target.Name
        Path     = $target.Path
        Files    = $files.Count
        SizeMB   = [math]::Round($sizeBytes / 1MB, 2)
        Status   = if ($Delete) { 'DeleteRequested' } else { 'Preview' }
    }
}

$summary | Format-Table -AutoSize

if (-not $Delete) {
    Write-Host ""
    Write-Host "Preview only. Re-run with -Delete to remove files from the listed folders." -ForegroundColor Cyan
    exit 0
}

foreach ($target in $targets) {
    if (-not (Test-Path -LiteralPath $target.Path)) {
        continue
    }

    Get-ChildItem -LiteralPath $target.Path -Force -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Cleanup attempt completed." -ForegroundColor Green
