# Dieses Stapelverarbeitungsprogramm sucht nach Merkmalen und ordnet diese einem Ablageort (Dokumententyp) zu
# Es verschiebt Dokumente nach "$manualPath" falls eine manuelle Bearbeitung nötig ist
# Durch Ausführen mit dem Argument "-writeidx" wird jeweils eine IDX-Datei erstellt

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
$department = $config.department
$idxPath = $config.idxPath
$pdfPath = $config.pdfPath               # Quelle PDF
$txtPath = $config.txtPath               # Quelle TXT
$backupTxtPath = $config.backupTxtPath
$backupPath = $config.backupPath
$manualPath = $config.manualPath
$stampPath = $config.stampPath
$logsPath = $config.logsPath

$files = Get-ChildItem $pdfPath -Filter *.pdf

# $Datum = Get-Date -Format yyyy.MM.dd
# $logfile = -join($Datum,".log")
$Datum = Get-Date -Format dd.MM.yyyy

# load helper functions
. ./utils.ps1

# counter for non-assignable cases
$count_nothing = 0

Clear-Host
Write-Host
Write-Host "# # # # # # # # # # # # # # # # # # # # # # # # # # # #"
Write-Host
Write-Host "  LOGGING NACH              $logsPath                  "
Write-Host
Write-Host "  IDX-DATEIEN NACH          $idxPath                   "
Write-Host
Write-Host "  SCHREIBEN MIT PARAMETER   -writeidx                  "
Write-Host
Write-Host "# # # # # # # # # # # # # # # # # # # # # # # # # # # #"
Write-Host

