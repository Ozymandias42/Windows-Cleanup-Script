
<# 
Service names to do stuff with later, maybe?
WSearch - Windows Search
sshd - ssh server
Spooler - Druckerwarteschlange
SEMgrSvc - Zahlungs- und NFC/SE-Manager
WinDefend - Windows Defender
WdNisSvc - Windows Defender Netzwerkinspektionsdienst
DiagTrack - Benutzererfahrung und Telemetrie im verbundenen Modus
#>

#SET VARIABLES
#Install openssh server


$WindowsOptionalFeatures2Remove=@(
"Internet-Explorer-Optional-x86",
"SMB1Protocol",
"SMB1Protocol-Client",
"SMB1Protocol-Deprecation",
"FaxServicesClientPackage",
"Printing-XPSServices-Features"
)

#DEFINE FUNCTIONS
function Remove-OneDrive {
    param ()
    if($Env:PROCESSOR_ARCHITECTURE -match "x86") {
        $SystemDir="System32"
    }
    else {
        $SystemDir="SysWOW64"
    }
    $OneDriveUninstExpr="$Env:SystemRoot\$($SystemDir)\OneDriveSetup.exe /uninstall"

    if (Test-Path ){
        Invoke-Expression "$OneDriveUninstExpr"
    }    
    
}
function Install-OpenSSHServer {
    param()
    $sshd_installed={ 
        Get-WindowsCapability -Online|
            Where-Object Name -match "openssh.server"|
            Select-Object State
    }
    if ($sshd_installed -notmatch "Installed") {
        Add-WindowsCapability -Online -Name OpenSSH.Server    
    }
    if ((Get-Service sshd).State -notmatch "Running") {
    Set-Service sshd -StartupType AutomaticDelayedStart
    Start-Service sshd
    }
}
function Remove-WindowsOptionalFeatures {
    param([Array] $WindowsOptionalFeatures2Remove)
    
    Get-WindowsOptionalFeature -Online |
    Where-Object State -EQ "Enabled"|
    ForEach-Object {
        if ($_.FeatureName -in $WindowsOptionalFeatures2Remove) {
            Disable-WindowsOptionalFeature -Online -NoRestart -Remove -FeatureName $_.FeatureName
        }
    }
}
#DO STUFF

#Disable Windows Seach Webresults
Set-WindowsSearchSetting -EnableWebResultsSetting 0

Install-OpenSSHServer

Remove-WindowsOptionalFeatures($WindowsOptionalFeatures2Remove)

Get-AppxPackage -AllUsers | 
    Where-Object {
        $_.Name -NotMatch "store|extension|advertising|NET|UI|VCLibs" -and -not $_.NonRemovable 
    }   |Remove-AppxPackage -AllUsers -ErrorAction Inquire




Remove-OneDrive


