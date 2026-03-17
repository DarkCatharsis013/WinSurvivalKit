[CmdletBinding()]
param(
    [string]$Path = ([Environment]::GetFolderPath('Desktop')),
    [int]$Top = 10
)

if (-not (Test-Path -LiteralPath $Path)) {
    throw "Path does not exist: $Path"
}

$files = Get-ChildItem -LiteralPath $Path -File -Force -ErrorAction Stop

if (-not $files) {
    Write-Host "No files found in $Path." -ForegroundColor Yellow
    exit 0
}

$totalSizeMB = [math]::Round((($files | Measure-Object -Property Length -Sum).Sum) / 1MB, 2)
$byExtension = $files |
    Group-Object {
        if ([string]::IsNullOrWhiteSpace($_.Extension)) { '[no extension]' } else { $_.Extension.ToLowerInvariant() }
    } |
    Sort-Object Count -Descending |
    Select-Object -First 8

Write-Host "Desktop Radar" -ForegroundColor Cyan
Write-Host "-------------"
Write-Host ("Path        : {0}" -f $Path)
Write-Host ("Files       : {0}" -f $files.Count)
Write-Host ("Total Size  : {0} MB" -f $totalSizeMB)
Write-Host ""
Write-Host "Top file types" -ForegroundColor Cyan

$byExtension |
    ForEach-Object {
        [pscustomobject]@{
            Extension = $_.Name
            Count = $_.Count
            TotalMB = [math]::Round((($_.Group | Measure-Object -Property Length -Sum).Sum) / 1MB, 2)
        }
    } |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Largest files" -ForegroundColor Cyan

$files |
    Sort-Object Length -Descending |
    Select-Object -First $Top Name,
        @{ Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) } },
        LastWriteTime |
    Format-Table -AutoSize
