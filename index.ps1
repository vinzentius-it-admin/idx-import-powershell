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
    
    :fileloop foreach ($file in $files) {

        $DocType = @("Default", "nix", "nix")       # Reset counters for loop
        $finds = "0"
        $Matches = ""
        $line = ""
        $Fallnr = ""
        $Name = ""
        $Vorname = ""
        $GebDatum = ""
        $count = ""
        $now = Get-Date -format "dd.MM.yyyy hh.mm.ss"

        $baseName = $file.name -replace ".pdf", ""

        $pdfFile = -join ($baseName, ".pdf")
        $idxFile = -join ($baseName, ".idx")
        $txtFile = -join ($baseName, ".txt")
        $okfile = -join ($baseName, ".ok")

        $idxFile = -join ($idxPath, $idxFile)
        $okfile = -join ($idxPath, $okFile)

        $fileName = -join ($txtPath, $txtFile)
        $pdfFileName = -join ($pdfPath, $pdfFile)

        if (-Not (Test-Path $fileName)) {
            continue fileloop
        }
        if (-Not (Test-Path $pdfFileName)) {
            continue fileloop
        }

        Write-Log " " info
        Write-Log "Neu:              $File " info


        # check for docType
        # Arztbrief
        $finds = Select-String -Pattern $ArztbriefPattern $fileName
        
        if (($DocType[0] -eq "Default") -and ($finds.count -gt 2)) {
            $DocType = $ArztbriefDocType
            $count = $finds.count
            write-log "Ergebnis:         $count Treffer vom Dokumententyp Arztbrief in $filename " info
        }

        # Histologie
        $finds = Select-String -Pattern $HistoPattern $fileName
        
        if (($DocType[0] -eq "Default") -and ($finds.count -gt 4)) {
            $DocType = $HistDocType
            $count = $finds.count
            write-log "Ergebnis:         $count Treffer vom Dokumententyp Histologie in $filename " info
        }

        elseif ($DocType[0] -eq "Default") {
            write-Log "Kein Doctype " warn 
            write-log "Docs werden verschoben nach $manualpath und $backupPath" warn
            Copy-Item -Force ${pdfPath}${pdfFile} $manualPath
            Move-Item -Force ${pdfPath}${pdfFile} $backupPath 
            Move-Item -Force $fileName $backupTxtPath
            continue fileloop
        }
        
        # write results out
        switch ( $DocType[2] ) {
            Arztbrief {
                # Fallnummer auf Aufkleber: 7-stellig [Leer] Datum [Leer] ACH
                $line = Select-String -pattern "^(\d{7}|\d{6})\s*\d{2}[.,]\d{2}[.,]\d{4}\s*ACH" $fileName
                # Write-Host $line
                $Matches = ""
 
                if (-not ($line)) {
                    Write-Log "KEINE FALLNUMMER Arztbrief" warn
                    write-log "Verschiebe Dateien nach $manualpath und $backupPath" warn
                    Copy-Item -Force ${pdfPath}${pdfFile} $manualPath
                    Move-Item -Force ${pdfPath}${pdfFile} $backupPath
                    Move-Item -Force $fileName $backupTxtPath 
                    continue fileloop
                }

                # if ([string]$line -Match "(000\d{7}|0000\d{6})") {
                if ([string]$line -Match ":(\d{7}|\d{6})\s*\d{2}[.,]\d{2}[.,]\d{4}\s*") {                
                    $Fallnr = $Matches[1]
                    # $decide = $Fallnr.Substring(3,1)
                    # if ($decide -eq "0") { $Fallnr = $Fallnr.substring(4,6) }
                    # else { $Fallnr = $Fallnr.Substring(3,7) }
                    Write-Log "Fallnummer        $Fallnr" info
                }
                else {
                    Write-Log "Konnte Fallnummer nicht extrahieren aus " warn
                    write-log "$line" warn
                    write-log "Verschiebe Dateien nach $manualpath und $backupPath" warn
                    Copy-Item -Force ${pdfPath}${pdfFile} $manualPath
                    Move-Item -Force ${pdfPath}${pdfFile} $backupPath
                    Move-Item -Force $fileName $backupTxtPath 
                    continue fileloop
                }

                # Name
                # $line = Select-String -Pattern "\w*[,.]\s*\w*[.,]\s*ge[bh][.,]\s*\d{2}[.,]\d{2}[.,]\d{4}" $fileName
                $line = Select-String -Pattern "^\w*[,]\s*\w*" $fileName

                # Entfernen Dr. med. (ungetestet!! )
                # $line = $line -replace "Dr[.,]","Dr"
                # $line = $line -replace "med[,.]",""

                if (-Not ([string]$line -Match ":\d{1,2}:(\w*)[,]\s*(\w*)")) {
                    # Write-Host $line " - nomatch Name, Vorname, geb. in $filename ($Doktype[1])"                
                    Write-Log "$line - nomatch Name, Vorname in $filename ($Doktype[1])" warn
                    continue fileloop
                }

                $Vorname = $Matches[2]
                $Nachname = $Matches[1]
                # $GebDatum = $Matches[3]
                $GebDatum = "01.01.1970"
                Write-Log "Vorname $Vorname" info
                Write-Log "Nachname $Nachname" info
                Write-Log "GebDatum $GebDatum" info

            }

            Histologie {
                # Fallnummer
                $fallPattern = @("Fall-Nr", "Fallnummer")
                $line = Select-String -Pattern $fallPattern $fileName
                Write-Log "Zeile             $line " info
                $Matches = ""

                if (-not ($line)) {
                    Write-Log "KEINE FALLNUMMER Histologie" warn
                    write-log "Verschiebe Dateien nach $manualpath und $backupPath" warn
                    Copy-Item -Force ${pdfPath}${pdfFile} $manualPath
                    Move-Item -Force ${pdfPath}${pdfFile} $backupPath
                    Move-Item -Force $fileName $backupTxtPath 
                    continue fileloop
                }

                # if (-Not ($line -Match "Fall-Nr.: (\d{7}|\d{6})")) {
                if ([string]$line -Match "Fall-Nr.:\s*(\d{7}|\d{6})") {
                    $Fallnr = $Matches[1]
                    Write-Log "Fallnummer        $Fallnr" info
                }
                else {
                    Write-Log "Konnte Fallnummer nicht extrahieren aus " warn
                    write-log "Verschiebe Dateien nach $manualpath und $backupPath" warn
                    Copy-Item -Force ${pdfPath}${pdfFile} $manualPath
                    Move-Item -Force ${pdfPath}${pdfFile} $backupPath
                    Move-Item -Force $fileName $backupTxtPath 
                    continue fileloop
                }                
        
                # Name Vorname
                $line = Select-String -Pattern "Patient.*ge"  $fileName
                $Matches = ""
                # Match auf Patient etc                      
                # if (-Not ([string]$line -Match "Patient.*:\s*\w*(?:\s*\w*)?(?:[,.])?\s*(\w*)(?:[,.])?\s*ge[bh]..*\s*(\w{2}[.,]\w{2}[.,]\w{4})")) {
                if (-Not ([string]$line -Match "Patient.*:.*ge[bh]..*\s*(\w{2}[.,]\w{2}[.,]\w{4})")) {                
                    Write-Log "$line - Keine Treffer für Name, Vorname in $filename ($Doktype[1])" warn
                    continue fileloop
                }
                
                # Entfernen Dr. med. 
                $line = $line -replace "Dr[.,]", "Dr"
                $line = $line -replace "med[,.]", ""
                
                # Nachname, Vorname
                if ([string]$line -Match "Patient.*:\s*(\w*)[,.]\s*(\w*)\s*ge[bh]..*\s*(\w{2}[.,]\w{2}[.,]\w{4})") {
                    Write-Log "Zeile             $line " info
                    $Vorname = $Matches[2]
                    $Nachname = $Matches[1]
                }      # Check: 2 Vornamen
                elseif ([string]$line -Match "Patient.*:\s*(\w*)\s*(\w*)\s*(\w*)?[,.]\s*ge[bh]..*\s*(\w{2}[.,]\w{2}[.,]\w{4})") {
                    Write-Log "Zeile             $line " info
                    if ($matches[3]) {
                        # Drei Namen, 3. ist Nachname
                        $Vorname = -join ($Matches[1], " ", $Matches[2])
                        $Nachname = $Matches[3]
                        $GebDatum = $Matches[4]
                    }
                    else {
                        $Vorname = $Matches[1]
                        $Nachname = $Matches[2]
                        $GebDatum = $Matches[4]
                    }
                }      # Check: Doppelter Vorname
                elseif ([string]$line -Match "Patient.*:\s*(\w*-\w*)\s*(\w*)?[,.]\s*ge[bh]..*\s*(\w{2}[.,]\w{2}[.,]\w{4})") {
                    Write-Log "Zeile             $line " info
                    $Vorname = $Matches[2]
                    $Nachname = $Matches[1]

                }
                else {
                    write-log "Verschiebe Dateien nach $manualpath und $backupPath" warn
                    Copy-Item -Force ${pdfPath}${pdfFile} $manualPath
                    Move-Item -Force ${pdfPath}${pdfFile} $backupPath
                    Move-Item -Force $fileName $backuptxtPath 
                    continue fileloop  
                } 
    
                Write-Log "Vorname           $Vorname" info 
                Write-Log "Nachname          $Nachname" info 
                Write-Log "GebDatum          $GebDatum" info 
            }

            default {
                write-log "seltener Fall: default - loop" warn
                $count_nothing += 1
                continue fileloop
            }

        }
    }

    write-Log "Unzugeordnet:     $count_nothing " info
}