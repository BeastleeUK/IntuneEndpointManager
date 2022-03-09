<#
.SYNOPSIS
	Installs the Microsoft App Installer Package, a pre-requisite for winget based package deployments.
.DESCRIPTION
	Installs the Microsoft App Installer Package, a pre-requisite for winget based package deployments.
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
$logFile = "$($(Get-Date -Format "yyyy-MM-dd HH.mm.ssK").Replace(":","."))-Install-AppInstaller.log"
$errorVar = $null

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
    $wingetURL = "https://aka.ms/getwinget"
    $bundlePath = "$PSScriptRoot\package.msixbundle"

    Write-Verbose "Starting detection for App Installer"
    $WorkingDir = $(Get-Location).Path
    Push-Location -StackName WorkingDir
    Push-Location "$env:SystemDrive\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe" -ErrorAction SilentlyContinue
    IF( $(Get-Location).Path -eq $WorkingDir){
        Write-Verbose "App Installer Not Installed - Starting Download"
        Invoke-WebRequest $wingetURL -UseBasicParsing -OutFile $bundlePath
        Write-Verbose -Verbose "Installing msixbundle for App Installer"
        DISM.EXE /Online /Add-ProvisionedAppxPackage /PackagePath:$bundlePath /SkipLicense
        Pop-Location -StackName WorkingDir
        exit 0
    }Else{
        $installedVersionFolder = Split-Path -Path (Get-Location) -Leaf
        $appFilePath = "$(Get-Location)\winget.exe"
    
        IF (!(Test-Path -Path $appFilePath)){

            Write-Verbose -Verbose "$appFilePath does not exist, trying winget.exe"
            $appFilePath = "$(Get-Location)\AppInstallerCLI.exe"
            IF (!(Test-Path -Path $appFilePath)){    
        
                Write-Verbose -Verbose "winget.exe and AppInstallerCLI.exe do not exist, uninstalling current version"
                Remove-AppPackage -Package $installedVersionFolder

                Write-Verbose -Verbose "App Installer not installed, starting download"
                Invoke-WebRequest $wingetURL -UseBasicParsing -OutFile $bundlePath

                Write-Verbose -Verbose "Installing msixbundle for App Installer"
                DISM.EXE /Online /Add-ProvisionedAppxPackage /PackagePath:$bundlePath /SkipLicense
                exit 0
            }
        }else{
            Write-Verbose -Verbose "App Installer already Installed"
            Exit 0
        }
        Pop-Location -StackName WorkingDir
    }
    Write-Verbose "Checking for settings file"
    $settingsFolder = "$env:ProgramData\Intune"
    $settingsFilePath = "$settingsFolder\Intune\settings.json"
    If (!(Test-Path -Path $settingsFilePath)) {
        New-Item -Path $settingsFolder -ItemType Directory -Force
        Copy-Item -Path "$PSScriptRoot\intune_settings.json" -Destination "$settingsFilePath"
    }
}
Catch {
    $errorVar = $_.Exception.Message
}
Finally {
    If ($errorVar){
        Write-Verbose "Script Errored"
        Write-Error  $errorVar
        Pop-Location -StackName WorkingDir
    }else{
        Write-Verbose "Script Completed"
    }   

    If( $debug) { Stop-Transcript }
    $VerbosePreference = "SilentlyContinue"
    $DebugPreference = "SilentlyContinue"


}