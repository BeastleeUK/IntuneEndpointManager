##Credit to CodyRWhite (https://github.com/CodyRWhite) for the orignal code and idea

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
    $wingetURL = "https://aka.ms/getwinget"
    $bundlePath = "$PSScriptRoot\package.msixbundle"

    Write-Verbose "Starting detection for App Installer"
    $WorkingDir = $(Get-Location).Path
    Push-Location -StackName WorkingDir
    Push-Location "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe" -ErrorAction SilentlyContinue
    IF( $(Get-Location).Path -eq $WorkingDir){
        Write-Verbose "App Installer Not Installed - Starting Download"
        Invoke-WebRequest $wingetURL -UseBasicParsing -OutFile $bundlePath
        Write-Verbose -Verbose "Installing msixbundle for App Installer"
        DISM.EXE /Online /Add-ProvisionedAppxPackage /PackagePath:$bundlePath /SkipLicense
        exit 0
    }Else{
        $installedVersionFolder = Split-Path -Path (Get-Location) -Leaf
        $appFilePath = "$(Get-Location)\AppInstallerCLI.exe"
        Pop-Location -StackName WorkingDir

        IF (!(Test-Path -Path $appFilePath)){            
            Write-Verbose -Verbose "AppInstallerCLI.exe does not exist, uninstalling current version"
            Remove-AppPackage -Package $installedVersionFolder

            Write-Verbose -Verbose "$appID not installed, starting download"
            Invoke-WebRequest $wingetURL -UseBasicParsing -OutFile $bundlePath

            Write-Verbose -Verbose "Installing msixbundle for $appID"
            DISM.EXE /Online /Add-ProvisionedAppxPackage /PackagePath:$bundlePath /SkipLicense
            exit 0
        }else{
            Write-Verbose -Verbose "$appID already Installed"
            Exit 0
        }
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