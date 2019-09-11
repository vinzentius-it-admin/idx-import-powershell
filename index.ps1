# Dieses Stapelverarbeitungsprogramm sucht nach Merkmalen und ordnet diese einem Ablageort (Dokumententyp) zu
# Es verschiebt Dokumente nach "$byHandPath" falls eine manuelle Bearbeitung nötig ist
# Durch Ausführen mit dem Argument "-writeidx" wird jeweils eine IDX-Datei erstellt

Param (
    [Parameter(Mandatory = $false)]
    [switch]$writeidx
)

# load helper functions
. ./utils.ps1

# load config file
$configFilePath = "config.json"
$configDistFilePath = "config.json.dist"
$checkFile = Test-Path $configFilePath
if (-not $checkFile) {
    Write-Host "Die Konfigurationsdatei $configFilePath konnte nicht gefunden werden. Bitte erstellen Sie eine Konfigurationsdatei mit dem Dateinamen $configFilePath im Wurzelverzeichnis dieser Anwendung. Dafür kann die Datei $configDistFilePath, die ebenfalls im Wurzelverzeichnis liegt, als Vorlage verwendet werden."
    exit 0
}

# variables
$files = @()
$count_nothing = 0
$Datum = Get-Date -Format dd.MM.yyyy
$inputPath = ""

# parse config file
$config = Get-Content -Raw -Path $configFilePath | ConvertFrom-Json
$department = $config.department
$idxPath = $config.idxPath
$pdfPath = $config.pdfPath               # Quelle PDF
$txtPath = $config.txtPath               # Quelle TXT
$backupTxtPath = $config.backupTxtPath
$backupPdfPath = $config.backupPdfPath
$byHandPath = $config.byHandPath
$logPath = $config.logPath
$iterateThrough = $config.iterateThrough
$pdfFileExtension = $config.pdfFileExtension
$idxFileExtension = $config.idxFileExtension
$txtFileExtension = $config.txtFileExtension
$okfileExtension = $config.okfileExtension

# validation of config parameters
if (
    [string]::IsNullOrEmpty($iterateThrough) -or
    ($iterateThrough -ne "pdf" -and $iterateThrough -ne "txt")
) {
    Write-Log "Kein (valides) Quellverzeichnis angegeben" warn
    exit 0
}

# fetch files
if ($iterateThrough -eq "pdf") {
    $files = Get-ChildItem $pdfPath -Filter "*.$iterateThrough"
    $inputPath = $pdfPath
}
elseif ($iterateThrough -eq "txt") {
    $files = Get-ChildItem $txtPath -Filter "*.$iterateThrough"
    $inputPath = $txtPath
}

Clear-Host
Write-Host
Write-Host "# # # # # # # # # # # # # # # # # # # # # # # # # # # #"
Write-Host
Write-Host "  LOGGING NACH              $logPath                  "
Write-Host
Write-Host "  INPUT-DATEIEN VON         $inputPath                 "
Write-Host
Write-Host "  IDX-DATEIEN NACH          $idxPath                   "
Write-Host
Write-Host "  SCHREIBEN ÜBER PARAMETER  -writeidx        "
Write-Host
Write-Host "# # # # # # # # # # # # # # # # # # # # # # # # # # # #"
Write-Host

