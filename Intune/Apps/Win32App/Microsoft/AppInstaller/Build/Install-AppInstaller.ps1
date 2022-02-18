$VerbosePreference = "Continue"
$DebugPreference = "Continue"

## Script Variables
$scriptPath = $MyInvocation.MyCommand.Definition
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
    Write-Verbose "Starting detection for App Installer"
    $WindowsAppsPath = $env:ProgramFiles + "\WindowsApps"
    $AppInstallerFolders = (Get-ChildItem -Path $WindowsAppsPath | Where-Object { $_.Name -like "Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe" } | Select-Object Name)
    $AppInstallerFound = $false
    If ( $AppInstallerFolders) {
        ForEach ($FolderName in $AppInstallerFolders) {
            $appFilePath = (Join-Path -path $WindowsAppsPath -ChildPath $FolderName.Name | Join-Path -ChildPath "AppInstallerCLI.exe")
            Write-Verbose "Checking for application at $appFilePath"
            If (Test-Path -Path $appFilePath) {
                $AppInstallerFound = $true
                Write-Verbose "File Found"
            }else{
                Write-Verbose "File not Found"
            }

        }
    }
    If (!($AppInstallerFound)) {
        Write-Verbose "App Installer not Installed, installing package"
        $PackagePath = Get-ChildItem -Path $dirFiles -Include "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -File -Recurse -ErrorAction SilentlyContinue
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