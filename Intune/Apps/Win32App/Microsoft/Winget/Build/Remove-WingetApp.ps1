##Credit to CodyRWhite (https://github.com/CodyRWhite) for the orignal code and idea
param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$appID
)

$VerbosePreference = "Continue"
$DebugPreference = "Continue"


$logPath = $(Join-Path -Path $env:windir -Childpath "Logs\Intune\WingetInstalls")
$logFile = "$($(Get-Date -Format "yyyy-MM-dd hh.mm.ssK").Replace(":",".")) - $appID.log"
$errorVar = $null
$installResult = $null

$settingsFilePath = $(Join-Path $env:ProgramData -ChildPath "Intune\settings.json")
$intuneSettings = Get-Content -Raw -Path $settingsFilePath | ConvertFrom-Json
$debug = [bool]$intuneSettings.Settings.InstallDebug

IF (!(Test-Path -Path $logPath)){
    New-Item -Path $logPath -ItemType Directory -Force
}

IF ($debug) {Start-Transcript -Path "$logPath\$logFile"}

try{
    Write-Verbose "Starting removal of $appID"
    Push-Location "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe"
    $appFilePath = "$(Get-Location)\AppInstallerCLI.exe"
    IF (Test-Path -Path $appFilePath){
        $argumentList =  [System.Collections.ArrayList]@("uninstall", "--silent", "--exact `"$appID`"")
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