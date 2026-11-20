#Requires -Version 5.1
<#
    DSP SpeedUp - installer
    Copies this folder (BepInEx framework + plugin) into the game root.
    Usage:
        powershell -ExecutionPolicy Bypass -File .\install.ps1
        powershell -ExecutionPolicy Bypass -File .\install.ps1 -GameDir "F:\SteamLibrary\steamapps\common\Dyson Sphere Program"
#>
param(
    [string]$GameDir = ""
)

$ErrorActionPreference = "Stop"
$src = $PSScriptRoot

function Test-GameDir([string]$path) {
    if ([string]::IsNullOrWhiteSpace($path)) { return $false }
    return Test-Path (Join-Path $path "DSPGAME.exe") -PathType Leaf
}

function Add-Candidate([System.Collections.Generic.List[string]]$list, [string]$path) {
    if ([string]::IsNullOrWhiteSpace($path)) { return }
    $path = $path -replace '/', '\'
    if (-not $list.Contains($path)) { $list.Add($path) }
}

$candidates = New-Object System.Collections.Generic.List[string]
Add-Candidate $candidates $GameDir

try {
    $steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -Name SteamPath -ErrorAction Stop).SteamPath
} catch {
    $steamPath = $null
}

if (-not [string]::IsNullOrWhiteSpace($steamPath)) {
    $steamPath = $steamPath -replace '/', '\'
    Add-Candidate $candidates (Join-Path $steamPath "steamapps\common\Dyson Sphere Program")

    $libraryFile = Join-Path $steamPath "steamapps\libraryfolders.vdf"
    if (Test-Path $libraryFile -PathType Leaf) {
        $vdf = Get-Content -Path $libraryFile -Raw
        foreach ($match in [regex]::Matches($vdf, '"path"\s+"([^"]+)"')) {
            $library = $match.Groups[1].Value -replace '\\\\', '\'
            if (Test-Path $library -PathType Container) {
                Add-Candidate $candidates (Join-Path $library "steamapps\common\Dyson Sphere Program")
            }
        }
    }
}

foreach ($root in @("C:\Program Files (x86)\Steam", "C:\Program Files\Steam", "D:\Steam", "D:\SteamLibrary", "E:\SteamLibrary", "F:\SteamLibrary", "G:\SteamLibrary")) {
    if (Test-Path $root -PathType Container) {
        Add-Candidate $candidates (Join-Path $root "steamapps\common\Dyson Sphere Program")
    }
}

$game = $null
foreach ($candidate in $candidates) {
    if (Test-GameDir $candidate) { $game = $candidate; break }
}

if ($null -eq $game) {
    Write-Host ""
    Write-Host "Could not find 'Dyson Sphere Program' automatically." -ForegroundColor Red
    Write-Host "Run the script again with the game folder, for example:"
    Write-Host '  powershell -ExecutionPolicy Bypass -File .\install.ps1 -GameDir "F:\SteamLibrary\steamapps\common\Dyson Sphere Program"'
    exit 1
}

$running = Get-Process -Name DSPGAME -ErrorAction SilentlyContinue
if ($running) {
    Write-Host "DSP is currently running. The files will be installed, but restart the game to load the mod." -ForegroundColor Yellow
}

$framework = Join-Path $game "BepInEx\core\BepInEx.dll"
$pluginSource = Join-Path $src "BepInEx\plugins\DSPSpeedUp\DSPSpeedUp.dll"

if (-not (Test-Path $pluginSource -PathType Leaf)) {
    Write-Host "Package is incomplete: $pluginSource is missing." -ForegroundColor Red
    exit 2
}

if (Test-Path $framework -PathType Leaf) {
    Write-Host "Existing BepInEx detected - installing the plugin only." -ForegroundColor Yellow
    $pluginDir = Join-Path $game "BepInEx\plugins\DSPSpeedUp"
    New-Item -ItemType Directory -Path $pluginDir -Force | Out-Null
    Copy-Item -Path $pluginSource -Destination $pluginDir -Force
} elseif (Test-Path (Join-Path $game "winhttp.dll") -PathType Leaf) {
    Write-Host "winhttp.dll already exists but BepInEx was not found." -ForegroundColor Red
    Write-Host "Another mod loader or a broken BepInEx install may be present. Aborting." -ForegroundColor Red
    exit 3
} else {
    Copy-Item -Path (Join-Path $src "BepInEx") -Destination $game -Recurse -Force
    Copy-Item -Path (Join-Path $src "winhttp.dll") -Destination $game -Force
    Copy-Item -Path (Join-Path $src "doorstop_config.ini") -Destination $game -Force
    if (Test-Path (Join-Path $src ".doorstop_version") -PathType Leaf) {
        Copy-Item -Path (Join-Path $src ".doorstop_version") -Destination $game -Force
    }
}

Write-Host ""
Write-Host "Installed DSP SpeedUp to:" -ForegroundColor Green
Write-Host "  $game"
Write-Host ""
Write-Host "Launch the game and load a save. The HUD should show 'Game Speed x2'."
Write-Host "  F9  = faster"
Write-Host "  F8  = slower"
Write-Host "  F10 = reset to 1x"
Write-Host "  Alt+F8 = show/hide HUD"
Write-Host "Config: BepInEx\config\dsp.speedup.cfg (created on first launch)"