if (-not $files) {
    if ($iterateThrough -eq "pdf") {
        Write-Log "Keine $($iterateThrough.ToUpper())-Dateien in $pdfPath" warn
    }
    elseif ($iterateThrough -eq "txt") {
        Write-Log "Keine $($iterateThrough.ToUpper())-Dateien in $txtPath" warn
    }
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
        $Vorname = ""
        $GebDatum = ""

        if ($iterateThrough -eq "pdf") {
            $baseName = $file.name -replace $pdfFileExtension, ""
        }
        elseif ($iterateThrough -eq "txt") {
            $baseName = $file.name -replace $txtFileExtension, ""
        }

        $pdfFile = -join ($baseName, $pdfFileExtension)
        $idxFile = -join ($baseName, $idxFileExtension)
        $txtFile = -join ($baseName, $txtFileExtension)
        $okfile = -join ($baseName, $okfileExtension)

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
            }
        }

        Write-Log " " info $logPath
        Write-Log " " info $logPath

        # Write-Host ($file | Format-Table | Out-String)

        if (-Not $found) {
            Write-Log "Typ:              UNBEKANNT " warn $logPath
            Write-Log "PDF:              $pdfPathname " warn $logPath
            Write-Log "TXT:              $txtPathname " warn $logPath
            Write-Log "Kein Dokumententyp zuordenbar " warn $logPath
            Write-Log "Docs werden verschoben nach $byHandPath und $backupPdfPath" warn $logPath
            Copy-Item -Force $pdfPathname $byHandPath
            $count_nothing += 1
            continue fileloop
            Move-Item -Force $pdfPathname $backupPdfPath 
            Move-Item -Force $txtPathname $backupTxtPath
        }
        else {
            Write-Log "Typ:              $topic " info $logPath
            Write-Log "PDF:              $pdfPathname " info $logPath
            Write-Log "TXT:              $txtPathname " info $logPath

            # write results out
            switch ( $topic ) {
                Arztbrief {
                    # Fallnummer auf Aufkleber: 7-stellig [Leer] Datum [Leer] ACH
                    $line = Select-String -pattern "^(\d{7}|\d{6})\s*\d{2}[.,]\d{2}[.,]\d{4}\s*ACH" $txtPathname
                    # Write-Host $line
                    $Matches = ""
    
                    if (-not ($line)) {
                        Write-Log "KEINE FALLNUMMER GEFUNDEN IN $txtPathname" warn $logPath
                        Write-Log "$line" warn $logPath
                        Write-Log "Verschiebe Dateien nach $byHandPath und $backupPdfPath" warn $logPath
                        Copy-Item -Force $pdfPathname $byHandPath
                        Move-Item -Force $pdfPathname $backupPdfPath
                        Move-Item -Force $txtPathname $backupTxtPath 
                        continue fileloop
                    }
    
                    # if ([string]$line -Match "(000\d{7}|0000\d{6})") {
                    if ([string]$line -Match ":(\d{7}|\d{6})\s*\d{2}[.,]\d{2}[.,]\d{4}\s*") {                
                        $Fallnr = $Matches[1]
                        # $decide = $Fallnr.Substring(3,1)
                        # if ($decide -eq "0") { $Fallnr = $Fallnr.substring(4,6) }
                        # else { $Fallnr = $Fallnr.Substring(3,7) }
                        Write-Log "Fallnummer:       $Fallnr" info $logPath
                    }
                    else {
                        Write-Log "Konnte Fallnummer nicht extrahieren aus $txtPathname" warn $logPath
                        Write-Log "$line" warn $logPath
                        Write-Log "Verschiebe Dateien nach $byHandPath und $backupPdfPath" warn $logPath
                        Copy-Item -Force $pdfPathname $byHandPath
                        Move-Item -Force $pdfPathname $backupPdfPath
                        Move-Item -Force $txtPathname $backupTxtPath 
                        continue fileloop
                    }
    
                    # Name
                    # $line = Select-String -Pattern "\w*[,.]\s*\w*[.,]\s*ge[bh][.,]\s*\d{2}[.,]\d{2}[.,]\d{4}" $txtPathname
                    $line = Select-String -Pattern "^\w*[,]\s*\w*" $txtPathname
    
                    if (-Not ([string]$line -Match ":\d{1,2}:(\w*)[,]\s*(\w*)")) {
                        Write-Log "Kein Treffer für Name, Vorname in $txtPathname" warn $logPath
                        Write-Log "$line" warn $logPath
                        continue fileloop
                    }
    
                    $Vorname = $Matches[2]
                    $Nachname = $Matches[1]
                    $GebDatum = "01.01.1970"
                    Write-Log "Vorname:          $Vorname" info $logPath
                    Write-Log "Nachname:         $Nachname" info $logPath
                    Write-Log "Geburtsdatum:     $GebDatum" info $logPath
    
                }
    
                Histologie {
                    # Fallnummer
                    $fallPattern = @("Fall-Nr", "Fallnummer")
                    $line = Select-String -Pattern $fallPattern $txtPathname
                    $Matches = ""
    
                    if (-not ($line)) {
                        Write-Log "KEINE FALLNUMMER GEFUNDEN IN $txtPathname" warn $logPath
                        Write-Log "$line" warn $logPath
                        Write-Log "Verschiebe Dateien nach $byHandPath und $backupPdfPath" warn $logPath
                        Copy-Item -Force $pdfPathname $byHandPath
                        Move-Item -Force $pdfPathname $backupPdfPath
                        Move-Item -Force $txtPathname $backupTxtPath 
                        continue fileloop
                    }
    
                    if ([string]$line -Match "Fall-Nr.:\s*(\d{7}|\d{6})") {
                        $Fallnr = $Matches[1]
                        Write-Log "Fallnummer:       $Fallnr" info $logPath
                    }
                    else {
                        Write-Log "Konnte Fallnummer nicht extrahieren aus $txtPathname" warn $logPath
                        Write-Log "$line" warn $logPath
                        Write-Log "Verschiebe Dateien nach $byHandPath und $backupPdfPath" warn $logPath
                        Copy-Item -Force $pdfPathname $byHandPath
                        Move-Item -Force $pdfPathname $backupPdfPath
                        Move-Item -Force $txtPathname $backupTxtPath 
                        continue fileloop
                    }                
    
                    # Name Vorname
                    $line = Select-String -Pattern "Patient.*ge"  $txtPathname
                    $Matches = ""
                    # Match auf Patient etc                      
                    # if (-Not ([string]$line -Match "Patient.*:\s*\w*(?:\s*\w*)?(?:[,.])?\s*(\w*)(?:[,.])?\s*ge[bh]..*\s*(\w{2}[.,]\w{2}[.,]\w{4})")) {
                    if (-Not ([string]$line -Match "Patient.*:.*ge[bh]..*\s*(\w{2}[.,]\w{2}[.,]\w{4})")) {                
                        Write-Log "Keine Treffer für Name, Vorname in $txtPathname" warn $logPath
                        Write-Log "$line" warn $logPath
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
                        Write-Log "Verschiebe Dateien nach $byHandPath und $backupPdfPath" warn $logPath
                        Copy-Item -Force $pdfPathname $byHandPath
                        Move-Item -Force $pdfPathname $backupPdfPath
                        Move-Item -Force $txtPathname $backuptxtPath 
                        continue fileloop  
                    } 
    
                    Write-Log "Vorname:          $Vorname" info $logPath
                    Write-Log "Nachname:         $Nachname" info $logPath
                    Write-Log "Geburtsdatum:     $GebDatum" info $logPath
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
                        Write-Log "KEINE FALLNUMMER GEFUNDEN IN $txtPathname" warn $logPath
                        Write-Log "$line" warn $logPath
                        Write-Log "Verschiebe Dateien nach $byHandPath und $backupPdfPath" warn $logPath
                        Copy-Item -Force $pdfPathname $byHandPath
                        Move-Item -Force $pdfPathname $backupPdfPath
                        Move-Item -Force $txtPathname $backupTxtPath 
                        continue fileloop
                    }
    
                    if ([string]$line -Match "Fall-Nr.\s*(\d{7}|\d{6})") {
                        $Fallnr = $Matches[1]
                        Write-Log "Fallnummer:       $Fallnr" info $logPath
                    }
                    else {
                        Write-Log "Konnte Fallnummer nicht extrahieren aus $txtPathname" warn $logPath
                        Write-Log "$line" warn $logPath
                        Write-Log "Verschiebe Dateien nach $byHandPath und $backupPdfPath" warn $logPath
                        Copy-Item -Force $pdfPathname $byHandPath
                        Move-Item -Force $pdfPathname $backupPdfPath
                        Move-Item -Force $txtPathname $backupTxtPath 
                        continue fileloop
                    }                

                    # Name, Vorname
                    $line = Select-String -Pattern "\s*Name\s+(\w*(?:-\w*)?)\s*(\w*(?:-\w*)?)\s*" $txtPathname
                    if (-Not ([string]$line -Match "\s*Name\s+(\w*(?:-\w*)?)\s*(\w*(?:-\w*)?)\s*(\w*(?:-\w*)?)?\s*")) {
                        Write-Log "Kein Treffer für Vorname und Name in $txtPathname" warn $logPath
                        Write-Log "$line" warn $logPath
                        continue fileloop
                    }

                    # Drei Namen, 3. ist Nachname
                    if ($Matches[3] -and $Matches[3] -ne "Fall-Nr") {
                        $Vorname = -join ($Matches[1], " ", $Matches[2])
                        $Nachname = $Matches[3]
                    }
                    else {
                        $Vorname = $Matches[1]
                        $Nachname = $Matches[2]
                    }
                    $GebDatum = "01.01.1970"

                    Write-Log "Vorname:          $Vorname" info $logPath
                    Write-Log "Nachname:         $Nachname" info $logPath
                    Write-Log "Geburtsdatum:     $GebDatum" info $logPath
    
                }
    
                default {
                    Write-Log "Seltener Fall. Weiter mit nächsten Datei..." warn $logPath
                }
    
            }

            # write files
            if ($writeidx) {
                try {
                    Write-IDXFile $department $Fallnr $categories $Nachname $Vorname $GebDatum $Datum $idxfile $idxPath $topic $pdfFile $pdfPath
                }
                catch {
                    Write-Log "Problem mit dem Schreiben von $idxfile" error $logPath
                    Write-Log "Parameter: $department $Fallnr $categories $Nachname $Vorname $GebDatum $Datum $idxfile $idxPath $topic $pdfFile $pdfPath" error $logPath
                    Write-Log "Dateien bleiben unberührt; Vorgang abgebrochen" error $logPath
                    break fileloop
                }
    
                Write-Log "Kopiere           $idxfile nach $okfile" info $logPath
                Copy-Item $idxfile $okfile
                Write-Log "Verschiebe        $pdfPathname und $txtPathname nach $backupPdfPath " info $logPath
                Move-Item -Force $pdfPathname $backupPdfPath
                Move-Item -Force $txtPathname $backupTxtPath
            }

        }
    }

    Write-Log " " info $logPath
    Write-Log " " info $logPath
    Write-Log "Unzugeordnet:     $count_nothing " info $logPath
}