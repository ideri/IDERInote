# ======================================
# VARIABLES
# ======================================
# The name for the environment variable (NO blanks or special characters allowed)
$ENV_VAR_NAME = "MyRoomName"

# Set this to true, if you want to prefill the room text box with the last value given
$REMEMBER_LAST_ROOM = $true 

# Show the x for closing the dialog
$SHOW_CLOSING_X = $true

# EN localization
$DIALOG_CAPTION = "Room selector"
$DIALOG_EXPLANATION = "Please fill in your current room name so your colleges know where you are in case of emergency."
$LABEL_ROOM_NAME = "Enter your current room:"
$BUTTON_TEXT = "Accept"
$EMPTY_ROOM_DIALOG_CAPTION = "No room specified"
$EMPTY_ROOM_DIALOG_MSG = "Room name is empty. Please fill in a room name."
$ERROR_DIALOG_CAPTION = "Error"
$ERROR_DIALOG_MSG = "Something went wrong. Please contact your IT specialist."

# DE localization 
<#
	$DIALOG_CAPTION = "Raum Auswahl"
	$DIALOG_EXPLANATION = "Bitte geben Sie Ihren derzeitigen Raum an, sodass Ihre Kollegen in einem Notfall wissen, wo Sie sich befinden."
	$LABEL_ROOM_NAME = "Ihr derzeitiger Raum:"
	$BUTTON_TEXT = "Übernehmen"
	$EMPTY_ROOM_DIALOG_CAPTION = "Kein Raum angegeben"
	$EMPTY_ROOM_DIALOG_MSG = "Sie haben keine Eingaben gemacht. Bitte geben Sie einen Namen für Ihren derzeitigen Raum an."
	$ERROR_DIALOG_CAPTION = "Error"
	$ERROR_DIALOG_MSG = "Etwas ist schief gegangen. Bitte wenden Sie sich an Ihren IT Mitarbeiter."
#>

# ======================================
# FUNCTIONS
# ======================================
function OnAcceptButtonClick {
    param (
        [Parameter(Mandatory=$true)]
        $Element
    )

	if([string]::IsNullOrEmpty($Element.Text)){
        # Show MsgBox if no room number has been specified
		$mbButtons = [System.Windows.Forms.MessageBoxButtons]::OK
		$mbIcon = [System.Windows.Forms.MessageBoxIcon]::Exclamation		
		[System.Windows.Forms.MessageBox]::Show($EMPTY_ROOM_DIALOG_MSG,$EMPTY_ROOM_DIALOG_CAPTION,$mbButtons,$mbIcon);
	}
    else {
        try {
			# Set user evnironment variable
			[System.Environment]::SetEnvironmentVariable($ENV_VAR_NAME, $Element.Text , [System.EnvironmentVariableTarget]::User)
			# Close the dialog
			$mainDialog.DialogResult = [System.Windows.Forms.DialogResult]::OK
        }
        catch {
			# display an error
            $mbButtons = [System.Windows.Forms.MessageBoxButtons]::OK
            $mbIcon = [System.Windows.Forms.MessageBoxIcon]::Error		
            [System.Windows.Forms.MessageBox]::Show($ERROR_DIALOG_MSG,$ERROR_DIALOG_CAPTION,$mbButtons,$mbIcon);
        }
    }
}

