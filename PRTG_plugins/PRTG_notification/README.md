# notify-via-IDERInote PRTG notification script

## Description
This PRTG notification script can be used to create IDERI note messages out of PRTG using the script provided and the IDERI note PowerShell module.
It can, e.g., be used to automatically inform your IT administrators about state changes of PRTG sensors directly on their desktops.

## How it works
If a sensor is configured to create a notification with the script, the script itself will check if an IDERI note message has already been created for this particular sensor in the past. If not, the script will attempt to create a new message on the IDERI note server specified, but will also log the sensor ID and the index of the newly created IDERI note message to a file. If the sensor then will change states, the script will check again if a message for that sensor has been created earlier and will attempt to update the message on the server instead of creating a new one each time a notification for that sensor should be sent.
This way the recipients will only get messages with the latest state of the sensor instead of multiple, maybe even obsolete messages.

By default the file holding the assignments between PRTG sensor IDs and IDERI note message indexes is located in <br />__%PROGRAMDATA%\\IDERI\\note-PRTG-notification\\sensorIdToMessageID.db.csv*__ on the PRTG server.

## Prerequesites
- PRTG version: >=20.1.57
- IDERI note PowerShell Module installed on the PRTG server.
- The user executing the script must have write access on directory __%PROGRAMDATA%\\IDERI\\note-PRTG-notification\\*__.

## Installation
- Install the IDERI note PowerShell Module from the latest inote.exe. (You can download it from the IDERI note homepage.)
- Download the notification script "notify-via-IDERInote.ps1" from the repository. (https://github.com/ideri/IDERInote/blob/PRTG_plugins/PRTG_plugins/PRTG_notification/notify-via-IDERInote.ps1)
- Copy the script to your PRTG installation notification directory. <br/> (Default: __*"C:\Program Files (x86)\PRTG Network Monitor\notifications\exe\notify-via-IDERInote.ps1"*__)
- Done. Now you can continue with configuring the script in PRTG.

## How to setup
As IDERI note uses domain objects (users, computers and security groups) as recipient identifiers we currently cannot use the Checkmk users as recipients. But as Checkmk only sends notifications if a contact is specified in the rule, we first have to create a new dummy user in Checkmk. If we'd check the *Notify all users* box of the rule multiple identical IDERI note messages would be created for each Checkmk user.

### Step by step
- Login to PRTG as an administrator.
- Navigate to __*Setup -> Notification Templates*__ and add a new template by pressing __*Add Notification Template*__ via the "__+__" on the right hand side.
- __...TODO__: Add Step by Step description on how to setup a working instance; Add screenshots; 

## Parameters available
__...TODO__: Documentation for mandatory and optional parameters 

## Troubleshooting
__...TODO__: 
