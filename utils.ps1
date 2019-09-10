function Write-Log {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$Message = "",

        # [Parameter(Mandatory=$false)]
        # [Alias('LogPath')]
        # [string]$Path='M:\IDXSRV\logs\default.log',
    
        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warn", "Info")]
        [string]$Level = "Info",
    
        [Parameter(Mandatory = $false)]
        [string]$logsPath = ""
    )

    Begin {
        # Set VerbosePreference to Continue so that verbose messages are displayed.
        $VerbosePreference = 'Continue'
        $DateReverse = Get-Date -Format yyyy.MM.dd
        $Week = Get-Date -UFormat %V  
        $logfile = -join ($logsPath, "ACH-KW", $Week, ".log")

    }
    Process {
        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
        if (!(Test-Path $logfile)) {
            Write-Verbose "Erstelle Logdatei: $logfile."
            $NewLogFile = New-Item $logfile -Force -ItemType File
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
    
        if (![string]::IsNullOrEmpty($logsPath)) {
            # Write log entry to $Path
            "$FormattedDate $LevelText $Message" | Out-File -FilePath $logfile -Append
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

function Write-PDFStamped ($stampTool, $pdfPath, $pdfFile, $stampPDF, $stampedPDF) { 
    $pdfCommand = -join ($stampTool, " ", $pdfPath, $pdfFile, " stamp ", $stampPDF, " output ", $stampedPDF)
    # write-host $pdfCommand
    Remove-Item $stampedPDF -Force -ErrorAction SilentlyContinue
    Invoke-Expression $pdfCommand
}

function Encode-IDXFile ($idxFile) {
    $content = Get-Content $idxFile
    [System.IO.File]::WriteAllLines($idxFile, $content)
}