<#
.SYNOPSIS
	Checks if the Microsoft App Installer Package, a pre-requisite for winget based package deployments, is installed.
.DESCRIPTION
	Checks if the Microsoft App Installer Package, a pre-requisite for winget based package deployments, is installed.
.NOTES
	Credit to CodyRWhite (https://github.com/CodyRWhite) for the orignal code
.LINK
	BeastleeUK Github Repository https://github.com/BeastleeUK/IntuneEndpointManager
.LINK
    Microsoft Winget Documentation https://docs.microsoft.com/en-us/windows/package-manager/winget/
#>

$VerbosePreference = "Continue"
$DebugPreference = "Continue"

$logPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\CustomLogging\InstallLogs"
$logSettingsPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\CustomLogging"
$settingsFilePath = "$logSettingsPath\settings.json"
$logFile = "$($(Get-Date -Format "yyyy-MM-dd hh.mm.ssK").Replace(":",".")) - $appID.log"
$errorVar = $null

If (Test-Path -Path $settingsFilePath) {
    $intuneSettings = Get-Content -Raw -Path $settingsFilePath | ConvertFrom-Json
    $debug = [bool]$intuneSettings.Settings.DetectionDebug
}else{
    $debug = $false
}

If ($debug) {
    IF (!(Test-Path -Path $logPath)){
        New-Item -Path $logPath -ItemType Directory -Force
    }
    Start-Transcript -Path "$logPath\$logFile"
}

try{
    $WindowsAppsPath = $env:SystemDrive + "\Program Files\WindowsApps"
    $AppInstallerFolders = (Get-ChildItem -Path $WindowsAppsPath | Where-Object { $_.Name -like "Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe" } | Select-Object Name)
    $AppInstallerFound = $false
    If ( $AppInstallerFolders) {
        ForEach ($FolderName in $AppInstallerFolders) {
            $appFilePath = (Join-Path -path $WindowsAppsPath -ChildPath $FolderName.Name | Join-Path -ChildPath "AppInstallerCLI.exe")
             If (Test-Path -Path $appFilePath) {
                $AppInstallerFound = $true
            }
        }
    }
    If ($AppInstallerFound) {
        Write-Verbose "App Installer is already present. Nothing to do"
        Exit 0 

    }else{
        Write-Verbose "App Installer not Installed, installing package"
        Exit 1
    }
}
Catch {
    $errorVar = $_.Exception.Message
}
Finally {
    If ($errorVar){
        Write-Verbose "Script Errored"
        Write-Error  $errorVar
    } 

    If ($debug) {Stop-Transcript}
    $VerbosePreference = "SilentlyContinue"
    $DebugPreference = "SilentlyContinue"
}