function Write-Log {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$Message = "",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warn", "Info")]
        [string]$Level = "Info",
    
        [Parameter(Mandatory = $false)]
        [string]$logPathname = ""
    )

    Begin {
    }
    Process {
        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
        if (-Not (Test-Path $logPathname)) {
            Write-Verbose "Erstelle Logdatei: $logPathname."
        }
        # Format Date for our Log File
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # Write message to error, warning, or verbose pipeline and specify $LevelText
        switch ($Level) {
            'Error' {
                Write-Error "$Message"
                $LevelText = 'ERROR:      '
            }
            'Warn' {
                Write-Warning "$Message"
                $LevelText = 'WARNING: '
            }
            'Info' {
                Write-Host "$Message" -ForegroundColor Cyan
                $LevelText = 'INFO:           '
            }
        }
    
        if (-Not [string]::IsNullOrEmpty($logPathname)) {
            # Write log entry to $Path
            "$FormattedDate $LevelText $Message" | Out-File -FilePath $logPathname -Append
        }
    }
    End {
    }
}

function Write-IDXFile ($department, $Fallnr, $categories, $Nachname, $Vorname, $GebDatum, $Datum, $idxFile, $idxPath, $topic, $pdfFile, $pdfPath) {
    # Remove-Item ${idxpath}${pdffile} -Force -ErrorAction SilentlyContinue
    Copy-Item ${pdfpath}${pdffile} ${idxpath}   

    $s = @"
<Patientenakte>
0
<idx>


{0}



{1}
{2}
{3}





</idx>
<n2>
{4}
{5}

{6}






</n2>
<n3>






</n3>
<n4>

{7}

{8}








</n4>

<usr>

</usr>
<img>
{9}
</img>
</Patientenakte>
"@ -f $department, $Fallnr, $categories[0], $categories[1], $Nachname, $Vorname, $GebDatum, $Datum, $topic, $pdfFile

    $s | Out-File -Encoding "Windows-1252" -FilePath $idxFile
}
