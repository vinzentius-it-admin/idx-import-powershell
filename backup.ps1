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
$deleteFilesOlderThan = $config.deleteFilesOlderThan

$today = Get-Date -Format dd.MM.yyyy
$limit = (Get-Date).AddDays(-$deleteFilesOlderThan).toString('dd.MM.yyyy')

Clear-Host
Write-Host
Write-Host "# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #"
Write-Host
Write-Host "  DATUM HEUTE                $today                        "
Write-Host
Write-Host "  LÖSCHE DATEIEN ÄLTER ALS   $limit                        "
Write-Host
Write-Host "  DIFFERENZ IN TAGEN         $deleteFilesOlderThan         "
Write-Host
Write-Host "  DATEIEN NICHT LÖSCHEN MIT  -debug                        "
Write-Host
Write-Host "  ACHTUNG: DIESES STAPELVERARBEITUNGSPROGRAMM SOLLTE       "
Write-Host "  SPÄTESTENS ALLE $deleteFilesOlderThan TAGE AUSGEFÜHRT    "
Write-Host "  WERDEN, SONST GEHEN DIE DATEIEN VERLOREN, DIE ZWISCHEN   "
Write-Host "  DER LETZTEN DATENSICHERUNG UND DEM AKTUELLEN DATUMSLIMIT "
Write-Host "  ERZEUGT WURDEN ODER MAN DEAKTIVIERT DIE LÖSCHUNG EINFACH "
Write-Host
Write-Host "# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #"
Write-Host

.\archiveFiles.ps1 `
    -source $backupPdfPath `
    -Target $backupZipPath `
    -ArchiveName "$department-PDF-" `
    -ArchiveGrouping month `
    -extn .pdf `
    -deleteFilesOlderThan $deleteFilesOlderThan `
    -TestMode:$debug

.\archiveFiles.ps1 `
    -source $backupTxtPath `
    -Target $backupZipPath `
    -ArchiveName "$department-TXT-" `
    -ArchiveGrouping month `
    -extn .txt `
    -deleteFilesOlderThan $deleteFilesOlderThan `
    -TestMode:$debug
