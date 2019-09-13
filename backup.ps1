# Dieses Stapelverarbeitungsprogramm sucht nach Merkmalen und ordnet diese einem Ablageort (Dokumententyp) zu
# Es verschiebt Dokumente nach "$byHandPath" falls eine manuelle Bearbeitung nötig ist
# Durch Ausführen mit dem Argument "-writeidx" wird jeweils eine IDX-Datei erstellt

Param (
    [switch]$debug = $false
)

# load config file
$configFilePath = "config.json"
$configFilePathDist = "config.json.dist"
$checkFile = Test-Path $configFilePath
if (-Not $checkFile) {
    Write-Host "Die Konfigurationsdatei $configFilePath konnte nicht gefunden werden. Bitte erstellen Sie eine Konfigurationsdatei mit dem Dateinamen $configFilePath im Wurzelverzeichnis dieser Anwendung. Dafür kann die Datei $configFilePathDist, die ebenfalls im Wurzelverzeichnis liegt, als Vorlage verwendet werden."
    exit 0
}

# parse config file
$config = Get-Content -Raw -Path $configFilePath | ConvertFrom-Json
$backupPdfPath = $config.backupPdfPath
$backupTxtPath = $config.backupTxtPath
$backupZipPath = $config.backupZipPath
$department = $config.department

# $today = Get-Date
# $limit = (Get-Date).AddDays(-120)
# Write-Host $today
# Write-Host $limit
# exit

.\archiveFiles.ps1 `
    -source $backupPdfPath `
    -Target $backupZipPath `
    -ArchiveName "$department-PDF-" `
    -ArchiveGrouping month `
    -extn .pdf `
    -deleteFilesOlderThan 240 `
    -TestMode:$debug

.\archiveFiles.ps1 `
    -source $backupTxtPath `
    -Target $backupZipPath `
    -ArchiveName "$department-TXT-" `
    -ArchiveGrouping month `
    -extn .txt `
    -deleteFilesOlderThan 120 `
    -TestMode:$debug
