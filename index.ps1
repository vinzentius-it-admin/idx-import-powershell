# matcht Doktype und gibt relevantes auf der Konsole aus; Verschieben von Dokumenten nur in den Manual - Path zur manuellen Bearbeitung
# Schreiben an die Schnittstelle, wenn Argument -writeidx angegeben

Param (
    [Parameter(Mandatory = $false)]
    [switch]$writeidx
)

$configFilePath = "config.json"
$configDistFilePath = "config.json.dist"
$checkFile = Test-Path $configFilePath
if (-not $checkFile) {
    Write-Host "Die Konfigurationsdatei $configFilePath konnte nicht gefunden werden. Bitte erstellen Sie eine Konfigurationsdatei mit dem Dateinamen $configFilePath im Wurzelverzeichnis dieser Anwendung. Dafür kann die Datei $configDistFilePath, die ebenfalls im Wurzelverzeichnis liegt, als Vorlage verwendet werden."
    exit 0
}

$config = Get-Content -Raw -Path $configFilePath | ConvertFrom-Json

# Problem: ggf falsche/keine Fallnummer
$ArztbriefPattern = @($config.patterns[0].value)
$ArztbriefDocType = @($config.docTypes[0].value)

$HistoPattern = @($config.patterns[1].value)
$HistDocType = @($config.docTypes[1].value)

$idxPath = $config.idxPath
$pdfPath = $config.pdfPath               # Quelle PDF
$txtPath = $config.txtPath               # Quelle TXT
$backupTxtPath = $config.backupTxtPath
$backupPath = $config.backupPath
$manualPath = $config.manualPath
$stampPath = $config.stampPath
$idxSrvDir = $config.idxSrvDir

$files = Get-ChildItem $pdfPath -Filter *.pdf

# $Datum = Get-Date -Format yyyy.MM.dd
# $logfile = -join($Datum,".log")
$Datum = Get-Date -Format dd.MM.yyyy

# load helper functions
. ./utils.ps1

# counter for non-assignable cases
$count_nothing = 0


clear-host
write-host " # # # # # # # # # # # # # "
write-host 
write-host "  LOGGING NACH $idxSrvDir "
write-host
write-host "  Zum Schreiben von Indexdateien nach $idxPath "
Write-Host
Write-Host "  Programm starten mit Parameter -writeidx "
Write-Host
write-host " # # # # # # # # # # # # # "


if (-not $files) {
    Write-Log "Keine PDF Files in $pdfpath" warn -shell
    exit 0
}
else {
}