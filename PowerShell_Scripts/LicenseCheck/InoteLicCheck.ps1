[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $LogfilePath
)

if(! $LogfilePath){
    $LogfilePath = "$PSScriptRoot"
}

$OUT_FILE_MAX_LICS = "$LogfilePath\IDERInote-MaxLicsUsed.csv"
# get the current date and time
$time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Start-Transcript -Path "$LogfilePath\IDERInote-MaxLicsUsed-lastExecution.log" -Force

Write-Host

try{
    Import-Module IDERI.note -ErrorAction Stop
    
    [int]$licsInUse = 0
    [int]$lastMaxLicsUsedValue = 0

    # get the current license info from the inote server
    $licInfos = Get-iNoteLicenseInformation
    $licsInUse = $licInfos.DesktopLicensesUsed

    # get the last max value from existing file
    if (Test-Path -Path "$OUT_FILE_MAX_LICS"){
        Write-Host "Reading previous max lics used value from file..."
        $lastMaxLicsUsedValue = (Import-Csv -Path "$OUT_FILE_MAX_LICS" -Delimiter ";").UsedLicenses
        Write-Host "Previous max lics used value: $lastMaxLicsUsedValue"
    } else {
        Write-Host "No file with previous max lics value found."
    }

    # check if the currently used licenses count is higher than the previous max used value
    Write-Host "Comparing current license count with last value..."
    if($lastMaxLicsUsedValue -lt $licsInUse){
        Write-Host "Current lics used value ($licsInUse) is greater than the previous max ($lastMaxLicsUsedValue). Writing to file..."
        # write the new value to the output file
        New-Object -TypeName psobject -Property @{
            date = $time
            UsedLicenses = $licsInUse
        } | Export-Csv -Path "$OUT_FILE_MAX_LICS" -Delimiter ";" -NoTypeInformation
    } else {
        Write-Host "Current lics used value ($licsInUse) is not greater than the previous max ($lastMaxLicsUsedValue). Nothing to do."
    }
} catch {
    "$time $($Error[0])" | Out-File -FilePath "$LogfilePath\IDERInote-MaxLicsUsed-Error.log" -Append
    exit 1
}

Stop-Transcript