function ShowRoomSelector {
	param(
		[string]
		$PredefinedRoom = [string]::Empty()
	)

	[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
	[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null

	$mainDialog = New-Object System.Windows.Forms.Form
	$lbl_Welcome = New-Object System.Windows.Forms.Label
	$lbl_RoomName = New-Object System.Windows.Forms.Label
	$btn_Accept = New-Object System.Windows.Forms.Button
	$textBox_roomName = New-Object System.Windows.Forms.TextBox
	$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState


	$handler_btn_Accept_Click= 
	{
		OnAcceptButtonClick -Element $textBox_roomName
	}

	$OnLoadForm_StateCorrection=
	{
		$mainDialog.WindowState = $InitialFormWindowState
	}

	# Main Dialog Properties
	$mainDialog.AcceptButton = $btn_Accept
	$mainDialog.AutoSize = $True
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 261
	$System_Drawing_Size.Width = 284
	$mainDialog.ClientSize = $System_Drawing_Size
	$mainDialog.ControlBox = $SHOW_CLOSING_X
	$mainDialog.DataBindings.DefaultDataSourceUpdateMode = 0
	$mainDialog.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",12,0,3,0)
	$mainDialog.FormBorderStyle = 3
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 841
	$System_Drawing_Point.Y = 0
	$mainDialog.Location = $System_Drawing_Point
	$mainDialog.MaximizeBox = $False
	$mainDialog.MinimizeBox = $False
	$mainDialog.Name = "mainDialog"
	$mainDialog.StartPosition = 1
	$mainDialog.Text = $DIALOG_CAPTION
	$mainDialog.TopMost = $True

	# Welcome Label Properties
	$lbl_Welcome.DataBindings.DefaultDataSourceUpdateMode = 0

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 13
	$System_Drawing_Point.Y = 13
	$lbl_Welcome.Location = $System_Drawing_Point
	$lbl_Welcome.Name = "lbl_Welcome"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 86
	$System_Drawing_Size.Width = 259
	$lbl_Welcome.Size = $System_Drawing_Size
	$lbl_Welcome.TabIndex = 3
	$lbl_Welcome.Text = $DIALOG_EXPLANATION
	$lbl_Welcome.TextAlign = 32

	$mainDialog.Controls.Add($lbl_Welcome)

	# Room Name Label Properties
	$lbl_RoomName.DataBindings.DefaultDataSourceUpdateMode = 0
	$lbl_RoomName.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",15,0,3,1)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 12
	$System_Drawing_Point.Y = 99
	$lbl_RoomName.Location = $System_Drawing_Point
	$lbl_RoomName.Name = "lbl_RoomName"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 61
	$System_Drawing_Size.Width = 259
	$lbl_RoomName.Size = $System_Drawing_Size
	$lbl_RoomName.TabIndex = 2
	$lbl_RoomName.Text = $LABEL_ROOM_NAME
	$lbl_RoomName.TextAlign = 512

	$mainDialog.Controls.Add($lbl_RoomName)

	# Text Box Properties
	$textBox_roomName.DataBindings.DefaultDataSourceUpdateMode = 0
	$textBox_roomName.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",15,0,3,1)
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 12
	$System_Drawing_Point.Y = 163
	$textBox_roomName.Location = $System_Drawing_Point
	$textBox_roomName.Name = "textBox_roomName"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 30
	$System_Drawing_Size.Width = 259
	$textBox_roomName.Size = $System_Drawing_Size
	$textBox_roomName.TabIndex = 0
	$textBox_roomName.TextAlign = 2
	$textBox_roomName.Text = $PredefinedRoom

	$mainDialog.Controls.Add($textBox_roomName)

	# Button Properties
	$btn_Accept.DataBindings.DefaultDataSourceUpdateMode = 0

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 75
	$System_Drawing_Point.Y = 210
	$btn_Accept.Location = $System_Drawing_Point
	$btn_Accept.Name = "btn_Accept"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 39
	$System_Drawing_Size.Width = 134
	$btn_Accept.Size = $System_Drawing_Size
	$btn_Accept.TabIndex = 1
	$btn_Accept.Text = $BUTTON_TEXT
	$btn_Accept.UseVisualStyleBackColor = $True
	$btn_Accept.add_Click($handler_btn_Accept_Click)

	$mainDialog.Controls.Add($btn_Accept)


	$InitialFormWindowState = $mainDialog.WindowState
	$mainDialog.add_Load($OnLoadForm_StateCorrection)
	$mainDialog.ShowDialog()| Out-Null

}

$currentRoom = [string]::Empty

if($REMEMBER_LAST_ROOM){
	# read the current value of the environment variable and prefill the text box with the value
	$currentRoom = [System.Environment]::GetEnvironmentVariable($ENV_VAR_NAME,[System.EnvironmentVariableTarget]::User)
}

ShowRoomSelector -PredefinedRoom $currentRoom
