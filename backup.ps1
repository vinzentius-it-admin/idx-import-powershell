# Dieses Stapelverarbeitungsprogramm sucht nach Merkmalen und ordnet diese einem Ablageort (Dokumententyp) zu
# Es verschiebt Dokumente nach "$byHandPath" falls eine manuelle Bearbeitung nötig ist
# Durch Ausführen mit dem Argument "-writeidx" wird jeweils eine IDX-Datei erstellt

Param (
    [switch]$keep
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

.\archiveFiles.ps1 -source $backupPdfPath -Target $backupZipPath -ArchiveName "$department-PDF-" -ArchiveGrouping month -extn .pdf -TestMode:$false

#.\archiveFiles.ps1 
#  -source $backupTxtPath 
#  -target $backupZipPath 
#  -ArchiveName "$department-TXT-" 
#  -ArchiveGrouping month 
#  -extn .txt
