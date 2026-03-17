[CmdletBinding()]
param()

$startupFolders = @(
    [pscustomobject]@{
        Source = 'StartupFolder:CurrentUser'
        Path = [Environment]::GetFolderPath('Startup')
    },
    [pscustomobject]@{
        Source = 'StartupFolder:AllUsers'
        Path = [Environment]::GetFolderPath('CommonStartup')
    }
)

$runKeys = @(
    @{ Source = 'Registry:CurrentUser'; Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' },
    @{ Source = 'Registry:LocalMachine'; Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' }
)

$results = @()

foreach ($folder in $startupFolders) {
    if (-not (Test-Path -LiteralPath $folder.Path)) {
        continue
    }

    $results += Get-ChildItem -LiteralPath $folder.Path -Force -ErrorAction SilentlyContinue |
        Select-Object @{ Name = 'Source'; Expression = { $folder.Source } },
                      @{ Name = 'Name'; Expression = { $_.Name } },
                      @{ Name = 'Command'; Expression = { $_.FullName } }
}

foreach ($runKey in $runKeys) {
    if (-not (Test-Path -LiteralPath $runKey.Path)) {
        continue
    }

    $item = Get-ItemProperty -LiteralPath $runKey.Path -ErrorAction SilentlyContinue
    if (-not $item) {
        continue
    }

    foreach ($property in $item.PSObject.Properties) {
        if ($property.Name -in 'PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider') {
            continue
        }

        $results += [pscustomobject]@{
            Source = $runKey.Source
            Name = $property.Name
            Command = [string]$property.Value
        }
    }
}

if (-not $results) {
    Write-Host "No common startup entries found." -ForegroundColor Yellow
    exit 0
}

$results |
    Sort-Object Source, Name |
    Format-Table -Wrap -AutoSize

Write-Host ""
Write-Host "Startup entries found: $($results.Count)" -ForegroundColor Cyan
