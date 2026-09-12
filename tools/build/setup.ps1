param([switch]$Templates)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$toolDir = Join-Path $repoRoot '.tools'
New-Item -ItemType Directory -Path $toolDir -Force | Out-Null
$version = '4.7.2'
$enginePath = Join-Path $toolDir 'godot\Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $enginePath)) {
    $zipPath = Join-Path $toolDir 'godot.zip'
    Invoke-WebRequest -Uri "https://downloads.godotengine.org/?version=$version&flavor=stable&slug=win64.exe.zip&platform=windows.64" -OutFile $zipPath -UseBasicParsing
    Expand-Archive -LiteralPath $zipPath -DestinationPath (Join-Path $toolDir 'godot') -Force
}
& $enginePath --version
if ($LASTEXITCODE -ne 0) { throw 'Godot did not start.' }
if ($Templates) {
    $templateDir = Join-Path $env:APPDATA "Godot\export_templates\$version.stable"
    if (-not (Test-Path -LiteralPath (Join-Path $templateDir 'windows_release_x86_64.exe'))) {
        $archivePath = Join-Path $toolDir 'export_templates.tpz'
        Invoke-WebRequest -Uri "https://downloads.godotengine.org/?version=$version&flavor=stable&slug=export_templates.tpz&platform=templates" -OutFile $archivePath -UseBasicParsing
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $archive = [IO.Compression.ZipFile]::OpenRead($archivePath)
        try {
            New-Item -ItemType Directory -Path $templateDir -Force | Out-Null
            foreach ($entry in $archive.Entries) {
                if ($entry.Name -in @('windows_debug_x86_64.exe','windows_release_x86_64.exe','version.txt')) {
                    [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path $templateDir $entry.Name), $true)
                }
            }
        } finally { $archive.Dispose() }
    }
}
Write-Output "Godot ready: $enginePath"
