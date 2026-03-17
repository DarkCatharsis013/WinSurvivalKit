[CmdletBinding()]
param(
    [string]$Path = '.',
    [int]$Top = 15,
    [switch]$Recurse
)

if (-not (Test-Path -LiteralPath $Path)) {
    throw "Path does not exist: $Path"
}

$files = Get-ChildItem -LiteralPath $Path -File -Force -ErrorAction Stop -Recurse:$Recurse
$files = $files | Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]'}

if (-not $files) {
    Write-Host "No files found." -ForegroundColor Yellow
    exit 0
}

$files |
    Sort-Object Length -Descending |
    Select-Object -First $Top @{
        Name = 'SizeMB'
        Expression = { [math]::Round($_.Length / 1MB, 2) }
    }, LastWriteTime, FullName |
    Format-Table -Wrap -AutoSize
