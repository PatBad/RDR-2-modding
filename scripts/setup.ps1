<#
.SYNOPSIS
Sets up this PC to build the mods and install them into RDR2.

.DESCRIPTION
Every step checks first and only changes what's missing, so it's safe to run again.

  1. Installs Git, Python 3 and Visual Studio Build Tools (C++) with winget.
  2. Finds the RDR2 folder.
  3. Installs Script Hook RDR2 into the game folder and its SDK into sdk\. It uses
     ScriptHookRDR2*.zip files in your Downloads folder, or downloads them from dev-c.com.
  4. Builds the mods and installs them into the game.

Installers may show a Windows admin prompt; click Yes. Visual Studio Build Tools is a
download of several GB.

.PARAMETER GameDir
The RDR2 folder (the one containing RDR2.exe), if it isn't found automatically.
Saved to game-dir.txt for the other scripts.

.PARAMETER CheckOnly
Report what's installed and what's missing without changing anything.

.PARAMETER NoDeploy
Don't build and install the mods at the end.
#>
param(
    [string]$GameDir,
    [switch]$CheckOnly,
    [switch]$NoDeploy
)
. "$PSScriptRoot\common.ps1"

$ScriptHookPage = 'http://www.dev-c.com/rdr2/scripthookrdr2/'
$WorkDir = Join-Path $env:TEMP 'rdr2-mod-setup'
$results = New-Object System.Collections.Generic.List[object]

function Write-Step([string]$Text) {
    Write-Host "`n== $Text" -ForegroundColor Cyan
}

function Add-Result([string]$Step, [string]$Status, [string]$Detail = '') {
    $results.Add([pscustomobject]@{ Step = $Step; Status = $Status; Detail = $Detail })
    $color = switch ($Status) {
        'OK' { 'Green' }
        'Installed' { 'Green' }
        'Skipped' { 'DarkGray' }
        default { 'Yellow' }
    }
    $line = "[$Status] $Step"
    if ($Detail) { $line += ": $Detail" }
    Write-Host $line -ForegroundColor $color
}

# Reload PATH so tools installed a moment ago can be found without opening a new window.
function Update-SessionPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
        [Environment]::GetEnvironmentVariable('Path', 'User')
}

# Whether the install worked is decided by checking again afterwards, not by winget's exit
# code, which is also non-zero for harmless cases such as "already installed".
function Invoke-Winget([string]$Id, [string[]]$ExtraArgs = @()) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget isn't available. Install 'App Installer' from the Microsoft Store, then run this again."
    }
    Write-Host "Installing $Id with winget. Click Yes if Windows asks for permission."
    & winget install --id $Id --exact --source winget --accept-package-agreements --accept-source-agreements @ExtraArgs |
        Out-Host
    Update-SessionPath
}

# Checks a tool with $Test (returns a description when present, $null when not) and installs
# it with winget when it's missing. Returns $true if the tool is present at the end.
function Install-Tool([string]$Name, [scriptblock]$Test, [string]$WingetId, [string[]]$WingetArgs, [string]$Hint) {
    $found = & $Test
    if ($found) {
        Add-Result $Name 'OK' $found
        return $true
    }
    if ($CheckOnly) {
        Add-Result $Name 'Missing' $Hint
        return $false
    }
    try {
        Invoke-Winget $WingetId $WingetArgs
    } catch {
        Add-Result $Name 'Failed' $_.Exception.Message
        return $false
    }
    $found = & $Test
    if ($found) {
        Add-Result $Name 'Installed' $found
        return $true
    }
    Add-Result $Name 'Failed' $Hint
    return $false
}

function Test-Git {
    $cmd = Get-Command git -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function Test-Python {
    # Native stderr must not become a terminating error here.
    $ErrorActionPreference = 'Continue'
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) { return $null }
    # Windows ships a placeholder python.exe that only points to the Microsoft Store; it fails.
    $version = (& python --version 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -eq 0 -and $version -match '^Python 3') { return $version }
    return $null
}

