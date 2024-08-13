<#
.NAME
    intqdadm - TemplateSelector
#>

#######################################
# VARIABLES
#######################################
# The folder that contains your ini templates
$TEMPLATE_FOLDER = "$PSScriptRoot\Templates\"
# The path to the intqdadm.exe on your system
$INTQDADM_EXE_PATH = "C:\Program Files (x86)\ideri\IDERI note Administrator\intqdadm.exe"
# The name of the template that should be preselected when the UI initially shows
$DEFAULT_TEMPLATE = ""
# The file name in the TEMPLATE_FOLDER that conains the default connection settings
$SRV_CONNECTION_INI_FILE_NAME = "_IDERInoteServerConnectionSection.ini"
# The language of the UI (possible values: en, de)
$LANGUAGE = "en"


#######################################
# Translations
#######################################
switch ($LANGUAGE) {
    "de" { $lang = @{window_heading='IDERI note Vorlagen'; btn_Select='Auswählen'; lbl_TemplateSelection='Bitte wählen Sie eine Vorlage aus:'}}
    Default { $lang = @{window_heading='IDERI note templates'; btn_Select='Select'; lbl_TemplateSelection='Please select a template:'}}
}


#######################################
# WinForm
#######################################
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$iconBase64 = 'AAABAAEAICAAAAAAGACoDAAAFgAAACgAAAAgAAAAQAAAAAEAGAAAAAAAAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHZ+wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHZ+wHZ+wHZ+wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHZ+wHZ+wAAAAHZ+wHZ+wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHZ+wHZ+wAAAAAAAAAAAAHZ+wHZ+wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAHZ+wHZ+wAAAAAAAAAAAAAAAAAAAAHZ+wHZ+wAAAAAAAAAAAAHZ+wAAAAAAAC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwAAAAAAAAAAAAAAAAAHZ+wHZ+wAAAAAAAAAAAAAAAAAAAAAAAAAAAAHZ+wHZ+wAAAAHZ+wHZ+wAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAHZ+wHZ+wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHZ+wHZ+wHZ+wHZ+wAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAHZ+wHZ+wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHZ+wAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAHZ+wHZ+wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHZ+wAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAHZ+wHZ+wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHZ+wAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHZ+wHZ+wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHZ+wAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHZ+wHZ+wAAAAAAAAAAAAAAAAAAAAAAAAAAAAHZ+wAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHZ+wAAAAAAAAAAAAAAAAAAAAAAAAAAAAHZ+wAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHZ+wHZ+wAAAAAAAAAAAAAAAAAAAAAAAAAAAAHZ+wAAAAAAAC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHZ+wHZ+wHZ+wHZ+wHZ+wHZ+wHZ+wHZ+wHZ+wHZ+wHZ+wAAAAAAAAAAAC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwAAAAAAAAAAAAAAAAC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwAAAAAAAAC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwAAAAAAAAC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwAAAAAAAAAAAAAAAAC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwC6dwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD///////////7////8f///+T////Of4AfnzsADz+TP85/wz/PP/s/z5/7P8/P+z/P5/s/z/P7P8/7+z/P8/sAD+ADgB///////////+AHgB/AAwAPz/M/z8/zP8/P8z/Pz/M/z8/zP8/P8z/Pz/M/z8/zP8/AAwAP4AeAH/////w=='
$iconBytes  = [Convert]::FromBase64String($iconBase64)
$iconStream     = [System.IO.MemoryStream]::new($iconBytes, 0, $iconBytes.Length)

$IDERInoteTemplateSelector       = New-Object system.Windows.Forms.Form
$IDERInoteTemplateSelector.ClientSize  = New-Object System.Drawing.Point(400,276)
$IDERInoteTemplateSelector.text  = $lang['window_heading']
$IDERInoteTemplateSelector.TopMost  = $true
$IDERInoteTemplateSelector.icon  = [System.Drawing.Icon]::FromHandle(([System.Drawing.Bitmap]::new($iconStream).GetHIcon()))

