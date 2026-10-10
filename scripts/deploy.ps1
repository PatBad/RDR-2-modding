<#
.SYNOPSIS
Copies the built .asi files (and their .ini files) into the RDR2 folder. The game must be closed.

.PARAMETER OverwriteIni
Replace .ini files already in the game folder. By default an .ini is only copied when it's
missing, so settings changed in the game folder aren't lost.
#>
param(
    [ValidateSet('Release', 'Debug')]
    [string]$Config = 'Release',
    [switch]$OverwriteIni
)
. "$PSScriptRoot\common.ps1"

$game = Get-GameDir
$bin = Join-Path $RepoRoot "build\bin\$Config"
if (-not (Test-Path $bin)) { throw "Nothing built yet at $bin. Run scripts\build.ps1 first." }

if (Get-Process -Name RDR2 -ErrorAction SilentlyContinue) {
    throw "RDR2 is running. Close the game first: it locks loaded .asi files and only loads mods at startup."
}

if (-not (Test-Path (Join-Path $game 'ScriptHookRDR2.dll'))) {
    Write-Warning "ScriptHookRDR2.dll is missing from $game. Install Script Hook RDR2 from http://www.dev-c.com/rdr2/scripthookrdr2/ or the mods won't load."
}
if (-not ((Test-Path (Join-Path $game 'dinput8.dll')) -or (Test-Path (Join-Path $game 'version.dll')))) {
    Write-Warning "No ASI loader (dinput8.dll, which comes with Script Hook RDR2) in $game. The mods won't load without one."
}

$asis = Get-ChildItem $bin -Filter *.asi
if (-not $asis) { throw "No .asi files in $bin." }

foreach ($asi in $asis) {
    Copy-Item $asi.FullName $game -Force
    Write-Host "Installed $($asi.Name)"

    $ini = Join-Path $bin "$($asi.BaseName).ini"
    $target = Join-Path $game "$($asi.BaseName).ini"
    if ((Test-Path $ini) -and ($OverwriteIni -or -not (Test-Path $target))) {
        Copy-Item $ini $target -Force
        Write-Host "Installed $($asi.BaseName).ini"
    }
}

Write-Host "`nDeployed to $game" -ForegroundColor Green
