$VerbosePreference = "Continue"
$DebugPreference = "Continue"

## Script Variables
$scriptPath = $MyInvocation.MyCommand.Definition
$scriptName = [IO.Path]::GetFileNameWithoutExtension($scriptPath)
$scriptFileName = Split-Path -Path $scriptPath -Leaf
$scriptRoot = Split-Path -Path $scriptPath -Parent
$scriptParentPath = (Get-Item -LiteralPath $scriptRoot).Parent.FullName

## Files location
$dirFiles = Join-Path -Path $scriptParentPath -ChildPath 'Files'

## Log Variables
$logPath = $(Join-Path -Path $env:windir -Childpath "Logs\Intune\WingetInstalls")
$logFile = "$($(Get-Date -Format "yyyy-MM-dd hh.mm.ssK").Replace(":",".")) - Install-AppInstaller.log"
$errorVar = $null

If (!(Test-Path -Path $logPath)){
    New-Item -Path $logPath -ItemType Directory -Force
}

Start-Transcript -Path "$logPath\$logFile"

try{
    $ExtractPath = $(Get-Location)
    Write-Verbose "Starting detection for App Installer"
    $appFilePath = $env:ProgramFiles + "\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\AppInstallerCLI.exe"
    If (!(Test-Path -Path $appFilePath)){
        Write-Verbose "App Installer not Installed, installing package"
        $PackagePath = Get-ChildItem -Path $ExtractPath -Include "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -File -Recurse -ErrorAction SilentlyContinue
        Add-AppPackage -path $PackagePath
    }else{
        Write-Verbose "App Installer is already present. Nothing to do"
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