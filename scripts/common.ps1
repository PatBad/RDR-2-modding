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

function Get-VsWherePath {
    $path = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $path) { return $path }
    return $null
}

# Install folder of a Visual Studio (or Build Tools) that has the x64 C++ compiler, or $null.
function Get-VcToolsPath {
    $vswhere = Get-VsWherePath
    if (-not $vswhere) { return $null }
    $path = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath |
        Select-Object -First 1
    if ($path) { return $path }
    return $null
}

# CMake from PATH, or the copy that ships with Visual Studio, or $null.
function Find-CMake {
    $cmd = Get-Command cmake -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $vswhere = Get-VsWherePath
    if ($vswhere) {
        $path = & $vswhere -latest -products * -find 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe' |
            Select-Object -First 1
        if ($path) { return $path }
    }
    return $null
}

# Copy-Item into the game folder, explaining the fix when Windows denies access
# (game folders under Program Files can need administrator rights).
function Copy-IntoGameDir([string]$Source, [string]$Destination) {
    try {
        Copy-Item $Source $Destination -Force
    } catch [System.UnauthorizedAccessException] {
        throw "Windows denied access to $Destination. Open PowerShell with 'Run as administrator' and run the script again."
    }
}
