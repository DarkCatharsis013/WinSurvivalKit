[CmdletBinding()]
param(
    [ValidateSet('Memory', 'CPU')]
    [string]$SortBy = 'Memory',
    [int]$Top = 15
)

$processes = Get-Process -ErrorAction Stop | Where-Object { $_.Id -ne 0 }

if ($SortBy -eq 'CPU') {
    $rows = $processes |
        Sort-Object CPU -Descending |
        Select-Object -First $Top Name, Id,
            @{ Name = 'CPUSeconds'; Expression = { [math]::Round($_.CPU, 2) } },
            @{ Name = 'MemoryMB'; Expression = { [math]::Round($_.WorkingSet64 / 1MB, 2) } }
} else {
    $rows = $processes |
        Sort-Object WorkingSet64 -Descending |
        Select-Object -First $Top Name, Id,
            @{ Name = 'MemoryMB'; Expression = { [math]::Round($_.WorkingSet64 / 1MB, 2) } },
            @{ Name = 'CPUSeconds'; Expression = { [math]::Round($_.CPU, 2) } }
}

$rows | Format-Table -AutoSize
