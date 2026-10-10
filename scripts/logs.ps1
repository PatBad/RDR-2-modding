<#
.SYNOPSIS
Prints the end of each mod's log and of ScriptHookRDR2.log from the game folder.
#>
param(
    [int]$Lines = 50
)
. "$PSScriptRoot\common.ps1"

$game = Get-GameDir
$names = @(Get-ModNames | ForEach-Object { "$_.log" }) + 'ScriptHookRDR2.log'

foreach ($name in $names) {
    $path = Join-Path $game $name
    Write-Host "===== $name" -ForegroundColor Cyan
    if (Test-Path $path) {
        Write-Host "(last written $((Get-Item $path).LastWriteTime))"
        Get-Content $path -Tail $Lines
    } else {
        Write-Host '(not found)'
    }
    Write-Host ''
}
