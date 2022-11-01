param(
    # The IDERI note server name.
    [Parameter(Mandatory = $true)]
    $InoteServerName,
    # The TCP port for the IDERI note administrator interface. If none is defined, named pipes will be used.
    [Parameter(Mandatory = $false)]
    $InoteServerPort = 0,
    # The duration in minutes the IDERI note message should be valid for. (Default: 60)
    [Parameter(Mandatory = $false)]
    $InoteMsgDurationMinutes = "60",
    # Show the IDERI note message in a popup. (Default: true)
    [Parameter(Mandatory = $false)]
    $InoteMsgShowPopup = $true,
    # Show the IDERI note message in a ticker. (Default: false)
    [Parameter(Mandatory = $false)]
    $InoteMsgShowTicker = $false,
    # The recipients for the IDERI note message as a comma separated string. (Example: 'note\homer.simpson, note\pc01$, note\GRP-IT')
    [Parameter(Mandatory = $true)]
    $InoteMsgRecipients,
    # The excludes for the IDERI note message as a comma separated string. (Example: 'note\homer.simpson, note\pc01$, note\GRP-IT')
    [Parameter(Mandatory = $false)]
    $InoteMsgExcludes,
    # Notify IDERI note server when message is received. (Default: false)
    [Parameter(Mandatory = $false)]
    $InoteMsgNotifyReceive = $false,
    # Notify IDERI note server when message is acknowledged. (Default: false)
    [Parameter(Mandatory = $false)]
    $InoteMsgNotifyAcknowledge = $false,
    # IDERI note message addressing mode. (Default: 'UserAndComputer'; Possible values: 'UserOnly', 'UserAndComputer', 'ComputerOnly')
    [Parameter(Mandatory = $false)]
    [ValidateSet("UserOnly", "UserAndComputer", "ComputerOnly")]
    $InoteMsgAddressingMode = "UserAndComputer",

    # '%sensorid' placeholder data of PRTG
    [Parameter(Mandatory = $true)]
    $prtgSensorID,
    # '%device' placeholder data of PRTG
    [Parameter(Mandatory = $true)]
    $prtgDevice,
    # '%name' placeholder data of PRTG
    [Parameter(Mandatory = $true)]
    $prtgName,
    # '%laststatus' placeholder data of PRTG
    [Parameter(Mandatory = $true)]
    $prtgLastStatus,
    # '%down' placeholder data of PRTG
    [Parameter(Mandatory = $true)]
    $prtgDown,
    # '%message' placeholder data of PRTG
    [Parameter(Mandatory = $false)]
    $prtgMessage,    
    # '%home' placeholder data of PRTG
    [Parameter(Mandatory = $false)]
    $prtgHome,
    # '%sitename' placeholder data of PRTG
    [Parameter(Mandatory = $true)]
    $prtgSitename

)

<# 
notify-via-IDERInote.ps1 (notification script)
PRTG notification script for IDERI note.
min. PRTG version required: PRTG 20.1.57

Author: IDERI GmbH (Sebastian Mann)
Homepage: https://www.ideri.com
Repo URL: https://github.com/ideri/IDERInote

Note: This script includes some functions written by Jeffery Hicks. 
      Thank you for that.
      https://jdhitsolutions.com/blog/powershell/2062/export-and-import-hash-tables/

