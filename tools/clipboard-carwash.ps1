[CmdletBinding()]
param(
    [switch]$TrimLines,
    [switch]$CollapseBlankLines,
    [switch]$WriteBack
)

$text = Get-Clipboard -Raw -ErrorAction Stop

if ([string]::IsNullOrEmpty($text)) {
    Write-Host "Clipboard is empty or does not contain text." -ForegroundColor Yellow
    exit 0
}

$cleaned = $text -replace "`r`n", "`n"
$cleaned = $cleaned -replace "[\u2018\u2019]", "'"
$cleaned = $cleaned -replace "[\u201C\u201D]", '"'

if ($TrimLines) {
    $cleaned = (($cleaned -split "`n") | ForEach-Object { $_.Trim() }) -join "`n"
}

if ($CollapseBlankLines) {
    $cleaned = $cleaned -replace "(`n\s*){3,}", "`n`n"
}

Write-Host "Clipboard preview:" -ForegroundColor Cyan
Write-Output $cleaned

if ($WriteBack) {
    Set-Clipboard -Value $cleaned -ErrorAction Stop
    Write-Host ""
    Write-Host "Cleaned text written back to clipboard." -ForegroundColor Green
}
