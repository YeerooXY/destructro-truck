param([string]$Godot = $env:GODOT_BIN)
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
if (-not $Godot) { $Godot = Join-Path $repoRoot '.tools\godot\Godot_v4.7.2-stable_win64_console.exe' }
if (-not (Test-Path -LiteralPath $Godot)) { throw 'Set GODOT_BIN to a Godot 4.7.2 executable, or run tools/build/setup.ps1.' }
Push-Location $repoRoot
try {
    & $Godot --headless --editor --import --path $repoRoot 2>&1 | Tee-Object -Variable importOutput
    if ($LASTEXITCODE -ne 0 -or ($importOutput -match 'SCRIPT ERROR|Parse Error|^ERROR:')) { throw 'Godot import failed.' }
    & $Godot --headless --path $repoRoot --script res://tests/test_runner.gd 2>&1 | Tee-Object -Variable testOutput
    if ($LASTEXITCODE -ne 0 -or ($testOutput -match 'SCRIPT ERROR|Parse Error|^ERROR:') -or -not ($testOutput -match 'TEST_RESULT suites=\d+ failures=0')) { throw 'Unit tests failed.' }
    & $Godot --headless --path $repoRoot --fixed-fps 60 --script res://tests/integration/test_playable.gd 2>&1 | Tee-Object -Variable playableOutput
    if ($LASTEXITCODE -ne 0 -or ($playableOutput -match 'SCRIPT ERROR|Parse Error|^ERROR:') -or -not ($playableOutput -match 'PLAYABLE_TEST failures=0')) { throw 'Playable integration failed.' }
    & $Godot --headless --path $repoRoot --fixed-fps 60 --script res://tests/scenes/gameplay/physics_regression.gd 2>&1 | Tee-Object -Variable physicsOutput
    if ($LASTEXITCODE -ne 0 -or ($physicsOutput -match 'SCRIPT ERROR|Parse Error|^ERROR:') -or -not ($physicsOutput -match 'PHYSICS_RESULT failures=0')) { throw 'Live physics regression failed.' }
    & $Godot --headless --path $repoRoot --fixed-fps 60 --script res://tests/red_team/test_prototype_boundaries.gd 2>&1 | Tee-Object -Variable boundaryOutput
    if ($LASTEXITCODE -ne 0 -or ($boundaryOutput -match 'SCRIPT ERROR|Parse Error|^ERROR:') -or -not ($boundaryOutput -match 'RED_TEAM_PROTOTYPE failures=0')) { throw 'Lifecycle boundary regression failed.' }
} finally { Pop-Location }