History:
(2022-11) 1.1:  Tested with PRTG version 21.4.72.1649+
                - Optional logging added.
                - Fix issue when optional parameter "InoteMsgExcludes" is missing.
                - Made parameter "prtgMessage" optional, as there is an issue with the message from PRTG containing special characters. (https://github.com/ideri/IDERInote/issues/3)
(2022-10) 1.0:  initial release
                Tested with PRTG version 21.4.72.1649+
#>
#######################################################################
# FUNCTIONS AND CLASSES
#######################
# The LoggingLevels
enum LoggingLevel {
    Error = 4
    Warning = 3
    Information = 2
    Debug = 1
    Trace = 0
}

function Write-Log() {
<#
.SYNOPSIS
Writes a log file.

.DESCRIPTION
If global variables "LoggingLevel" and "LogFilePath" are specified and have a value, Write-Log will write to the specified log file accordingly.

.EXAMPLE
$Global:LoggingLevel = [int][LoggingLevel]::Information
$Global:LogFilePath = "$env:TEMP/mylog.log"
Write-Log -Text "My error text." -InformationLevel "Error"

This will write the defined string "My error text." to the mylog.log file located in $env:TEMP.

.EXAMPLE
$Global:LoggingLevel = [int][LoggingLevel]::Error
$Global:LogFilePath = "$env:TEMP/mylog.log"
Write-Log -Text "My error text." -InformationLevel "Information"

This will not write to the specified log file, as the global error level is set to 'Error'.

.NOTES
Requires the flags enum 'LoggingLevel' to be specified and available in session.
Regires the global variables 'LoggingLevel' and 'LogFilePath' to be set.

#>

    [CmdletBinding()]
    param(
        # The text of the log message.
        [Parameter(Mandatory = $true)]
        [string]$Text,
        # The severity of the log message. (Default: "Information")
        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warning", "Information", "Debug", "Trace")]
        [LoggingLevel]$InformationLevel = "Information"
    )

    if ($Global:LogFilePath -ne $null -and $Global:LoggingLevel -ne $null) {
        $datetime = Get-Date -Format "yyyy-MM-dd hh:mm:ss.fff"

        function Write-ToLog($severity) {
            "$datetime - $($HOST.InstanceId) - $prtgSensorID - $severity - $Text" | Out-File "$Global:LogFilePath" -Append
        }

        # check if LoggingLevel variable is set
        if ($Global:LoggingLevel -ne $null) {
            # check if sepcified information level should be logged
            if ([LoggingLevel]$Global:LoggingLevel -le $InformationLevel) {
                # test path and create path if not existent
                if (!(Test-Path $([System.IO.Path]::GetDirectoryName($Global:LogFilePath)))) {
                    New-Item -Path $([System.IO.Path]::GetDirectoryName($Global:LogFilePath)) -ItemType Directory
                }

                # check the information level and log accordingly
                switch ([int]$InformationLevel) {
                    $([int][LoggingLevel]::Error) { Write-ToLog -severity "E"; break; }
                    $([int][LoggingLevel]::Warning) { Write-ToLog -severity "W"; break; }
                    $([int][LoggingLevel]::Information) { Write-ToLog -severity "I"; break; }
                    $([int][LoggingLevel]::Debug) { Write-ToLog -severity "D"; break; }
                    $([int][LoggingLevel]::Trace) { Write-ToLog -severity "T"; break; }
                    Default { Write-ToLog -severity "0"; break;}
                }
            }
        }
    }
}

function New-InoteMessageWithDbForPrtg {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $SensorID,
        [Parameter(Mandatory = $true)]
        $MessageObj,
        [Parameter(Mandatory = $false)]
        $dbPath = "$env:PROGRAMDATA\IDERI\note-PRTG-notification\sensorIdToMessageID.db.csv"
    )
    
    begin {
        # Initialize sensorIDs
        $sensorIDs = @{}
        # The default for message ID
        $msgID = $null

        # create path to db file if not existent
        if (!(Test-Path $([System.IO.Path]::GetDirectoryName($dbPath)))) {
            New-Item -Path $([System.IO.Path]::GetDirectoryName($dbPath)) -ItemType Directory
        }

        # Import some functions
        Function Export-HashtoCSV {

            <#
            .Synopsis
            Export a hashtable to a CSV file
            .Description
            This function will export a hash table to a CSV file. The function
            will add a new column, Type, which will be the .NET type of each
            value. This information is used with Import-CSVtoHash to properly
            reconstitute the hash table.
            
            .Parameter Path
            The file name and path to the CSV file.
            
            .Parameter Hashtable
            The hash table object to export.
            
            .Example
            PS C:\> $myhash | Export-HashtoCSV MyHash.csv
            PS C:\> get-contnet .\Myhash.csv
            #TYPE Selected.System.Collections.DictionaryEntry
            "Key","Value","Type"
            "name","jeff","String"
            "pi","3.14","Double"
            "date","2/2/2012 8:53:58 AM","DateTime"
            "size","3","Int32"
            
            .Link
            Import-CSVtoHash
            Export-CSV
            
            .Inputs
            Hashtable
            .Outputs
            None
            
            #>
            
            [cmdletbinding(SupportsShouldProcess = $True)]
            
            Param (
                [Parameter(Position = 0, Mandatory = $True, HelpMessage = "Enter a filename and path for the CSV file")]
                [ValidateNotNullorEmpty()]
                [string]$Path,
                [Parameter(Position = 1, Mandatory = $True, HelpMessage = "Enter a hashtable",
                    ValueFromPipeline = $True)]
                [ValidateNotNullorEmpty()]
                [hashtable]$Hashtable
            
            )
            
            Begin {
                Write-Verbose "Starting hashtable export"
                Write-Verbose "Exporting to $path"
            }
            
            Process {
                <#
                  Add a column for the data type of each hash table entry.
                  This can be used on import to properly reconstitute the
                  hash table
                #>
                $Hashtable.GetEnumerator() | `
                    Select Key, Value, @{Name = "Type"; Expression = { $_.value.gettype().name } } | `
                    Export-Csv -Path $Path
            
            }
            
            End {
                Write-Verbose "Ending hashtable export"
            }
            
        } #end function
        
        Function Import-CSVtoHash {
        
            <#
        .Synopsis
        Import a CSV file and create a hash table
        .Description
        This function will import a CSV file of hash table data and recreate
        the hash table object. Ideally the CSV file will have been created
        with the Export-HashtoCSV function, bu you can import any CSV provided
        it has Key and Value headings. If you include a Type heading, then the
        values will be cast to that type.
        
        "Key","Value","Type"
        "name","jeff","String"
        "pi","3.14","Double"
        "date","2/2/2012 8:53:58 AM","DateTime"
        "size","3","Int32"
        
        .Parameter Path
        The file name and path to the CSV file.
        
        .Example
        PS C:\> $h=Import-CSVtoHash MyHash.csv
        PS C:\> $h
        Name                           Value
        ----                           -----
        name                           jeff
        pi                             3.14
        date                           2/2/2012 8:53:58 AM
        size                           3
        
        .Link
        Export-HashtoCSV
        Import-CSV
        
        .Inputs
        String
        .Outputs
        Hashtable
        
        #>
        
            [cmdletbinding()]
        
            Param (
                [Parameter(Position = 0, Mandatory = $True, HelpMessage = "Enter a filename and path for the CSV file")]
                [ValidateNotNullorEmpty()]
                [ValidateScript({ Test-Path -Path $_ })]
                [string]$Path
            )
        
            Write-Verbose "Importing data from $Path"
        
            Import-Csv -Path $path | ForEach-Object -begin {
                #define an empty hash table
                $hash = @{}
            } -process {
                <#
                if there is a type column, then add the entry as that type
                otherwise we'll treat it as a string
                #>
                if ($_.Type) {
                    
                    $type = [type]"$($_.type)"
                }
                else {
                    $type = [type]"string"
                }
                Write-Verbose "Adding $($_.key)"
                Write-Verbose "Setting type to $type"
                
                $hash.Add($_.Key, ($($_.Value) -as $type))
        
            } -end {
                #write hash to the pipeline
                Write-Output $hash
            }
        
            write-verbose "Import complete"
        
        } #end function
    }
    
    process {
        # Then we import an existing db.csv if it exists
        Write-Log "Checking if a db for sensor and message index exists..." Debug
        if (Test-Path($dbPath)) {
            Write-Log "DB file exists." Debug
            # Import sensor IDs
            Write-Log "Trying to import the db..." Debug
            $sensorIDs = Import-CSVtoHash -Path "$dbPath"
            
            # Check if current sensor ID exists in the DB and get the corresponding message ID.
            Write-Log "Checking if current sensor was already in db and set message index accordingly..." Debug
            $msgID = $sensorIDs["$sensorID"]
        }

        # If msgID is other then null we update the message. Else we create a new one
        if ($msgID) {
            Write-Log "SensorID found in db." Debug
            Write-Log "Message index: $msgID" Trace
            # Update an existing message
            Write-Log "Trying to update the existing IDERI note message on the server..." Debug
            try{
                $msgCreated = Set-iNoteMessage -MessageObject $MessageObj -Index $msgID -Force -ErrorAction Stop
                Write-Log "IDERI note message updated successfully."
            }catch{
                $err = "Message could not be updated. (Line $($_.InvocationInfo.ScriptLineNumber)) - $_" 
                Write-Log $err Error
                throw $_
            }
        }
        else {
            Write-Log "SensorID could not be found in db." Debug
            # Create new message and get the ID
            Write-Log "Trying to create a new IDERI note message on the server..." Debug
            try{
                $msgCreated = New-iNoteMessage -MessageObject $MessageObj -Force -ErrorAction Stop
                Write-Log "IDERI note message created successfully."
            }catch{
                $err = "Message could not be created. (Line $($_.InvocationInfo.ScriptLineNumber)) - $_" 
                Write-Log $err Error
                throw $_
            }

            # Now we got the new ID of the IDERI note message associated with the sensor and can add it to the DB.
            Write-Log "Adding the new message index for the sensorID to the db..." Debug
            $msgID = $msgCreated.Index

            $sensorIDs.Add("$sensorID", $msgID)

            # Finally we export the hash to db.csv, as we've added a value
            Write-Log "Overriting the db file..." Debug
            Export-HashtoCSV -Path "$dbPath" -Hashtable $sensorIDs
        } 
    }
    
    end {
        
    }
}


