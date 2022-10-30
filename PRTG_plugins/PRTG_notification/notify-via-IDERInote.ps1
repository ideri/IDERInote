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
    [Parameter(Mandatory = $true)]
    $prtgMessage,
    # '%home' placeholder data of PRTG
    [Parameter(Mandatory = $false)]
    $prtgHome,
    # '%sitename' placeholder data of PRTG
    [Parameter(Mandatory = $true)]
    $prtgSitename

)

## notify-via-IDERInote.ps1 (notification script)
## PRTG notification script for IDERI note.
## min. PRTG version required: PRTG 20.1.57
##
## Author: IDERI GmbH (Sebastian Mann)
## Homepage: https://www.ideri.com
## Repo URL: https://github.com/ideri/IDERInote
##
## Note: This script includes some functions written by Jeffery Hicks. 
##       Thank you for that.
##       https://jdhitsolutions.com/blog/powershell/2062/export-and-import-hash-tables/
##
## History:
## (2022-10) 1.0: initial release
##                Tested with PRTG version 21.4.72.1649+

#######################################################################
# FUNCTIONS
############
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
        if (!(Test-Path $dbPath)) {
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
        if (Test-Path($dbPath)) {
            # Import sensor IDs
            $sensorIDs = Import-CSVtoHash -Path "$dbPath"
            
            # Check if current sensor ID exists in the DB and get the corresponding message ID.
            $msgID = $sensorIDs["$sensorID"]
        }

        # If msgID is other then null we update the message. Else we create a new one
        if ($msgID) {
            # Update an existing message
            $msgCreated = Set-iNoteMessage -MessageObject $MessageObj -Index $msgID -Force -ErrorAction Stop
            # error handling
            if (!$msgCreated) {
                Write-Error "Message could not be created."
                exit 1    
            }
        }
        else {
            # Create new message and get the ID
            $msgCreated = New-iNoteMessage -MessageObject $MessageObj -Force -ErrorAction Stop

            # error handling
            if (!$msgCreated) {
                Write-Error "Message could not be created."
                exit 1    
            }

            # Now we got the new ID of the IDERI note message associated with the sensor and can add it to the DB.
            $msgID = $msgCreated.Index

            $sensorIDs.Add("$sensorID", $msgID)

            # Finally we export the hash to db.csv, as we've added a value
            Export-HashtoCSV -Path "$dbPath" -Hashtable $sensorIDs
        } 
    }
    
    end {
        
    }
}


function Test-Prerequesites {
    if ($null -eq (Get-Module -Name IDERI.note -ListAvailable)) {
        Write-Error "IDERI note PowerShell Module missing. Please install first."
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
    $recipientsArr = $recipients.Split(",").Trim()
    $message.Recipient.Clear()
    $message.Recipient.AddRange($recipientsArr)
    return $message
}
function Add-InoteMsgExcludes([Ideri.Note.Message]$message, [string]$excludes) {
    $excludesArr = $excludes.Split(",").Trim()
    $message.Exclude.Clear()
    $message.Exclude.AddRange($excludesArr)
    return $message
}
#######################################################################


# First check the prerequesites
Test-Prerequesites

# parse laststatus to priority
$priority = Get-InotePriorityFromPrtgStatus($prtgLastStatus)

# compose the message text
$msgText = "[$prtgSitename]" + [System.Environment]::NewLine + [System.Environment]::NewLine + `
    "Sensor '$prtgName' of '$prtgDevice' has state '$prtgLastStatus'." + [System.Environment]::NewLine + [System.Environment]::NewLine + `
    "Device: $prtgDevice" + [System.Environment]::NewLine + `
    "Sensor: $prtgName" + [System.Environment]::NewLine + `
    "Status: $prtgLastStatus" + [System.Environment]::NewLine + `
    "Down: $prtgDown" + [System.Environment]::NewLine + [System.Environment]::NewLine + `
    "Message: " + [System.Environment]::NewLine + `
    "$prtgMessage"

# create a server connection to the IDERI note server
try {
    New-iNoteServerConnection -ComputerName "$InoteServerName" -TCPPort ([int]::Parse($InoteServerPort)) -ErrorAction Stop
}
catch {
    Write-Error "Failed to create a connection to the IDERI note server. $_"
    exit 1
}

# create an IDERI note message object
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
}
catch {
    Write-Error "Failed to create message object. $_"
    exit 1
}

# set the addressing mode for the message
try {
    $message.AddressingMode = [Ideri.Note.AddressingMode]$InoteMsgAddressingMode
}
catch {
    Write-Error "Failed to parse AddressingMode. $_"
}

# add recipients and exclude to message
$message = Add-InoteMsgRecipients -message $message -recipients $InoteMsgRecipients
$message = Add-InoteMsgExcludes -message $message -excludes $InoteMsgExcludes

# add a link to the sensor
if ($prtgHome) {
    $parts = "$prtgHome", "sensor.htm?id=$prtgSensorID"
    $urlToSensor = ($parts | foreach { $_.trim('/') }) -join '/'
    $message.LinkText = "Go to sensor..."
    $message.LinkTarget = "$urlToSensor"
}

# create a new IDERI note message or update an existing one on the IDERI note server
try {
    New-InoteMessageWithDbForPrtg -SensorID $prtgSensorID -MessageObj $message
}
catch {
    Write-Error "Failed to create the message. $_"
    exit 1
}

 
 
 
