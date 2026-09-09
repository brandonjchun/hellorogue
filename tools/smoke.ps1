#Requires -Version 5.1
<#
    Headless verification for hellorogue. No editor, no window.

      .\tools\smoke.ps1            # every script compiles, every scene builds
      .\tools\smoke.ps1 -Tests     # the GUT unit suite
      .\tools\smoke.ps1 -All       # smoke + tests + a real boot   <- use this one
      .\tools\smoke.ps1 -Deep      # also runs _ready() on every scene (noisy)
      .\tools\smoke.ps1 -Boot      # boots the real main scene for 180 frames
      .\tools\smoke.ps1 -Rescan    # rebuild Godot's class-name cache (see below)

    Set $env:GODOT to override the engine path.

    -Rescan: Godot keeps a cache of `class_name` declarations in
    .godot/global_script_class_cache.cfg. GUT tests refer to your classes by
    name, so a test for a BRAND NEW class_name will fail to parse until the
    cache is rebuilt. Note that `--editor --quit` is NOT enough -- it exits
    before the background scan finishes -- which is why this uses --quit-after.
#>
param(
    [switch]$Tests,
    [switch]$Deep,
    [switch]$Boot,
    [switch]$All,
    [switch]$Rescan
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
$noise = "Mouse is not supported|ObjectDB instances leaked|Resources still in use|" +
         "libpng warning|RID allocations of type|were leaked at exit|NativeCommandError|" +
         "CategoryInfo|FullyQualifiedErrorId|^\s*\+|" +
         # Godot prints an `at: ...` source line under each warning above.
         "at: mouse_set_mode|at: cleanup \(core/object|at: clear \(core/io|" +
         # PowerShell decorates native stderr with the calling script's line.
         "^At .*smoke\.ps1:\d+|^\s*$"

# Exit codes are unreliable here (Godot returns 1 on harmless leaks at exit), so
# pass/fail is decided by scanning output for real failures.
$failPattern = "SCRIPT ERROR|Compile Error|Parse Error|SMOKE FAILURE|SMOKE TEST FAILED|" +
               "Failed to load script|Ignoring script|Nothing was run|[1-9][0-9]* failed"

$failures = 0

function Invoke-Stage {
    param([string]$Name, [string[]]$GodotArgs)

    Write-Host ""
    Write-Host "== $Name ==" -ForegroundColor Cyan

    # Godot writes script errors to stderr, so stderr has to be captured. In
    # Windows PowerShell 5.1, `2>&1` on a native exe wraps each stderr line in
    # an ErrorRecord, which a script-scoped "Stop" preference turns into a
    # throw -- so this stage runs under "Continue" and judges the run by its
    # output instead.
    $previous = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $raw = & $godot @GodotArgs 2>&1 | Out-String
    $ErrorActionPreference = $previous
    $lines = $raw -split "`r?`n" | Where-Object { $_ -and ($_ -notmatch $noise) }
    $lines | ForEach-Object { Write-Host $_ }

    $bad = $lines | Where-Object { $_ -match $failPattern }
    if ($bad) {
        Write-Host "-> $Name FAILED ($($bad.Count) problem(s))" -ForegroundColor Red
        $script:failures++
    } else {
        Write-Host "-> $Name ok" -ForegroundColor Green
    }
}

if ($Rescan) {
    Write-Host "== rebuilding class-name cache ==" -ForegroundColor Cyan
    & $godot --headless --path $projectDir --editor --quit-after 1500 2>&1 | Out-Null
    $cache = Join-Path $projectDir ".godot\global_script_class_cache.cfg"
    $count = (Select-String -Path $cache -Pattern '"class":' -AllMatches).Matches.Count
    Write-Host "-> $count class names registered" -ForegroundColor Green
    if (-not ($Tests -or $Deep -or $Boot -or $All)) { exit 0 }
}

# Default to the shallow smoke test when nothing specific was asked for.
$runSmoke = $All -or $Deep -or -not ($Tests -or $Boot)
$runTests = $All -or $Tests
$runBoot  = $All -or $Boot

if ($runSmoke) {
    $smokeArgs = @("--headless", "--path", $projectDir, "res://tools/smoke_test.tscn")
    if ($Deep) { $smokeArgs += @("--", "--deep") }
    Invoke-Stage -Name ("smoke test" + $(if ($Deep) { " (deep)" } else { "" })) -GodotArgs $smokeArgs
}

if ($runTests) {
    Invoke-Stage -Name "unit tests" -GodotArgs @(
        "--headless", "--path", $projectDir,
        "-s", "res://addons/gut/gut_cmdln.gd",
        # -glog=1 prints scripts, totals and failures, but not a line per
        # passing test. Raise it to 2 or 3 when a failure needs context.
        "-gdir=res://test", "-ginclude_subdirs", "-gexit", "-glog=1")
}

if ($runBoot) {
    Invoke-Stage -Name "main scene boot" -GodotArgs @(
        "--headless", "--path", $projectDir, "--quit-after", "180")
}

Write-Host ""
if ($failures -gt 0) {
    Write-Host "FAILED - $failures stage(s) had problems." -ForegroundColor Red
    exit 1
}
Write-Host "PASSED" -ForegroundColor Green
exit 0
