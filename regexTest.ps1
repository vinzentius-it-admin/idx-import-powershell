Write-Host "****************************"
Write-Host ""

$Matches = ''

$files = Get-ChildItem "./data/txt/" -Filter "*.txt"

# $fileName = "./data/txt/dms_20191127102900.txt"

:fileloop foreach ($filename in $files) {

    # $line = Select-String -Pattern "^(\d{7}|\d{6})([\s-]*)?" $fileName | Select-Object -First 1
    $line = Select-String -Pattern "^[\w-]*, [\w-]*.*" $fileName | Select-Object -First 1
    
    Write-Host ($line | Format-List | Out-String)
    [string]$line.Line -Match "([\w-]*), ([\w-]*)\s?(\w*)?"
    # [string]$line.Line -Match  "^(\d{7}|\d{6})([\s-]*)?"

    # $Fallnr = $Matches[1]

    $Nachname = $Matches[1]
    $Vorname = $Matches[2]
    # $Matches[3].GetType()
    try {$Matches[3] = [int]$Matches[3]}
    catch {}
    if ($Matches[3] -isnot [int] ) {
        # 2 Vornamen
        $Vorname = -join ($Matches[2], " ", $Matches[3])              
    }

    Write-Host ($Matches | Format-Table | Out-String)
    Write-Host "Vorname :" $Vorname
    Write-Host "Nachname :" $Nachname
}