if (-not $files) {
    Write-Log "Keine PDF Files in $pdfPath" warn
    exit 0
}
else {
    
    :fileloop foreach ($file in $files) {
        $found = $false
        $topic = ""
        $categories = @("", "")
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

        $txtPathname = -join ($txtPath, $txtFile)
        $pdfPathname = -join ($pdfPath, $pdfFile)

        if (-Not (Test-Path $txtPathname)) {
            continue fileloop
        }
        if (-Not (Test-Path $pdfPathname)) {
            continue fileloop
        }

        foreach ($docType in $config.docTypes) {
            # check for docType
            $finds = Select-String -Pattern $docType.pattern $txtPathname
            if (-Not $found -and $finds.count -gt $docType.gt) {
                $found = $true
                $topic = $docType.topic
                $categories = $docType.category
                $count = $finds.count
            }
        }

        Write-Log " " info $logsPath
        Write-Log " " info $logsPath

        # Write-Host ($file | Format-Table | Out-String)

        if (-Not $found) {
            Write-Log "Typ:              unbekannt " warn $logsPath
            Write-Log "PDF:              $pdfPathname " warn $logsPath
            Write-Log "TXT:              $txtPathname " warn $logsPath
            Write-Log "Kein Dokumententyp zuordenbar " warn $logsPath
            Write-Log "Docs werden verschoben nach $manualPath und $backupPath" warn $logsPath
            Copy-Item -Force $pdfPathname $manualPath
            $count_nothing += 1
            continue fileloop
            #Move-Item -Force $pdfPathname $backupPath 
            #Move-Item -Force $txtPathname $backupTxtPath
        }
        else {
            Write-Log "Typ:              $topic " info $logsPath
            Write-Log "PDF:              $pdfPathname " info $logsPath
            Write-Log "TXT:              $txtPathname " info $logsPath

            # write results out
            switch ( $topic ) {
                Arztbrief {
                    # Fallnummer auf Aufkleber: 7-stellig [Leer] Datum [Leer] ACH
                    $line = Select-String -pattern "^(\d{7}|\d{6})\s*\d{2}[.,]\d{2}[.,]\d{4}\s*ACH" $txtPathname
                    # Write-Host $line
                    $Matches = ""
    
                    if (-not ($line)) {
                        Write-Log "KEINE FALLNUMMER GEFUNDEN IN $txtPathname" warn $logsPath
                        Write-Log "$line" warn $logsPath
                        Write-Log "Verschiebe Dateien nach $manualPath und $backupPath" warn $logsPath
                        Copy-Item -Force $pdfPathname $manualPath
                        Move-Item -Force $pdfPathname $backupPath
                        Move-Item -Force $txtPathname $backupTxtPath 
                        continue fileloop
                    }
    
                    # if ([string]$line -Match "(000\d{7}|0000\d{6})") {
                    if ([string]$line -Match ":(\d{7}|\d{6})\s*\d{2}[.,]\d{2}[.,]\d{4}\s*") {                
                        $Fallnr = $Matches[1]
                        # $decide = $Fallnr.Substring(3,1)
                        # if ($decide -eq "0") { $Fallnr = $Fallnr.substring(4,6) }
                        # else { $Fallnr = $Fallnr.Substring(3,7) }
                        Write-Log "Fallnummer:       $Fallnr" info $logsPath
                    }
                    else {
                        Write-Log "Konnte Fallnummer nicht extrahieren aus $txtPathname" warn $logsPath
                        Write-Log "$line" warn $logsPath
                        Write-Log "Verschiebe Dateien nach $manualPath und $backupPath" warn $logsPath
                        Copy-Item -Force $pdfPathname $manualPath
                        Move-Item -Force $pdfPathname $backupPath
                        Move-Item -Force $txtPathname $backupTxtPath 
                        continue fileloop
                    }
    
                    # Name
                    # $line = Select-String -Pattern "\w*[,.]\s*\w*[.,]\s*ge[bh][.,]\s*\d{2}[.,]\d{2}[.,]\d{4}" $txtPathname
                    $line = Select-String -Pattern "^\w*[,]\s*\w*" $txtPathname
    
                    if (-Not ([string]$line -Match ":\d{1,2}:(\w*)[,]\s*(\w*)")) {
                        Write-Log "Kein Treffer für Name, Vorname in $txtPathname" warn $logsPath
                        Write-Log "$line" warn $logsPath
                        continue fileloop
                    }
    
                    $Vorname = $Matches[2]
                    $Nachname = $Matches[1]
                    $GebDatum = "01.01.1970"
                    Write-Log "Vorname:          $Vorname" info $logsPath
                    Write-Log "Nachname:         $Nachname" info $logsPath
                    Write-Log "Geburtsdatum:     $GebDatum" info $logsPath
    
                }
    
                Histologie {
                    # Fallnummer
                    $fallPattern = @("Fall-Nr", "Fallnummer")
                    $line = Select-String -Pattern $fallPattern $txtPathname
                    $Matches = ""
    
                    if (-not ($line)) {
                        Write-Log "KEINE FALLNUMMER GEFUNDEN IN $txtPathname" warn $logsPath
                        Write-Log "$line" warn $logsPath
                        Write-Log "Verschiebe Dateien nach $manualPath und $backupPath" warn $logsPath
                        Copy-Item -Force $pdfPathname $manualPath
                        Move-Item -Force $pdfPathname $backupPath
                        Move-Item -Force $txtPathname $backupTxtPath 
                        continue fileloop
                    }
    
                    if ([string]$line -Match "Fall-Nr.:\s*(\d{7}|\d{6})") {
                        $Fallnr = $Matches[1]
                        Write-Log "Fallnummer:       $Fallnr" info $logsPath
                    }
                    else {
                        Write-Log "Konnte Fallnummer nicht extrahieren aus $txtPathname" warn $logsPath
                        Write-Log "$line" warn $logsPath
                        Write-Log "Verschiebe Dateien nach $manualPath und $backupPath" warn $logsPath
                        Copy-Item -Force $pdfPathname $manualPath
                        Move-Item -Force $pdfPathname $backupPath
                        Move-Item -Force $txtPathname $backupTxtPath 
                        continue fileloop
                    }                
    
                    # Name Vorname
                    $line = Select-String -Pattern "Patient.*ge"  $txtPathname
                    $Matches = ""
                    # Match auf Patient etc                      
                    # if (-Not ([string]$line -Match "Patient.*:\s*\w*(?:\s*\w*)?(?:[,.])?\s*(\w*)(?:[,.])?\s*ge[bh]..*\s*(\w{2}[.,]\w{2}[.,]\w{4})")) {
                    if (-Not ([string]$line -Match "Patient.*:.*ge[bh]..*\s*(\w{2}[.,]\w{2}[.,]\w{4})")) {                
                        Write-Log "Keine Treffer für Name, Vorname in $txtPathname" warn $logsPath
                        Write-Log "$line" warn $logsPath
                        continue fileloop
                    }
        
                    # Entfernen Dr. med. 
                    $line = $line -replace "Dr[.,]", "Dr"
                    $line = $line -replace "med[,.]", ""
        
                    # Nachname, Vorname
                    if ([string]$line -Match "Patient.*:\s*(\w*)[,.]\s*(\w*)\s*ge[bh]..*\s*(\w{2}[.,]\w{2}[.,]\w{4})") {
                        $Vorname = $Matches[2]
                        $Nachname = $Matches[1]
                    }      # Check: 2 Vornamen
                    elseif ([string]$line -Match "Patient.*:\s*(\w*)\s*(\w*)\s*(\w*)?[,.]\s*ge[bh]..*\s*(\w{2}[.,]\w{2}[.,]\w{4})") {
                        if ($Matches[3]) {
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
                        $Vorname = $Matches[2]
                        $Nachname = $Matches[1]
    
                    }
                    else {
                        Write-Log "Verschiebe Dateien nach $manualPath und $backupPath" warn $logsPath
                        Copy-Item -Force $pdfPathname $manualPath
                        Move-Item -Force $pdfPathname $backupPath
                        Move-Item -Force $txtPathname $backuptxtPath 
                        continue fileloop  
                    } 
    
                    Write-Log "Vorname:          $Vorname" info $logsPath
                    Write-Log "Nachname:         $Nachname" info $logsPath
                    Write-Log "Geburtsdatum:     $GebDatum" info $logsPath
                }
    
                { 
                    "Leistungsbescheid",
                    "Zuzahlungsaufforderung"
                } {
                    # Fallnummer
                    $fallPattern = @("Fall-Nr")
                    $line = Select-String -Pattern $fallPattern $txtPathname
                    $Matches = ""
    
                    if (-not ($line)) {
                        Write-Log "KEINE FALLNUMMER GEFUNDEN IN $txtPathname" warn $logsPath
                        Write-Log "$line" warn $logsPath
                        Write-Log "Verschiebe Dateien nach $manualPath und $backupPath" warn $logsPath
                        Copy-Item -Force $pdfPathname $manualPath
                        Move-Item -Force $pdfPathname $backupPath
                        Move-Item -Force $txtPathname $backupTxtPath 
                        continue fileloop
                    }
    
                    if ([string]$line -Match "Fall-Nr.\s*(\d{7}|\d{6})") {
                        $Fallnr = $Matches[1]
                        Write-Log "Fallnummer:       $Fallnr" info $logsPath
                    }
                    else {
                        Write-Log "Konnte Fallnummer nicht extrahieren aus $txtPathname" warn $logsPath
                        Write-Log "$line" warn $logsPath
                        Write-Log "Verschiebe Dateien nach $manualPath und $backupPath" warn $logsPath
                        Copy-Item -Force $pdfPathname $manualPath
                        Move-Item -Force $pdfPathname $backupPath
                        Move-Item -Force $txtPathname $backupTxtPath 
                        continue fileloop
                    }                

                    # Name, Vorname
                    $line = Select-String -Pattern "\s*Name\s+(\w*(?:-\w*)?)\s*(\w*(?:-\w*)?)\s*" $txtPathname
                    if (-Not ([string]$line -Match "\s*Name\s+(\w*(?:-\w*)?)\s*(\w*(?:-\w*)?)\s*(\w*(?:-\w*)?)?\s*")) {
                        Write-Log "Kein Treffer für Vorname und Name in $txtPathname" warn $logsPath
                        Write-Log "$line" warn $logsPath
                        continue fileloop
                    }

                    if ($Matches[3]) {                # Drei Namen, 3. ist Nachname
                        $Vorname = -join($Matches[1]," ",$Matches[2])
                        $Nachname = $Matches[3]
                    } else {
                        $Vorname = $Matches[1]
                        $Nachname = $Matches[2]
                    }
                    $GebDatum = "01.01.1970"

                    Write-Log "Vorname:          $Vorname" info $logsPath
                    Write-Log "Nachname:         $Nachname" info $logsPath
                    Write-Log "Geburtsdatum:     $GebDatum" info $logsPath
    
                }
    
                default {
                    Write-Log "Seltener Fall. Weiter mit nächsten Datei..." warn $logsPath
                }
    
            }

            # write files
            if ($writeidx) {
                try {
                    Write-IDXFile $department $Fallnr $categories $Nachname $Vorname $GebDatum $Datum $idxfile $idxPath $topic $pdfFile $pdfPath
                }
                catch {
                    Write-Log "Problem mit dem Schreiben von $idxfile" error $logsPath
                    Write-Log "Parameter: $department $Fallnr $categories $Nachname $Vorname $GebDatum $Datum $idxfile $idxPath $topic $pdfFile $pdfPath" error $logsPath
                    Write-Log "Dateien bleiben unberührt; Vorgang abgebrochen" error $logsPath
                    break fileloop
                }
    
                Write-Log "Kopiere           $idxfile nach $okfile" info $logsPath
                Copy-Item $idxfile $okfile
                Write-Log "Verschiebe        $pdfPathname und $txtPathname nach $backupPath " info $logsPath
                #Move-Item -Force $pdfPathname $backupPath
                #Move-Item -Force $txtPathname $backupTxtPath
            }

        }
    }

    Write-Log " " info $logsPath
    Write-Log " " info $logsPath
    Write-Log "Unzugeordnet:     $count_nothing " info $logsPath
}