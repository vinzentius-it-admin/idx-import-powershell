
function reencodeIDX ($idxFile)
{
    $content = Get-Content $idxFile
    [System.IO.File]::WriteAllLines($idxFile, $content)
}

function Write-Log
{
[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$true,
               ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [Alias("LogContent")]
    [string]$Message,

    # [Parameter(Mandatory=$false)]
    # [Alias('LogPath')]
    # [string]$Path='M:\IDXSRV\logs\default.log',
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Error","Warn","Info")]
    [string]$Level="Info",

    [Parameter(Mandatory=$false)]
    [switch]$Shell
)

Begin
{
    # Set VerbosePreference to Continue so that verbose messages are displayed.
    $VerbosePreference = 'Continue'
    $DateReverse = Get-Date -Format yyyy.MM.dd
    $Week = Get-Date -UFormat %V  
#        $idxSrvDir = "M:\IDXSRV\"
     $idxSrvDir = "C:\HYDmedia-Import-auto\01\idx-srv\"
    $logDir = -join($idxSrvDir,"logs\")
    $logfile = -join($logDir,"ACH-KW",$Week,".log")

}
Process
{
    # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
    if (!(Test-Path $logfile)) {
        Write-Verbose "Creating $logfile."
        $NewLogFile = New-Item $logfile -Force -ItemType File
        }
    # Format Date for our Log File
    $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Write message to error, warning, or verbose pipeline and specify $LevelText
    switch ($Level) {
        'Error' {
            Write-Error $Message
            $LevelText = 'ERROR:      '
            }
        'Warn' {
            Write-Warning $Message
            $LevelText = 'WARNING: '
            }
        'Info' {
            Write-Verbose $Message
            $LevelText = 'INFO:           '
            }
        }
    
    if (-Not ($Shell)) {
        # Write log entry to $Path
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $logfile -Append
    }
}
End
{
}
}

function writeIDX ($Fallnr,$DokType,$Nachname,$Vorname,$GebDatum,$Datum,$idxFile,$idxPath,$pdfFile,$pdfPath) 
{
# Remove-Item ${idxpath}${pdffile} -Force -ErrorAction SilentlyContinue
Copy-Item ${pdfpath}${pdffile} ${idxpath}   

$s = @"
<Patientenakte>
0
<idx>


S-DMS



{0}
{1}
{2}





</idx>
<n2>
{3}
{4}

{5}






</n2>
<n3>






</n3>
<n4>

{6}

{7}








</n4>

<usr>

</usr>
<img>
{8}
</img>
</Patientenakte>
"@ -f $Fallnr, $DocType[0], $DocType[1], $Nachname, $Vorname, $GebDatum, $Datum, $DocType[2], $pdfFile

$s | Out-File -Encoding Windows-1252 -FilePath $idxFile
}

function writeStampedPDF ($stampTool,$pdfPath,$pdfFile,$stampPDF,$stampedPDF)
{ 
$pdfCommand = -join($stampTool," ",$pdfPath,$pdfFile, " stamp ",$stampPDF," output ",$stampedPDF)
# write-host $pdfCommand
Remove-Item $stampedPDF -Force -ErrorAction SilentlyContinue
Invoke-Expression $pdfCommand
}