function Get-DownloadsFolder {
    try {
        $path = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
        if ($path -and (Test-Path $path)) { return $path }
    } catch {
    }
    return (Join-Path $env:USERPROFILE 'Downloads')
}

function Test-ZipFile([string]$Path) {
    if (-not (Test-Path $Path)) { return $false }
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        return ($stream.ReadByte() -eq 0x50) -and ($stream.ReadByte() -eq 0x4B)  # "PK"
    } finally {
        $stream.Dispose()
    }
}

# Newest Script Hook zips in the Downloads folder: @{ Runtime = path; Sdk = path }.
function Find-ScriptHookZips {
    $zips = @(Get-ChildItem (Get-DownloadsFolder) -Filter 'ScriptHookRDR2*.zip' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending)
    $runtime = $zips | Where-Object { $_.Name -notmatch 'SDK' } | Select-Object -First 1
    $sdk = $zips | Where-Object { $_.Name -match 'SDK' } | Select-Object -First 1
    return @{
        Runtime = $(if ($runtime) { $runtime.FullName } else { $null })
        Sdk = $(if ($sdk) { $sdk.FullName } else { $null })
    }
}

# Finds the zip links on the Script Hook page and downloads the kinds asked for
# ('Runtime', 'Sdk'): @{ Runtime = path; Sdk = path }.
function Get-ScriptHookDownloads([string[]]$Kinds) {
    New-Item -ItemType Directory -Force $WorkDir | Out-Null
    [System.Net.ServicePointManager]::SecurityProtocol =
        [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
    $client = New-Object System.Net.WebClient
    Write-Host "Looking for downloads on $ScriptHookPage"
    $page = $client.DownloadString($ScriptHookPage)
    $pageUri = New-Object System.Uri($ScriptHookPage)

    $result = @{ Runtime = $null; Sdk = $null }
    $pattern = 'href\s*=\s*["'']([^"'']*ScriptHookRDR2[^"'']*\.zip)["'']'
    foreach ($match in [regex]::Matches($page, $pattern, 'IgnoreCase')) {
        $uri = New-Object System.Uri($pageUri, $match.Groups[1].Value)
        $kind = if ($uri.AbsolutePath -match 'SDK') { 'Sdk' } else { 'Runtime' }
        if ($Kinds -notcontains $kind -or $result[$kind]) { continue }

        $file = Join-Path $WorkDir ([System.IO.Path]::GetFileName($uri.AbsolutePath))
        Write-Host "Downloading $($uri.AbsoluteUri)"
        $client.Headers['Referer'] = $ScriptHookPage
        $client.DownloadFile($uri, $file)
        if (Test-ZipFile $file) {
            $result[$kind] = $file
        } else {
            Remove-Item $file -ErrorAction SilentlyContinue
        }
    }
    return $result
}

function Expand-Zip([string]$Zip) {
    $dir = Join-Path $WorkDir ([System.IO.Path]::GetFileNameWithoutExtension($Zip))
    if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }
    Expand-Archive -Path $Zip -DestinationPath $dir -Force
    return $dir
}

function Install-ScriptHookRuntime([string]$Zip, [string]$Game) {
    $dir = Expand-Zip $Zip
    foreach ($name in 'ScriptHookRDR2.dll', 'dinput8.dll') {
        if (Test-Path (Join-Path $Game $name)) { continue }
        # version.dll is another ASI loader; two loaders would load every mod twice.
        if ($name -eq 'dinput8.dll' -and (Test-Path (Join-Path $Game 'version.dll'))) { continue }
        $file = Get-ChildItem $dir -Recurse -Filter $name | Select-Object -First 1
        if (-not $file) { throw "$name isn't in $Zip." }
        Copy-IntoGameDir $file.FullName $Game
        Write-Host "Copied $name into $Game"
    }
}

