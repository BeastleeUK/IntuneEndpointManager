##Credit to CodyRWhite (https://github.com/CodyRWhite) for the orignal code and idea

$VerbosePreference = "Continue"
$DebugPreference = "Continue"

## Log Variables
$logPath = $(Join-Path -Path $env:windir -Childpath "Logs\Intune\WingetInstalls")
$logFile = "$($(Get-Date -Format "yyyy-MM-dd hh.mm.ssK").Replace(":",".")) - Detect-AppInstaller.log"
$errorVar = $null

$settingsFilePath = $(Join-Path $env:ProgramData -ChildPath "Intune\settings.json")
If (Test-Path -Path $settingsFilePath){
    $intuneSettings = Get-Content -Raw -Path $settingsFilePath | ConvertFrom-Json
    $debug = [bool]$intuneSettings.Settings.InstallDebug
}else{
    $debug = $false
}

IF ($debug) {

    If (!(Test-Path -Path $logPath)){
        New-Item -Path $logPath -ItemType Directory -Force
    }  
    Start-Transcript -Path "$logPath\$logFile"
}

try{
    Write-Verbose "Starting detection for App Installer"
    $WorkingDir = $(Get-Location).Path
    Push-Location -StackName WorkingDir
    Push-Location "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe" -ErrorAction SilentlyContinue
    IF( $(Get-Location).Path -eq $WorkingDir){
        Write-Verbose "App Installer Not Installed"
        Exit 1
    }Else{
        Write-Verbose "App Installer already installed"
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

    If ($debug) {Stop-Transcript}
    $VerbosePreference = "SilentlyContinue"
    $DebugPreference = "SilentlyContinue"

    If ($errorVar){
        throw $errorVar 
    }
}