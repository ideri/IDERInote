param(
    $InoteServerName,
    $InoteServerPort,
    $InoteMsgDurationMinutes = "5",
    $InoteMsgShowPopup = $true,
    $InoteMsgShowTicker = $false,

    $Device,
    $Name,
    $Status,
    $Down,
    $Message
)

## notify-via-IDERInote.ps1 (notification script)
## PRTG notification script for IDERI note.
##
## Author: IDERI GmbH (Sebastian Mann)
## Homepage: https://www.ideri.com
## Repo URL: https://github.com/ideri/IDERInote-checkMk_plugins
##
## History:
## (2022-10) 1.0: initial release
##              Tested with ...

function Test-Prerequesites
{
    if((Get-Module -Name IDERI.note -ListAvailable) -eq $null)
    {
        Write-Error "IDERI note PowerShell Module missing. Please install first."
        exit 1
    }
}

function Get-InotePriorityFromPrtgStatus($status)
{
    $statusArr = $status.Split(" ")
    switch ($statusArr[0]) 
    {
        "Down" { return "ALERT"; break; }
        "Warning" { return "WARNING"; break; }
        "Unusual" { return "WARNING"; break; }
        "Paused" { return "INFORMATION"; break; }
        "Up" { return "INFORMATION"; break; }
        "Unknown" { return "WARNING"; break; }
        Default { return "WARNING"; break; }
    }
}

# First check the prerequesites
Test-Prerequesites


# parse status to priority
$priority = Get-InotePriorityFromPrtgStatus($Status)

# compose the message text
$msgText = `
    "Device: $Device" + [System.Environment]::NewLine + `
    "Name: $Name" + [System.Environment]::NewLine + `
    "Status: $Status" + [System.Environment]::NewLine + `
    "Down: $Down" + [System.Environment]::NewLine + `
    "Message: " + [System.Environment]::NewLine + `
    "$Message"

# create a server connection to the IDERI note server
New-iNoteServerConnection -ComputerName "$InoteServerName" -TCPPort ([int]::Parse($InoteServerPort))

# create a IDERI note message object
$message = [Ideri.Note.Message]::new($IDERInoteServerSession)
$message.Text = $msgText
$message.Priority = $priority
$message.StartTime = (Get-Date)
$message.EndTime = (Get-Date).AddMinutes([int]::Parse($InoteMsgDurationMinutes))
$message.ShowPopup = [System.Convert]::ToBoolean($InoteMsgShowPopup)
$message.ShowTicker = [System.Convert]::ToBoolean($InoteMsgShowTicker)

# create a new IDERI note message on the IDERI note server
New-iNoteMessage -MessageObject $message -Force 