function Install-ScriptHookSdk([string]$Zip) {
    $dir = Expand-Zip $Zip
    $lib = Get-ChildItem $dir -Recurse -Filter 'ScriptHookRDR2.lib' | Select-Object -First 1
    if (-not $lib) { throw "ScriptHookRDR2.lib isn't in $Zip." }
    # Copy the whole SDK (headers and samples are useful reference), then make sure the
    # library is where CMakeLists.txt looks for it.
    $sdkRoot = Split-Path (Split-Path $lib.FullName -Parent) -Parent
    $target = Join-Path $RepoRoot 'sdk'
    New-Item -ItemType Directory -Force (Join-Path $target 'lib') | Out-Null
    Copy-Item (Join-Path $sdkRoot '*') $target -Recurse -Force
    Copy-Item $lib.FullName (Join-Path $target 'lib\ScriptHookRDR2.lib') -Force
    Write-Host "Extracted the SDK into $target"
}

if ($CheckOnly) {
    Write-Host 'Checking only: nothing will be installed or changed.' -ForegroundColor Cyan
}

# --- 1. Tools ---------------------------------------------------------------------------------
Write-Step 'Tools'
Install-Tool 'Git' { Test-Git } 'Git.Git' @() `
    'Install Git from https://git-scm.com/download/win' | Out-Null
Install-Tool 'Python 3' { Test-Python } 'Python.Python.3.13' @() `
    "Install Python 3 from https://www.python.org/downloads/ and tick 'Add python.exe to PATH'. Only the native lookup tools need it." |
    Out-Null
$haveCompiler = Install-Tool 'C++ build tools' { Get-VcToolsPath } 'Microsoft.VisualStudio.2022.BuildTools' `
    @('--override', '--wait --passive --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended') `
    "Install Visual Studio Build Tools with the 'Desktop development with C++' workload. If Build Tools are already installed, open Visual Studio Installer, click Modify and tick that workload."
