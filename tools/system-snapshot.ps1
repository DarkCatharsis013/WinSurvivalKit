[CmdletBinding()]
param()

$os = Get-CimInstance Win32_OperatingSystem
$computer = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$gpus = Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name
$drives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
$ipAddresses = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object {
        $_.IPAddress -notlike '127.*' -and
        $_.PrefixOrigin -ne 'WellKnown'
    } |
    Select-Object -ExpandProperty IPAddress

$uptime = (Get-Date) - $os.LastBootUpTime
$ramGB = [math]::Round($computer.TotalPhysicalMemory / 1GB, 2)

Write-Host "System Snapshot" -ForegroundColor Cyan
Write-Host "---------------"
Write-Host ("Computer : {0}" -f $env:COMPUTERNAME)
Write-Host ("User     : {0}" -f $env:USERNAME)
Write-Host ("OS       : {0}" -f $os.Caption)
Write-Host ("Version  : {0}" -f $os.Version)
Write-Host ("CPU      : {0}" -f $cpu.Name.Trim())
Write-Host ("RAM      : {0} GB" -f $ramGB)
Write-Host ("Uptime   : {0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes)
Write-Host ("GPU      : {0}" -f (($gpus | Where-Object { $_ }) -join '; '))
Write-Host ("IPv4     : {0}" -f (($ipAddresses | Sort-Object -Unique) -join ', '))
Write-Host ""
Write-Host "Disks" -ForegroundColor Cyan

$drives |
    Select-Object DeviceID,
                  VolumeName,
                  @{ Name = 'SizeGB'; Expression = { [math]::Round($_.Size / 1GB, 1) } },
                  @{ Name = 'FreeGB'; Expression = { [math]::Round($_.FreeSpace / 1GB, 1) } } |
    Format-Table -AutoSize
