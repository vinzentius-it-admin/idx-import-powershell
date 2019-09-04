$configFilePath = "config.json.dist"
$configDistFilePath = "config.json.dist"
$checkFile = Test-Path $configFilePath
if (!$checkFile) {
    Write-Host "Die Konfigurationsdatei $configFilePath konnte nicht gefunden werden. Bitte erstellen Sie eine Konfigurationsdatei mit dem Dateinamen $configFilePath im Wurzelverzeichnis dieser Anwendung. Dafür kann die Datei $configDistFilePath, die ebenfalls im Wurzelverzeichnis liegt, als Vorlage verwendet werden."
    exit 0
}

#Write-Output "************* 1 **************"
#$linuxfile = import-csv .\.env.dist -Delimiter '=' -Header Var,Value
#Write-Host ($linuxfile | Format-Table | Out-String)
#Write-Host ($linuxfile | Format-List | Out-String)
#Write-Output $linuxfile.Var
#Write-Output $linuxfile.Value
#Write-Output "********** end of 1 **********"
Write-Output "************* 2 **************"
$linuxfile = Get-Content -Raw -Path $configFilePath | ConvertFrom-Json
#Write-Host ($linuxfile | Format-Table | Out-String)
#Write-Host ($linuxfile | Format-List | Out-String)
#Write-Output $linuxfile.pattern[0].value
foreach ($obj in $linuxfile.patterns[0].value) {
    Write-Host ("Got: " + $obj)
}
Write-Output "********** end of 2 **********"
