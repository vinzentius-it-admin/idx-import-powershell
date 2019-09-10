Write-Host "****************************"
Write-Host "****************************"
Write-Host "****************************"
Write-Host ""

$fileName = "./data/txt/<filename>.txt"

$checkFile = Test-Path $fileName

if ($checkFile) {
    $line = Select-String -Pattern "\s*Name\s+(\w*(?:-\w*)?)\s*(\w*(?:-\w*)?)\s*" $fileName
    Write-Host ($line | Format-List | Out-String)
    
    if (-Not ([string]$line -Match "\s*Name\s+(\w*(?:-\w*)?)\s*(\w*(?:-\w*)?)\s*(\w*(?:-\w*)?)?\s*")) {
        Write-Warning "Kein Treffer:                 $fileName"
        Write-Host ""
        Write-Host ""
    }
    
    Write-Host ($Matches | Format-Table | Out-String)
}
else {
    Write-Warning "Datei nicht gefunden:         $fileName"
    Write-Host ""
}