function Test-Prerequesites {
    if ($null -eq (Get-Module -Name IDERI.note -ListAvailable)) {
        $err = "IDERI note PowerShell Module missing. Please install first."
        Write-Log $err Error
        Write-Error $err
        exit 1
    }
}


function Get-InotePriorityFromPrtgStatus($status) {
    $statusArr = $status.Split(" ")
    switch ($statusArr[0]) {
        "Down" { return "ALERT"; break; }
        "Warning" { return "WARNING"; break; }
        "Unusual" { return "WARNING"; break; }
        "Paused" { return "INFORMATION"; break; }
        "Up" { return "INFORMATION"; break; }
        "Unknown" { return "WARNING"; break; }
        Default { return "WARNING"; break; }
    }
}

function Add-InoteMsgRecipients([Ideri.Note.Message]$message, [string]$recipients) {
    if([string]::IsNullOrEmpty($recipients)){
        Write-Error "No recipients defined." -ErrorAction Stop
    }
    else{
        $recipientsArr = $recipients.Split(",").Trim()
        $message.Recipient.Clear()
        $message.Recipient.AddRange($recipientsArr)
    }
    return $message    
}
function Add-InoteMsgExcludes([Ideri.Note.Message]$message, [string]$excludes) {
    if(![String]::IsNullOrEmpty($excludes)){
        $excludesArr = $excludes.Split(",").Trim()
        $message.Exclude.Clear()
        $message.Exclude.AddRange($excludesArr)
    }
    return $message
}

