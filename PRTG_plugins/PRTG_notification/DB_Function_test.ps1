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
    
    [cmdletbinding(SupportsShouldProcess=$True)]
    
    Param (
    [Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a filename and path for the CSV file")]
    [ValidateNotNullorEmpty()]
    [string]$Path,
    [Parameter(Position=1,Mandatory=$True,HelpMessage="Enter a hashtable",
    ValueFromPipeline=$True)]
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
        Select Key,Value,@{Name="Type";Expression={$_.value.gettype().name}} | `
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
[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a filename and path for the CSV file")]
[ValidateNotNullorEmpty()]
[ValidateScript({Test-Path -Path $_})]
[string]$Path
)

Write-Verbose "Importing data from $Path"

Import-Csv -Path $path | ForEach-Object -begin {
        #define an empty hash table
        $hash=@{}
    } -process {
        <#
        if there is a type column, then add the entry as that type
        otherwise we'll treat it as a string
        #>
        if ($_.Type) {
            
            $type=[type]"$($_.type)"
        }
        else {
            $type=[type]"string"
        }
        Write-Verbose "Adding $($_.key)"
        Write-Verbose "Setting type to $type"
        
        $hash.Add($_.Key,($($_.Value) -as $type))

    } -end {
        #write hash to the pipeline
        Write-Output $hash
    }

write-verbose "Import complete"

} #end function

####################################################

# The path to the db.csv
$dbPath = "$env:LOCALAPPDATA\IDERI\note-PRTG-notification\sensorIdToMessageID.db"
# Initialize sensorIDs
$sensorIDs = @{}
# The default for message ID
$msgID = $null


if(!(Test-Path $dbPath))
{
    New-Item -Path $([System.IO.Path]::GetDirectoryName($dbPath)) -ItemType Directory
}

# We get the sensor ID from PRTG
$sensorID = "105"

# Then we import an existing db.csv if it exists
if(Test-Path($dbPath))
{
    # Import sensor IDs
    $sensorIDs = Import-CSVtoHash -Path $dbPath
    
    # Check if current sensor ID exists in the DB and get the corresponding message ID.
    $msgID = $sensorIDs["$sensorID"]
}

# If msgID is other then 0 we update the message. Else we create a new one
if($msgID)
{
    # TODO: Update message
}
else {
    # TODO: Create new message and get the ID

    # Now we got the new ID of the IDERI note message associated with the sensor and can add it to the DB.
    $msgID = 15

    $sensorIDs.Add("$sensorID", $msgID)

    # Finally we export the hash to db.csv, as we added a value
    Export-HashtoCSV -Path "$dbPath" -Hashtable $sensorIDs
} 
