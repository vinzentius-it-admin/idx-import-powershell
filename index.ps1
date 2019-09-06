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
$department = $config.department
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

Clear-Host
write-host 
write-host "# # # # # # # # # # # # # # # # # # # # # # # # # # # #"
write-host 
write-host "  LOGGING NACH $idxSrvDir                              "
write-host 
write-host "  Zum Schreiben von Indexdateien nach $idxPath         "
Write-Host
Write-Host "  Programm starten mit Parameter -writeidx             "
write-host 
write-host "# # # # # # # # # # # # # # # # # # # # # # # # # # # #"
write-host 

if (-not $files) {
    Write-Log "Keine PDF Files in $pdfpath" warn
    exit 0
}
else {
    
    :fileloop foreach ($file in $files) {
        $found = $false
        $docType = $false
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

        Write-Log " " info $idxSrvDir
        Write-Log "Neu:              $File " info $idxSrvDir


        foreach ($pattern in $config.patterns) {
            # check for docType
            $finds = Select-String -Pattern $pattern.value $fileName
            if (-Not $found -and $finds.count -gt $pattern.gt) {
                $found = $true
                $docType = $pattern.key
                $count = $finds.count
                Write-Log "Ergebnis:         $count Treffer vom Dokumententyp $($pattern.key) in $filename " info $idxSrvDir
            }
        }

        if (-Not $found) {
            Write-Log "Kein Dokumententyp zuordenbar " warn $idxSrvDir
            Write-Log "Kein Dokumententyp zuordenbar $($pattern.key) " warn $idxSrvDir
            Write-Log "Docs werden verschoben nach $manualpath und $backupPath" warn $idxSrvDir
            Copy-Item -Force ${pdfPath}${pdfFile} $manualPath
            $count_nothing += 1
            continue fileloop
            #Move-Item -Force ${pdfPath}${pdfFile} $backupPath 
            #Move-Item -Force $fileName $backupTxtPath
        }
        else {
            
            # write results out
            switch ( $docType ) {
                Arztbrief {
                    # Fallnummer auf Aufkleber: 7-stellig [Leer] Datum [Leer] ACH
                    $line = Select-String -pattern "^(\d{7}|\d{6})\s*\d{2}[.,]\d{2}[.,]\d{4}\s*ACH" $fileName
                    # Write-Host $line
                    $Matches = ""
    
                    if (-not ($line)) {
                        Write-Log "KEINE FALLNUMMER Arztbrief" warn $idxSrvDir
                        Write-Log "Verschiebe Dateien nach $manualpath und $backupPath" warn $idxSrvDir
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
                        Write-Log "Fallnummer:       $Fallnr" info $idxSrvDir
                    }
                    else {
                        Write-Log "Konnte Fallnummer nicht extrahieren aus " warn $idxSrvDir
                        Write-Log "$line" warn $idxSrvDir
                        Write-Log "Verschiebe Dateien nach $manualpath und $backupPath" warn $idxSrvDir
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
                        Write-Log "$line - Kein Treffer für Name, Vorname in $filename ($Doktype[1])" warn $idxSrvDir
                        continue fileloop
                    }
    
                    $Vorname = $Matches[2]
                    $Nachname = $Matches[1]
                    # $GebDatum = $Matches[3]
                    $GebDatum = "01.01.1970"
                    Write-Log "Vorname:          $Vorname" info $idxSrvDir
                    Write-Log "Nachname:         $Nachname" info $idxSrvDir
                    Write-Log "GebDatum:         $GebDatum" info $idxSrvDir
    
                }
    
                Histologie {
                    # Fallnummer
                    $fallPattern = @("Fall-Nr", "Fallnummer")
                    $line = Select-String -Pattern $fallPattern $fileName
                    Write-Log "Zeile:            $line " info $idxSrvDir
                    $Matches = ""
    
                    if (-not ($line)) {
                        Write-Log "KEINE FALLNUMMER Histologie" warn $idxSrvDir
                        Write-Log "Verschiebe Dateien nach $manualpath und $backupPath" warn $idxSrvDir
                        Copy-Item -Force ${pdfPath}${pdfFile} $manualPath
                        Move-Item -Force ${pdfPath}${pdfFile} $backupPath
                        Move-Item -Force $fileName $backupTxtPath 
                        continue fileloop
                    }
    
                    # if (-Not ($line -Match "Fall-Nr.: (\d{7}|\d{6})")) {
                    if ([string]$line -Match "Fall-Nr.:\s*(\d{7}|\d{6})") {
                        $Fallnr = $Matches[1]
                        Write-Log "Fallnummer:       $Fallnr" info $idxSrvDir
                    }
                    else {
                        Write-Log "Konnte Fallnummer nicht extrahieren aus " warn $idxSrvDir
                        Write-Log "Verschiebe Dateien nach $manualpath und $backupPath" warn $idxSrvDir
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
                        Write-Log "$line - Keine Treffer für Name, Vorname in $filename ($Doktype[1])" warn $idxSrvDir
                        continue fileloop
                    }
        
                    # Entfernen Dr. med. 
                    $line = $line -replace "Dr[.,]", "Dr"
                    $line = $line -replace "med[,.]", ""
        
                    # Nachname, Vorname
                    if ([string]$line -Match "Patient.*:\s*(\w*)[,.]\s*(\w*)\s*ge[bh]..*\s*(\w{2}[.,]\w{2}[.,]\w{4})") {
                        Write-Log "Zeile:            $line " info $idxSrvDir
                        $Vorname = $Matches[2]
                        $Nachname = $Matches[1]
                    }      # Check: 2 Vornamen
                    elseif ([string]$line -Match "Patient.*:\s*(\w*)\s*(\w*)\s*(\w*)?[,.]\s*ge[bh]..*\s*(\w{2}[.,]\w{2}[.,]\w{4})") {
                        Write-Log "Zeile:            $line " info $idxSrvDir
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
                        Write-Log "Zeile:            $line " info $idxSrvDir
                        $Vorname = $Matches[2]
                        $Nachname = $Matches[1]
    
                    }
                    else {
                        Write-Log "Verschiebe Dateien nach $manualpath und $backupPath" warn $idxSrvDir
                        Copy-Item -Force ${pdfPath}${pdfFile} $manualPath
                        Move-Item -Force ${pdfPath}${pdfFile} $backupPath
                        Move-Item -Force $fileName $backuptxtPath 
                        continue fileloop  
                    } 
    
                    Write-Log "Vorname:          $Vorname" info $idxSrvDir
                    Write-Log "Nachname:         $Nachname" info $idxSrvDir
                    Write-Log "GebDatum:         $GebDatum" info $idxSrvDir
                }
    
                default {
                    Write-Log "Seltener Fall. Weiter mit nächsten Datei..." warn $idxSrvDir
                }
    
            }

            # write files
            if ($writeidx) {
                try {
                    Write-IDXFile $department $Fallnr $DokType $Nachname $Vorname $GebDatum $Datum $idxfile $idxPath $pdfFile $pdfPath
                }
                catch {
                    Write-Log "Problem mit dem Schreiben von $idxfile" error $idxSrvDir
                    Write-Log "Parameter: $department $Fallnr $DokType $Nachname $Vorname $GebDatum $Datum $idxfile $idxPath $pdfFile $pdfPath" error $idxSrvDir
                    Write-Log "Dateien bleiben unberührt; Vorgang abgebrochen" error $idxSrvDir
                    break fileloop
                }
    
                Write-Log "Kopiere           $idxfile nach $okfile" info $idxSrvDir
                Copy-Item $idxfile $okfile
                Write-Log "Verschiebe        ${pdfPath}${pdfFile} und $filename nach $backupPath " info $idxSrvDir
                Move-Item -Force ${pdfPath}${pdfFile} $backupPath
                Move-Item -Force $fileName $backupTxtPath
            }

        }
    }

    Write-Log "Unzugeordnet:     $count_nothing " info $idxSrvDir
}