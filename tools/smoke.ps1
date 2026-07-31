#Requires -Version 5.1
<#
    Headless verification for hellorogue. No editor, no window.

      .\tools\smoke.ps1          # every script compiles, every scene builds
      .\tools\smoke.ps1 -Deep    # also runs _ready() on every scene (noisy)
      .\tools\smoke.ps1 -Boot    # boots the real main scene for 180 frames

    Set $env:GODOT to override the engine path.
#>
param(
    [switch]$Deep,
    [switch]$Boot
)

$ErrorActionPreference = "Stop"

$godot = $env:GODOT
if (-not $godot) {
    $godot = "C:\Users\zeonb\Desktop\listerine\Godot\gamegodot_v4.2.1-stable_win64.exe\Godot_v4.2.1-stable_win64_console.exe"
}
if (-not (Test-Path $godot)) {
    Write-Host "Godot not found at: $godot" -ForegroundColor Red
    Write-Host "Set `$env:GODOT to the console binary and re-run." -ForegroundColor Red
    exit 2
}

$projectDir = Split-Path -Parent $PSScriptRoot

# Warnings that are artifacts of running without a display, not real problems.
$noise = "Mouse is not supported|ObjectDB instances leaked|Resources still in use"

if ($Boot) {
    Write-Host "== booting main scene (180 frames) ==" -ForegroundColor Cyan
    $out = & $godot --headless --path $projectDir --quit-after 180 2>&1 | Out-String
} else {
    $mode = if ($Deep) { "deep" } else { "shallow" }
    Write-Host "== smoke test ($mode) ==" -ForegroundColor Cyan
    if ($Deep) {
        $out = & $godot --headless --path $projectDir res://tools/smoke_test.tscn -- --deep 2>&1 | Out-String
    } else {
        $out = & $godot --headless --path $projectDir res://tools/smoke_test.tscn 2>&1 | Out-String
    }
}

$lines = $out -split "`r?`n" | Where-Object { $_ -and ($_ -notmatch $noise) }
$lines | ForEach-Object { Write-Host $_ }

# Exit codes are unreliable here (Godot returns 1 on harmless leaks at exit),
# so decide pass/fail by scanning the output for real failures.
$bad = $lines | Where-Object {
    $_ -match "SCRIPT ERROR|Compile Error|Parse Error|SMOKE FAILURE|SMOKE TEST FAILED|Failed to load script"
}

Write-Host ""
if ($bad) {
    Write-Host "FAILED - $($bad.Count) problem(s) above." -ForegroundColor Red
    exit 1
}
Write-Host "PASSED" -ForegroundColor Green
exit 0
