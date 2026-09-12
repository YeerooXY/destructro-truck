param([string]$Godot = $env:GODOT_BIN)
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
if (-not $Godot) { $Godot = Join-Path $repoRoot '.tools\godot\Godot_v4.7.2-stable_win64_console.exe' }
& (Join-Path $PSScriptRoot 'check.ps1') -Godot $Godot
$outputDir = Join-Path $repoRoot 'builds\windows'
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
& $Godot --headless --path $repoRoot --export-release 'Windows Desktop' (Join-Path $outputDir 'Destructro Truck.exe') 2>&1 | Tee-Object -Variable exportOutput
if ($LASTEXITCODE -ne 0 -or ($exportOutput -match 'SCRIPT ERROR|Export failed')) { throw 'Windows export failed.' }
& $Godot --headless --path $repoRoot --script res://tools/release/write_notices.gd
if ($LASTEXITCODE -ne 0) { throw 'License notices failed.' }
$auditDir = Join-Path $repoRoot '.tools\package-audit'
New-Item -ItemType Directory -Path $auditDir -Force | Out-Null
Set-Content -LiteralPath (Join-Path $auditDir 'project.godot') -Value 'config_version=5' -Encoding UTF8
Copy-Item -LiteralPath (Join-Path $repoRoot 'tools\release\audit_package.gd') -Destination (Join-Path $auditDir 'audit.gd') -Force
& $Godot --headless --path $auditDir --script res://audit.gd -- (Join-Path $outputDir 'Destructro Truck.exe') 2>&1 | Tee-Object -Variable auditOutput
if ($LASTEXITCODE -ne 0 -or -not ($auditOutput -match 'PACKAGE_AUDIT PASS')) { throw 'Exported resource audit failed.' }
$startupStdout = Join-Path $auditDir 'startup.out.log'
$startupStderr = Join-Path $auditDir 'startup.err.log'
$startup = Start-Process -FilePath (Join-Path $outputDir 'Destructro Truck.exe') -ArgumentList @('--headless', '--verbose', '--quit-after', '120') -WorkingDirectory $auditDir -WindowStyle Hidden -RedirectStandardOutput $startupStdout -RedirectStandardError $startupStderr -Wait -PassThru
$startupOutput = (Get-Content -LiteralPath $startupStdout -Raw) + (Get-Content -LiteralPath $startupStderr -Raw)
if ($startup.ExitCode -ne 0 -or $startupOutput -match 'SCRIPT ERROR|Parse Error|ERROR:' -or $startupOutput -notmatch 'Completed load for:.*res://src/bootstrap/main.tscn') { throw "Exported startup failed: $startupOutput" }
Write-Output 'EXPORTED_STARTUP PASS (outside the source directory)'
Copy-Item -LiteralPath (Join-Path $repoRoot 'docs\acceptance\PLAYTEST.md') -Destination (Join-Path $outputDir 'READ ME.txt')
Get-FileHash -LiteralPath (Join-Path $outputDir 'Destructro Truck.exe') -Algorithm SHA256 | Format-List
$packageFiles = @('Destructro Truck.exe', 'READ ME.txt', 'THIRD-PARTY-NOTICES.txt') | ForEach-Object { Join-Path $outputDir $_ }
Compress-Archive -LiteralPath $packageFiles -DestinationPath (Join-Path $repoRoot 'builds\Destructro-Truck-First-Playable.zip') -Force
