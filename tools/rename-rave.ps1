[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Path,
    [string]$Filter = '*',
    [string]$Prefix = '',
    [string]$Suffix = '',
    [string]$Find = '',
    [string]$Replace = '',
    [int]$StartNumber = 0,
    [switch]$Apply
)

$items = Get-ChildItem -LiteralPath $Path -File -Filter $Filter -ErrorAction Stop |
    Sort-Object Name

if (-not $items) {
    Write-Host "No files matched." -ForegroundColor Yellow
    exit 0
}

$useNumbering = $PSBoundParameters.ContainsKey('StartNumber')
$index = if ($useNumbering) { $StartNumber } else { 0 }
$plan = foreach ($item in $items) {
    $baseName = $item.BaseName
    if ($Find) {
        $baseName = $baseName -replace [regex]::Escape($Find), $Replace
    }

    $numberPart = if ($useNumbering) {
        '{0:D3}_' -f $index
    } else {
        ''
    }

    $newName = "{0}{1}{2}{3}{4}" -f $Prefix, $numberPart, $baseName, $Suffix, $item.Extension
    $index++

    [pscustomobject]@{
        OldName = $item.Name
        NewName = $newName
        Changed = $item.Name -ne $newName
    }
}

$plan | Format-Table -AutoSize

$duplicateTargets = $plan |
    Group-Object NewName |
    Where-Object Count -gt 1

if ($duplicateTargets) {
    Write-Host ""
    Write-Warning "Rename plan contains duplicate target names. Adjust the options before using -Apply."
    $duplicateTargets | Select-Object Name, Count | Format-Table -AutoSize
    exit 1
}

if (-not $Apply) {
    Write-Host ""
    Write-Host "Preview only. Re-run with -Apply to rename files." -ForegroundColor Cyan
    exit 0
}

foreach ($entry in $plan | Where-Object Changed) {
    Rename-Item -LiteralPath (Join-Path $Path $entry.OldName) -NewName $entry.NewName -ErrorAction Stop
}

Write-Host ""
Write-Host "Renamed $(($plan | Where-Object Changed).Count) file(s)." -ForegroundColor Green