$btn_Select                      = New-Object system.Windows.Forms.Button
$btn_Select.text                 = $lang['btn_Select']
$btn_Select.width                = 150
$btn_Select.height               = 30
$btn_Select.Anchor               = 'bottom'
$btn_Select.location             = New-Object System.Drawing.Point(125,226)
$btn_Select.Font                 = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$lbl_TemplateSelection           = New-Object system.Windows.Forms.Label
$lbl_TemplateSelection.text      = $lang['lbl_TemplateSelection']
$lbl_TemplateSelection.AutoSize  = $true
$lbl_TemplateSelection.width     = 360
$lbl_TemplateSelection.height    = 10
$lbl_TemplateSelection.Anchor    = 'top,right,left'
$lbl_TemplateSelection.location  = New-Object System.Drawing.Point(21,34)
$lbl_TemplateSelection.Font      = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$lstBox_Templates                = New-Object system.Windows.Forms.ListBox
$lstBox_Templates.width          = 360
$lstBox_Templates.height         = 140
$lstBox_Templates.Anchor         = 'top,right,left'
$lstBox_Templates.location       = New-Object System.Drawing.Point(21,66)

$IDERInoteTemplateSelector.controls.AddRange(@($btn_Select,$lbl_TemplateSelection,$lstBox_Templates))


# Disable resize of form and set start position
$IDERInoteTemplateSelector.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen;
$IDERInoteTemplateSelector.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$IDERInoteTemplateSelector.MaximizeBox = $false;
$IDERInoteTemplateSelector.WindowState = "Normal"
# Set horizontal scrollbar for ListBox
$lstBox_Templates.HorizontalScrollbar = "auto";

#######################################
# Events
#######################################
$IDERInoteTemplateSelector.Add_Load({ onLoad_form -TemplateFolder $TEMPLATE_FOLDER })
$btn_Select.Add_Click({ onClick_ButtonSelect -templateName $lstBox_Templates.SelectedItem.ToString() })
$lstBox_Templates.Add_DoubleClick({ onClick_ButtonSelect -templateName $lstBox_Templates.SelectedItem.ToString() })
$IDERInoteTemplateSelector.Add_Shown({ onShown_form })

#######################################
# Functions
#######################################
function onLoad_form ([string]$TemplateFolder)
{
    $templateNameList = New-Object System.Collections.ArrayList

    $templates = Get-ChildItem "$TEMPLATE_FOLDER\*.ini"

    foreach ($item in $templates)
    {
        if($item.Name -ne $SRV_CONNECTION_INI_FILE_NAME)
        {
            $templateName = ($item.Name).Replace(".ini","")
            $templateNameList.Add($templateName)
        }
    }

    $templateNameList | ForEach-Object {[void] $lstBox_Templates.Items.Add($_)}
    if($lstBox_Templates.Items.Count -gt 0)
    {
        $lstBox_Templates.SelectedItem = $DEFAULT_TEMPLATE
    }
}

function onShown_form ()
{
    $IDERInoteTemplateSelector.Focus()
    $IDERInoteTemplateSelector.TopMost = $false;
}

function onClick_ButtonSelect ([string]$templateName)
{
    $template = Get-ChildItem "$TEMPLATE_FOLDER\$templateName.ini"

    $templateContent = Get-Content $template -Raw -Encoding UTF8
    if(Test-Path "$TEMPLATE_FOLDER\$SRV_CONNECTION_INI_FILE_NAME" -ErrorAction SilentlyContinue)
    {
        $templateContent = AppendInoteServerConnectionIniSectionToTemplate -ConnectionSectionFile "$TEMPLATE_FOLDER\$SRV_CONNECTION_INI_FILE_NAME" -TemplateContent $templateContent
    }

    $templateContent | Out-File "$env:TEMP\iNoteTemplate.ini" -Force

    Start-Process -FilePath $INTQDADM_EXE_PATH -ArgumentList "/ini=`"$env:TEMP\iNoteTemplate.ini`"" #`"$($template.FullName)`""
}

function AppendInoteServerConnectionIniSectionToTemplate ([string]$ConnectionSectionFile, [string]$TemplateContent)
{
    $connectionSection = [string]::Empty

    if(!$TemplateContent.Contains("[Connection]"))
    {
        $connectionSection = Get-Content $ConnectionSectionFile -Raw -Encoding UTF8
        $TemplateContent += [System.Environment]::NewLine + $ConnectionSection
    }

    return $TemplateContent
}

#######################################
# Script
#######################################

#Write your logic code here

[void]$IDERInoteTemplateSelector.ShowDialog()

#Dispose
$IconStream.Dispose()
$IDERInoteTemplateSelector.Dispose()