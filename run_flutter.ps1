param(
    [string]$Device = '',
    [switch]$Release
)

$flutter = "E:/Softwares/Flutter/bin/flutter.bat"
$projectPath = "e:/Larawans/FlutterProjects/NetShopFlutter"

if (-not (Test-Path $flutter)) {
    Write-Error "Flutter executable not found at $flutter"
    exit 1
}

Set-Location -Path $projectPath

& $flutter pub get

$runArgs = @('run')
if ($Release) {
    $runArgs += '--release'
}

if ($Device) {
    $runArgs += '-d'
    $runArgs += $Device
}

& $flutter @runArgs
