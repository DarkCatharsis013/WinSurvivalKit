[CmdletBinding()]
param(
    [int]$Port,
    [switch]$Kill
)

$connections = Get-NetTCPConnection -State Listen -ErrorAction Stop |
    Sort-Object LocalPort, OwningProcess

if ($Port) {
    $connections = $connections | Where-Object { $_.LocalPort -eq $Port }
}

if (-not $connections) {
    Write-Host "No listening TCP connections found." -ForegroundColor Yellow
    exit 0
}

$processMap = @{}
foreach ($process in Get-Process -ErrorAction SilentlyContinue) {
    $processMap[$process.Id] = $process.ProcessName
}

$rows = foreach ($connection in $connections) {
    [pscustomobject]@{
        Port      = $connection.LocalPort
        Address   = $connection.LocalAddress
        PID       = $connection.OwningProcess
        Process   = $processMap[$connection.OwningProcess]
    }
}

$rows | Format-Table -AutoSize

if ($Kill) {
    if (-not $Port) {
        throw "Specify -Port when using -Kill."
    }

    $target = $rows | Select-Object -First 1
    if (-not $target) {
        throw "Nothing is listening on port $Port."
    }

    Write-Warning "Stopping PID $($target.PID) ($($target.Process)) on port $Port."
    Stop-Process -Id $target.PID -Force -ErrorAction Stop
    Write-Host "Process stopped." -ForegroundColor Green
}
