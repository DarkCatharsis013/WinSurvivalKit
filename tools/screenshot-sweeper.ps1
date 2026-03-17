[CmdletBinding()]
param(
    [string]$Path = (Join-Path $env:USERPROFILE 'Pictures\Screenshots'),
    [string[]]$Extensions = @('*.png', '*.jpg', '*.jpeg', '*.bmp', '*.webp'),
    [switch]$Apply
)

if (-not (Test-Path -LiteralPath $Path)) {
    throw "Path does not exist: $Path"
}

$files = foreach ($pattern in $Extensions) {
    Get-ChildItem -LiteralPath $Path -File -Filter $pattern -ErrorAction SilentlyContinue
}

$files = $files | Sort-Object LastWriteTime, Name

if (-not $files) {
    Write-Host "No matching images found." -ForegroundColor Yellow
    exit 0
}

$plan = foreach ($file in $files) {
    $folderName = $file.LastWriteTime.ToString('yyyy-MM-dd')
    $destinationFolder = Join-Path $Path $folderName
    $destinationPath = Join-Path $destinationFolder $file.Name

    [pscustomobject]@{
        File   = $file.Name
        Target = $destinationFolder
        Move   = $file.DirectoryName -ne $destinationFolder
    }
}

$plan | Format-Table -AutoSize

if (-not $Apply) {
    Write-Host ""
    Write-Host "Preview only. Re-run with -Apply to sort the files." -ForegroundColor Cyan
    exit 0
}

foreach ($file in $files) {
    $folderName = $file.LastWriteTime.ToString('yyyy-MM-dd')
    $destinationFolder = Join-Path $Path $folderName
    $destinationPath = Join-Path $destinationFolder $file.Name

    if ($file.DirectoryName -eq $destinationFolder) {
        continue
    }

    if (-not (Test-Path -LiteralPath $destinationFolder)) {
        New-Item -ItemType Directory -Path $destinationFolder | Out-Null
    }

    if (Test-Path -LiteralPath $destinationPath) {
        Write-Warning "Skipping $($file.Name) because the destination already exists."
        continue
    }

    Move-Item -LiteralPath $file.FullName -Destination $destinationPath -ErrorAction Stop
}

Write-Host ""
Write-Host "Sweep complete." -ForegroundColor Green
