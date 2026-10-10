<#
.SYNOPSIS
Builds every mod in mods\ into build\bin\<Config>\<ModName>.asi.
#>
param(
    [ValidateSet('Release', 'Debug')]
    [string]$Config = 'Release'
)
. "$PSScriptRoot\common.ps1"

$cmake = Find-CMake
if (-not $cmake) {
    throw "CMake not found. Run scripts\setup.ps1, or install Visual Studio Build Tools with the 'Desktop development with C++' workload (it includes CMake)."
}

$build = Join-Path $RepoRoot 'build'
& $cmake -S $RepoRoot -B $build -A x64
if ($LASTEXITCODE) { exit $LASTEXITCODE }
& $cmake --build $build --config $Config --parallel
if ($LASTEXITCODE) { exit $LASTEXITCODE }

Write-Host "`nBuilt to $(Join-Path $build "bin\$Config")" -ForegroundColor Green
