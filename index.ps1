$configFilePath = "config.json"
$configDistFilePath = "config.json.dist"
$checkFile = Test-Path $configFilePath
if (!$checkFile) {
    Write-Host "Die Konfigurationsdatei $configFilePath konnte nicht gefunden werden. Bitte erstellen Sie eine Konfigurationsdatei mit dem Dateinamen $configFilePath im Wurzelverzeichnis dieser Anwendung. Dafür kann die Datei $configDistFilePath, die ebenfalls im Wurzelverzeichnis liegt, als Vorlage verwendet werden."
    exit 0
}

$linuxfile = Get-Content -Raw -Path $configFilePath | ConvertFrom-Json
foreach ($obj in $linuxfile.patterns[0].value) {
    Write-Host ("Got: " + $obj)
}
