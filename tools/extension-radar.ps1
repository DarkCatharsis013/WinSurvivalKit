[CmdletBinding()]
param(
    [string]$Path = '.',
    [switch]$Recurse
)

if (-not (Test-Path -LiteralPath $Path)) {
    throw "Path does not exist: $Path"
}

$files = Get-ChildItem -LiteralPath $Path -File -Force -ErrorAction Stop -Recurse:$Recurse

if (-not $files) {
    Write-Host "No files found." -ForegroundColor Yellow
    exit 0
}

$files |
    Group-Object {
        if ([string]::IsNullOrWhiteSpace($_.Extension)) {
            '[no extension]'
        } else {
            $_.Extension.ToLowerInvariant()
        }
    } |
    ForEach-Object {
        $totalBytes = ($_.Group | Measure-Object -Property Length -Sum).Sum
        [pscustomobject]@{
            Extension = $_.Name
            Count = $_.Count
            TotalMB = [math]::Round($totalBytes / 1MB, 2)
        }
    } |
    Sort-Object -Property @{ Expression = 'TotalMB'; Descending = $true }, @{ Expression = 'Count'; Descending = $true } |
    Format-Table -AutoSize
