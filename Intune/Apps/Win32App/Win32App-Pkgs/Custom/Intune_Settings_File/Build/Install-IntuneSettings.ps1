$VerbosePreference = "Continue"
$DebugPreference = "Continue"

## Log Variables
$logPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\CustomLogging\InstallLogs"
$logSettingsPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\CustomLogging"
$settingsFilePath = "$logSettingsPath\settings.json"
$logFile = "$($(Get-Date -Format "yyyy-MM-dd HH.mm.ssK").Replace(":","."))-Install-IntuneSettings.log"
$errorVar = $null

If (!(Test-Path $logPath)) { New-Item -Path $logPath -ItemType Directory -Force }
Start-Transcript -Path "$logPath\$logFile"

try{   
    If (!(Test-Path -Path $settingsFilePath)) {
        Write-Verbose "Adding default settings file"
        New-Item -Path $logsettingsPath -ItemType Directory -Force
        Copy-Item -Path "$PSScriptRoot\Files\intune_settings.json" -Destination "$settingsFilePath"
        Exit 0
    }else{
        Write-Verbose "Settings file already present"
        Exit 0
    }
}
Catch {
    $errorVar = $_.Exception.Message
}
Finally {
    IF ($errorVar){
        Write-Verbose "Script Errored"
        Write-Error  $errorVar
    }else{
        Write-Verbose "Script Completed"
    }   

    Stop-Transcript
    $VerbosePreference = "SilentlyContinue"
    $DebugPreference = "SilentlyContinue"
}