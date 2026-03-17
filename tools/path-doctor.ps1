[CmdletBinding()]
param(
    [ValidateSet('Process', 'User', 'Machine')]
    [string]$Scope = 'Process'
)

switch ($Scope) {
    'Process' { $rawPath = $env:Path }
    'User' { $rawPath = [Environment]::GetEnvironmentVariable('Path', 'User') }
    'Machine' { $rawPath = [Environment]::GetEnvironmentVariable('Path', 'Machine') }
}

if ([string]::IsNullOrWhiteSpace($rawPath)) {
    Write-Host "PATH is empty for scope $Scope." -ForegroundColor Yellow
    exit 0
}

$entries = $rawPath.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
$seen = @{}
$results = foreach ($entry in $entries) {
    $trimmed = $entry.Trim()
    $normalized = $trimmed.Trim('"').TrimEnd('\').ToLowerInvariant()

    $status = @()
    if ($trimmed -match '^".*"$') {
        $status += 'Quoted'
    }
    if (-not (Test-Path -LiteralPath $trimmed.Trim('"'))) {
        $status += 'Missing'
    }
    if ($seen.ContainsKey($normalized)) {
        $status += "DuplicateOf:$($seen[$normalized])"
    } else {
        $seen[$normalized] = $trimmed
    }

    [pscustomobject]@{
        Entry  = $trimmed
        Status = if ($status) { $status -join ', ' } else { 'OK' }
    }
}

$results | Format-Table -Wrap

$problemCount = ($results | Where-Object { $_.Status -ne 'OK' }).Count
Write-Host ""
Write-Host "Checked $($results.Count) PATH entries. Problem entries: $problemCount" -ForegroundColor Cyan
