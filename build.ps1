param(
    [string]$GodotVersion
)

if (-not $GodotVersion) {
    Write-Host "Usage eg: .\build.ps1 -GodotVersion v4.5-stable"
    exit 1
}

# Resolve project path (script directory)
$ProjectPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $ProjectPath) { $ProjectPath = Get-Location }

Write-Host "Project path: $ProjectPath"

# Read mod.json to detect pack and assembly names
$modJsonPath = Join-Path $ProjectPath 'mod.json'

if (-not (Test-Path -Path $modJsonPath -PathType Leaf)) {
    Write-Host "ERROR: mod.json not found at $modJsonPath"
    exit 1
}

# Read and parse mod.json
$mod = Get-Content -Raw -Path $modJsonPath | ConvertFrom-Json

# mainPck is required
if (-not ($mod.PSObject.Properties.Name -contains 'mainPck' -or $mod.PSObject.Properties.Name -contains 'mainPCK')) {
    Write-Host "ERROR: mod.json missing required field 'mainPck'"
    exit 1
}

$MainPck = if ($mod.PSObject.Properties.Name -contains 'mainPck') { $mod.mainPck } else { $mod.mainPCK }
if ([string]::IsNullOrWhiteSpace($MainPck)) {
    Write-Host "ERROR: mainPck in mod.json is empty"
    exit 1
}

# Derive NAME from mainPck filename (without extension)
try { $NAME = [System.IO.Path]::GetFileNameWithoutExtension($MainPck) } catch { $NAME = $null }
if ([string]::IsNullOrWhiteSpace($NAME)) {
    Write-Host "ERROR: could not determine build name from mainPck: $MainPck"
    exit 1
}

# mainAssembly is optional; if missing, set DLL to $null
if ($mod.PSObject.Properties.Name -contains 'mainAssembly') { $DLL = $mod.mainAssembly }
elseif ($mod.PSObject.Properties.Name -contains 'mainassembly') { $DLL = $mod.mainassembly }
else { $DLL = $null }

Write-Host "Using NAME=$NAME, PCK=$MainPck, DLL=$DLL"

# Check GODOT_INSTALL environment variable
if (-not $env:GODOT_INSTALL) {
    Write-Host "Please set the GODOT_INSTALL environment variable to the path that contains Godot engine folders"
    exit 1
}

# Compose Godot executable path (matches build.bat)
$Godot = Join-Path $env:GODOT_INSTALL "Godot_${GodotVersion}_mono_win64\Godot_${GodotVersion}_mono_win64_console.exe"

if (-not (Test-Path -Path $Godot -PathType Leaf)) {
    Write-Host "Godot $GodotVersion not found at $Godot"
    exit 1
}

# Prepare build folder
$BuildDir = Join-Path $ProjectPath "build\$NAME"
if (Test-Path $BuildDir) {
    Write-Host "Removing existing build folder: $BuildDir"
    Remove-Item -Recurse -Force -LiteralPath $BuildDir
}

New-Item -ItemType Directory -Path $BuildDir | Out-Null

Write-Host "Building project at $ProjectPath with Godot at $Godot"

# Export .pck using Godot headless
$PackPath = Join-Path $BuildDir $MainPck
& $Godot --headless --export-pack 'Windows Desktop' $PackPath
$godotExit = $LASTEXITCODE
if ($godotExit -ne 0) {
    Write-Host "Exporting project failed with exit code $godotExit"
    exit $godotExit
}

# Copy DLL from Godot Mono export temporary location
if ($DLL) {
    $SourceDll = Join-Path $ProjectPath ".godot\mono\temp\bin\ExportRelease\win-x64\$DLL"
    if (-not (Test-Path -Path $SourceDll -PathType Leaf)) {
        Write-Host "Exported DLL not found at $SourceDll"
        exit 1
    }
    Copy-Item -LiteralPath $SourceDll -Destination $BuildDir -Force
} else {
    Write-Host "No DLL to copy (mainAssembly not specified in mod.json)"
}

# Copy mod.json
Copy-Item -LiteralPath $modJsonPath -Destination $BuildDir -Force

# Create zip archive using built-in Compress-Archive (no 7z required)
$ZipPath = Join-Path $ProjectPath "build\$NAME.zip"
try {
    if (Test-Path $ZipPath) { Remove-Item -Force $ZipPath }
    Compress-Archive -Path $BuildDir -DestinationPath $ZipPath -Force
} catch {
    Write-Host "Creating zip failed: $_"
    exit 1
}

# If SIMPLECHESS_MODS_PATH is defined, extract into that folder using Expand-Archive
if ($env:SIMPLECHESS_MODS_PATH) {
    Write-Host "Copying into mods override path: $env:SIMPLECHESS_MODS_PATH"
    try {
        Expand-Archive -Path $ZipPath -DestinationPath $env:SIMPLECHESS_MODS_PATH -Force
    } catch {
        Write-Host "Extracting into mods path failed: $_"
        exit 1
    }
}

Write-Host "Build complete. Output: $ZipPath"
exit 0
