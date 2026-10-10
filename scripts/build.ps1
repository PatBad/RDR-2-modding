<#
.SYNOPSIS
Builds every mod in mods\ into build\bin\<Config>\<ModName>.asi.
#>
param(
    [ValidateSet('Release', 'Debug')]
    [string]$Config = 'Release'
)
. "$PSScriptRoot\common.ps1"

$cmake = (Get-Command cmake -ErrorAction SilentlyContinue).Source
if (-not $cmake) {
    # Visual Studio ships its own CMake; use it when CMake isn't on PATH.
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $cmake = & $vswhere -latest -products * -find 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe' |
            Select-Object -First 1
    }
}
if (-not $cmake) {
    throw "CMake not found. Install Visual Studio Build Tools with the 'Desktop development with C++' workload (it includes CMake)."
}

$build = Join-Path $RepoRoot 'build'
& $cmake -S $RepoRoot -B $build -A x64
if ($LASTEXITCODE) { exit $LASTEXITCODE }
& $cmake --build $build --config $Config --parallel
if ($LASTEXITCODE) { exit $LASTEXITCODE }

Write-Host "`nBuilt to $(Join-Path $build "bin\$Config")" -ForegroundColor Green