$haveCMake = Install-Tool 'CMake' { Find-CMake } 'Kitware.CMake' @() `
    'Install CMake from https://cmake.org/download/ (it normally comes with the C++ build tools).'

# --- 2. Game folder ---------------------------------------------------------------------------
Write-Step 'RDR2 folder'
$game = $null
if ($GameDir) {
    if (Test-Path (Join-Path $GameDir 'RDR2.exe')) {
        $GameDir = (Resolve-Path $GameDir).Path
        $env:RDR2_DIR = $GameDir
        if (-not $CheckOnly) { Set-Content -Path (Join-Path $RepoRoot 'game-dir.txt') -Value $GameDir }
    } else {
        Write-Host "RDR2.exe isn't in $GameDir" -ForegroundColor Yellow
    }
}
try {
    $game = Get-GameDir
    Add-Result 'RDR2 folder' 'OK' $game
} catch {
    Add-Result 'RDR2 folder' 'Missing' 'Not found. Run this again with -GameDir "<the folder containing RDR2.exe>".'
}

# --- 3. Script Hook RDR2 and its SDK ----------------------------------------------------------
Write-Step 'Script Hook RDR2'
$sdkLib = Join-Path $RepoRoot 'sdk\lib\ScriptHookRDR2.lib'

function Test-ScriptHookInGame {
    if (-not $game) { return $false }
    $hasHook = Test-Path (Join-Path $game 'ScriptHookRDR2.dll')
    $hasLoader = (Test-Path (Join-Path $game 'dinput8.dll')) -or (Test-Path (Join-Path $game 'version.dll'))
    return $hasHook -and $hasLoader
}

$hadRuntime = Test-ScriptHookInGame
$hadSdk = Test-Path $sdkLib
$needRuntime = $game -and -not $hadRuntime

if (-not $CheckOnly -and ($needRuntime -or -not $hadSdk)) {
    $zips = Find-ScriptHookZips
    if (($needRuntime -and -not $zips.Runtime) -or (-not $hadSdk -and -not $zips.Sdk)) {
        try {
            $kinds = @()
            if ($needRuntime -and -not $zips.Runtime) { $kinds += 'Runtime' }
            if (-not $hadSdk -and -not $zips.Sdk) { $kinds += 'Sdk' }
            $downloaded = Get-ScriptHookDownloads $kinds
            if (-not $zips.Runtime) { $zips.Runtime = $downloaded.Runtime }
            if (-not $zips.Sdk) { $zips.Sdk = $downloaded.Sdk }
        } catch {
            Write-Host "Couldn't download from dev-c.com: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    if ($needRuntime -and $zips.Runtime) {
        if (Get-Process -Name RDR2 -ErrorAction SilentlyContinue) {
            Write-Host 'RDR2 is running, so Script Hook RDR2 cannot be installed. Close the game and run this again.' -ForegroundColor Yellow
        } else {
            try {
                Install-ScriptHookRuntime $zips.Runtime $game
            } catch {
                Write-Host $_.Exception.Message -ForegroundColor Yellow
            }
        }
    }
    if (-not $hadSdk -and $zips.Sdk) {
        try {
            Install-ScriptHookSdk $zips.Sdk
        } catch {
            Write-Host $_.Exception.Message -ForegroundColor Yellow
        }
    }
}

$manualDownload = "Download Script Hook RDR2 and the SDK from $ScriptHookPage into your Downloads folder, then run this again."
if (-not $game) {
    Add-Result 'Script Hook RDR2 in the game' 'Skipped' 'needs the RDR2 folder'
} elseif ($hadRuntime) {
    Add-Result 'Script Hook RDR2 in the game' 'OK'
} elseif (Test-ScriptHookInGame) {
    Add-Result 'Script Hook RDR2 in the game' 'Installed'
} else {
    Add-Result 'Script Hook RDR2 in the game' 'Missing' $manualDownload
}

if ($hadSdk) {
    Add-Result 'Script Hook SDK in sdk\' 'OK'
} elseif (Test-Path $sdkLib) {
    Add-Result 'Script Hook SDK in sdk\' 'Installed'
} else {
    Add-Result 'Script Hook SDK in sdk\' 'Missing' $manualDownload
}

# --- 4. Build and install the mods ------------------------------------------------------------
Write-Step 'Build and install the mods'
if ($CheckOnly -or $NoDeploy) {
    Add-Result 'Build mods' 'Skipped'
} elseif (-not ($haveCompiler -and $haveCMake -and (Test-Path $sdkLib))) {
    Add-Result 'Build mods' 'Skipped' 'needs the C++ build tools, CMake and the SDK'
} else {
    $built = $false
    try {
        & "$PSScriptRoot\build.ps1"
        if ($LASTEXITCODE) { throw 'The build failed; see the errors above.' }
        $built = $true
        Add-Result 'Build mods' 'OK'
    } catch {
        Add-Result 'Build mods' 'Failed' $_.Exception.Message
    }

    if ($built -and (Test-ScriptHookInGame)) {
        try {
            & "$PSScriptRoot\deploy.ps1"
            Add-Result 'Install mods into the game' 'OK'
        } catch {
            Add-Result 'Install mods into the game' 'Failed' $_.Exception.Message
        }
    } elseif ($built) {
        Add-Result 'Install mods into the game' 'Skipped' 'needs the RDR2 folder and Script Hook RDR2'
    }
}

# --- Summary ----------------------------------------------------------------------------------
Write-Host "`n== Summary" -ForegroundColor Cyan
$results | Format-Table -AutoSize -Wrap | Out-String -Width 160 | Write-Host

$problems = @($results | Where-Object { $_.Status -in 'Missing', 'Failed' })
if ($problems.Count -gt 0) {
    Write-Host 'Fix the items marked Missing or Failed, then run this script again.' -ForegroundColor Yellow
    exit 1
}
if (-not $CheckOnly -and -not $NoDeploy) {
    Write-Host "All set. Start RDR2 in Story Mode: 'ExampleMod loaded' appears in the top-left corner. Press F9 and F10 to try it." -ForegroundColor Green
}
exit 0
