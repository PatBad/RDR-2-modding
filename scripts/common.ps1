# Shared helpers, dot-sourced by the other scripts.
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent

# Finds the RDR2 folder (the one containing RDR2.exe).
function Get-GameDir {
    $candidates = @()
    if ($env:RDR2_DIR) { $candidates += $env:RDR2_DIR }
    $file = Join-Path $RepoRoot 'game-dir.txt'
    if (Test-Path $file) { $candidates += (Get-Content $file -TotalCount 1).Trim() }

    $registryKeys = @(
        'HKLM:\SOFTWARE\WOW6432Node\Rockstar Games\Red Dead Redemption 2',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 1174180'
    )
    foreach ($key in $registryKeys) {
        $item = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
        if ($item.InstallFolder) { $candidates += $item.InstallFolder }
        if ($item.InstallLocation) { $candidates += $item.InstallLocation }
    }

    $candidates += @(
        "${env:ProgramFiles(x86)}\Steam\steamapps\common\Red Dead Redemption 2",
        "$env:ProgramFiles\Rockstar Games\Red Dead Redemption 2",
        "$env:ProgramFiles\Epic Games\RedDeadRedemption2"
    )

    foreach ($dir in $candidates) {
        if ($dir -and (Test-Path (Join-Path $dir 'RDR2.exe'))) { return (Resolve-Path $dir).Path }
    }
    throw "Couldn't find RDR2. Write the game folder (the one containing RDR2.exe) into game-dir.txt at the repo root, or set the RDR2_DIR environment variable."
}

function Get-ModNames {
    Get-ChildItem (Join-Path $RepoRoot 'mods') -Directory | ForEach-Object Name
}
