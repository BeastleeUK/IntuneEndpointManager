<#
.SYNOPSIS
	This script performs the installation or uninstallation of application(s) via the winget command.
.DESCRIPTION
	The script either performs an "Install" (default) or an "Uninstall".  It is designed for deployment from MDM services, e.g. Intune.
	The install action has a number of additional paramaters that are passed to the winget command.
	The script requires a the Microsoft Desktop App Installer package to be installed and checks for it at runtime.
.PARAMETER action
	The type of action to perform. Default is: Install.
.PARAMETER appID
	The specific name or ID of the package to be installed.
.PARAMETER source
	The source location of the package, this can be winget (default) or msstore.
.PARAMETER override
	Allows the passing of command line switches to the installer.
.EXAMPLE
    powershell.exe -Command "& { & '.\Manage-WingetApp.ps1' -appID "Microsoft.PowerToys" }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Manage-WingetApp.ps1' -appID "Microsoft.PowerToys" -action "uninstall" }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Manage-WingetApp.ps1' -appID "Microsoft.PowerToys" -override /InstallPath="C:\Temp" }"
.NOTES
	Credit to CodyRWhite (https://github.com/CodyRWhite) for the orignal code
.LINK
	BeastleeUK Github Repository https://github.com/BeastleeUK/IntuneEndpointManager
.LINK
    Microsoft Winget Documentation https://docs.microsoft.com/en-us/windows/package-manager/winget/
#>

param (
    [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$action = "install",
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$appID,
    [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$source = "winget",
    [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$scope = "machine",
    [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$override
)

$VerbosePreference = "Continue"
$DebugPreference = "Continue"


$logPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\CustomLogging\InstallLogs"
$logSettingsPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\CustomLogging"
$settingsFilePath = "$logSettingsPath\settings.json"
$logFile = "$($(Get-Date -Format "yyyy-MM-dd hh.mm.ssK").Replace(":",".")) - $appID.log"
$errorVar = $null
$installResult = $null

If (Test-Path -Path $settingsFilePath) {
    $intuneSettings = Get-Content -Raw -Path $settingsFilePath | ConvertFrom-Json
    $debug = [bool]$intuneSettings.Settings.InstallDebug
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
    Write-Verbose "Starting $action of $appID"
    Push-Location "$env:SystemDrive\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe"
    $appFilePath = "$(Get-Location)\AppInstallerCLI.exe"
    If (Test-Path -Path $appFilePath){
        switch ($action) {

            "install" {
                $argumentList =  [System.Collections.ArrayList]@("install", "--silent", "--accept-package-agreements", "--accept-source-agreements", "--source $source", "--scope $scope", "--exact `"$appID`"")
                If ($override) { $argumentList.Add("--override `"$override`"") }       
            }

            "uninstall" {
                $argumentList =  [System.Collections.ArrayList]@("uninstall", "--silent", "--exact `"$appID`"")
            }

            default {
                Write-Verbose "No valid action specified. Exiting."
                Exit 1
            }
        }
        $cliCommand = '& $appFilePath ' + $argumentList
        $installResult =  Invoke-Expression $cliCommand | Out-String
        Write-Verbose $installResult
    }else{
        Write-Verbose "App Installer not installed"
        Exit 1
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

    IF ($debug) {Stop-Transcript}
    $VerbosePreference = "SilentlyContinue"
    $DebugPreference = "SilentlyContinue"

    Pop-Location
}