$VerbosePreference = "Continue"
$DebugPreference = "Continue"

## Log Variables
$logPath = $(Join-Path -Path $env:windir -Childpath "Logs\Intune\WingetInstalls")
$logFile = "$($(Get-Date -Format "yyyy-MM-dd hh.mm.ssK").Replace(":",".")) - Install-AppInstaller.log"
$errorVar = $null

If (!(Test-Path -Path $logPath)){
    New-Item -Path $logPath -ItemType Directory -Force
}

Start-Transcript -Path "$logPath\$logFile"

try{   
    $settingsFolder = "$env:ProgramData\Intune"
    $settingsFilePath = "$settingsFolder\settings.json"
    If (!(Test-Path -Path $settingsFilePath)) {
        Write-Verbose "Adding default settings file"
        New-Item -Path $settingsFolder -ItemType Directory -Force
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
    If ($errorVar){
        Write-Verbose "Script Errored"
        Write-Error  $errorVar
    }else{
        Write-Verbose "Script Completed"
    }   

    Stop-Transcript
    $VerbosePreference = "SilentlyContinue"
    $DebugPreference = "SilentlyContinue"

    If ($errorVar){
        throw $errorVar 
    }
}