#######################################################################
# GLOBAL VARIABLES
##################
# Variables for logging. If not set no log will be written. Remove the "#"" for the LogFilePath variable value to write a log to that file.
$Global:LoggingLevel = [int][LoggingLevel]::Error
$Global:LogFilePath = "$env:PROGRAMDATA/IDERI/note-PRTG-notification/notifications.log"


#######################################################################
# SCRIPT
########
Write-Log "##############################################"
Write-Log "Script started."

# For debug purposes write the parameters passed to the script to the log file
Write-Log "------ TRACE ------" Trace
Write-Log "Parameters passed to script:" Trace
foreach ($key in $MyInvocation.BoundParameters.keys)
{
    $value = (get-variable $key).Value 
    Write-Log "$key : $value" Trace
}
Write-Log "-----" Trace
Write-Log "Invocation Line:" Trace
Write-Log $($MyInvocation.Line) Trace
Write-Log "---- END TRACE ----" Trace


# First check the prerequesites
Write-Log "Testing prerequesites..." Information
Test-Prerequesites

try{
    # parse laststatus to priority
    Write-Log "Parsing status to message priority..."
    try{
        $priority = Get-InotePriorityFromPrtgStatus($prtgLastStatus)
        Write-Log "Priority of message set to: $priority" Debug
    }catch{
        $err = "Could not parse state to priority. Continue anyway with default priority. Err: (Line $($_.InvocationInfo.ScriptLineNumber)) - $_" 
        Write-Log $err Warning
    }

    # compose the message text
    Write-Log "Composing the message text..."
    $msgText = @"
[$prtgSitename]

Sensor '$prtgName' of '$prtgDevice' has state '$prtgLastStatus'.

Device: $prtgDevice
Sensor: $prtgName
Status: $prtgLastStatus
Down: $prtgDown
"@

    # Add PRTG message if specified
    if($prtgMessage){
        Write-Log "Adding PRTG message to message text..." Debug
        $msgText += [System.Environment]::NewLine + [System.Environment]::NewLine + "Message Text:" + [System.Environment]::NewLine + $prtgMessage
    }


    Write-Log "Message text: $msgText" Trace

    # create a server connection to the IDERI note server
    Write-Log "Creating a connection to the IDERI note server..."
    try {
        Write-Log "Server: $InoteServerName" Trace
        Write-Log "Port: $InoteServerPort" Trace
        New-iNoteServerConnection -ComputerName "$InoteServerName" -TCPPort ([int]::Parse($InoteServerPort)) -ErrorAction Stop
        Write-Log "Connection to the IDERI note Server was successfull."
    }
    catch {
        $err = "Failed to create a connection to the IDERI note server. (Line $($_.InvocationInfo.ScriptLineNumber)) - $_" 
        Write-Log "$err" Error
        throw $_
    }

    # create an IDERI note message object
    Write-Log "Creating a new IDERI note message object..."
    try {
        $message = [Ideri.Note.Message]::new($IDERInoteServerSession)
        $message.Text = $msgText
        $message.Priority = [Ideri.Note.Priority]$priority
        $message.StartTime = (Get-Date)
        $message.EndTime = (Get-Date).AddMinutes([int]::Parse($InoteMsgDurationMinutes))
        $message.ShowPopup = [System.Convert]::ToBoolean($InoteMsgShowPopup)
        $message.ShowTicker = [System.Convert]::ToBoolean($InoteMsgShowTicker)
        $message.NotifyReceive = [System.Convert]::ToBoolean($InoteMsgNotifyReceive)
        $message.NotifyAcknowledge = [System.Convert]::ToBoolean($InoteMsgNotifyAcknowledge)

        Write-Log "Message object created successfully." Debug
    }
    catch {
        $err = "Failed to create message object. (Line $($_.InvocationInfo.ScriptLineNumber)) - $_" 
        Write-Log $err Error
        throw $_
    }

    # set the addressing mode for the message
    Write-Log "Trying to set the addressing mode for the message..."
    try {
        $message.AddressingMode = [Ideri.Note.AddressingMode]$InoteMsgAddressingMode
        Write-Log "Addressing mode set successfully." Debug
    }
    catch {
        $err = "Failed to parse AddressingMode. (Line $($_.InvocationInfo.ScriptLineNumber)) - $_" 
        Write-Log $err Error
        throw $_
    }

    # add recipients
    Write-Log "Parsing and adding recipients to message..."
    try{
        $message = Add-InoteMsgRecipients -message $message -recipients $InoteMsgRecipients
        Write-Log "Recipients: $($message.Recipient -join ', ')" Trace
    }catch{
        Write-Log "Failed to parse recipients. (Line $($_.InvocationInfo.ScriptLineNumber)) - $_"  Error
        throw $_
    }
    # add excludes to message
    Write-Log "Parsing and adding excludes to message..."
    try{
        $message = Add-InoteMsgExcludes -message $message -excludes $InoteMsgExcludes
        Write-Log "Excludes: $($message.Recipient -join ', ')" Trace
    }catch{
        Write-Log "Failed to parse excludes. (Line $($_.InvocationInfo.ScriptLineNumber)) - $_"  Error
        throw $_
    }

    # add a link to the sensor
    if ($prtgHome) {
        Write-Log "Adding a link to the sensor to the message..."
        $parts = "$prtgHome", "sensor.htm?id=$prtgSensorID"
        $urlToSensor = ($parts | foreach { $_.trim('/') }) -join '/'
        $message.LinkText = "Go to sensor..."
        $message.LinkTarget = "$urlToSensor"
    }
}
catch{
    Write-Log "$($_.Exception.ToString())" Debug
    $err = "An error occured while composing the message object. (Line $($_.InvocationInfo.ScriptLineNumber)) - $_" 
    exit 1
}

# create a new IDERI note message or update an existing one on the IDERI note server
Write-Log "Trying to create/update the message on the server..."
try {
    New-InoteMessageWithDbForPrtg -SensorID $prtgSensorID -MessageObj $message
}
catch {
    $err = "An error occured while creating message. (Line $($_.InvocationInfo.ScriptLineNumber)) - $_" 
    Write-Log $err Error
    Write-Log "$($_.Exception.ToString())" Debug
    Write-Error $err
    exit 1
}

