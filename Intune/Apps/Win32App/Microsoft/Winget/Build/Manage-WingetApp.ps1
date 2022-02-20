##Credit to CodyRWhite (https://github.com/CodyRWhite) for the orignal code and idea
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


$logPath = $(Join-Path -Path $env:windir -Childpath "Logs\Intune\WingetInstalls")
$logFile = "$($(Get-Date -Format "yyyy-MM-dd hh.mm.ssK").Replace(":",".")) - $appID.log"
$errorVar = $null
$installResult = $null

$settingsFilePath = $(Join-Path -Path $env:ProgramData -ChildPath "Intune\settings.json")
$intuneSettings = Get-Content -Raw -Path $settingsFilePath | ConvertFrom-Json
$debug = [bool]$intuneSettings.Settings.InstallDebug

IF (!(Test-Path -Path $logPath)){
    New-Item -Path $logPath -ItemType Directory -Force
}

IF ($debug) {Start-Transcript -Path "$logPath\$logFile"}

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