
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

<# 
Removes Windows Search Indexing.
Disable-WindowsOptionalFeature -Online -NoRestart -Remove -FeatureName SearchEngine-Client-Package

Remove-WindowsCapability -Online -Name Hello.Face.18330
#>

#SET VARIABLES
$WindowsOptionalFeatures2Remove=@(
"Internet-Explorer-Optional-x86",
"SMB1Protocol",
"SMB1Protocol-Client",
"SMB1Protocol-Deprecation",
"FaxServicesClientPackage",
"Printing-XPSServices-Features"
)

$AppXNames2Exclude=@(
    "Dolby",
    "Intel",
    "Lenovo",
    "Wacom",
    "Realtek",
    #The next line is important to allow for reinstallation of apps via powershell again. Also store is removable but would need to be reinstalled via 
    "store","extension","advertising","NET","UI","VCLibs"
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
    $OneDriveExePath="$Env:SystemRoot\$($SystemDir)\OneDriveSetup.exe"

    if (Test-Path $OneDriveExePath){
        $OneDriveUninstExpr="$($OneDriveExePath) /uninstall"
        #Make sure onedrive isn't ruinning anymore.
        $OneDriveProcess=@(Get-Process "*onedrive*")
        if ($OneDriveProcess.Count -ne 0 ) { Stop-Process -Force -Name OneDrive }
        
        #Invoke Uninstall Expression
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
function Remove-AppXPackages {
    param([array] $AppXNames2Exclude )
    #Create List of all Packages that are removable at all.
    $RemovablePackages=Get-AppxPackage -AllUsers | Where-Object { -not $_.NonRemovable }
    
    #Filters that list according to pre-defined criteria
    function FiltertMatchesInList {
        param ($value, [Array]$List)
        foreach ($item in $List) {
            if ($value -match $item) {
              return $False
            }
          }
          return $True
    }
    
    #$Packa ges2Remove=$RemovablePackages | filterAgainstList $AppXNames2Exclude $_ 
    $Packages2Remove=$RemovablePackages | Where-Object { 
        FiltertMatchesInList $_.Name $AppXNames2Exclude 
    }
    
    $Packages2Remove | Remove-AppxPackage -AllUsers -ErrorAction Inquire
    
}

#DO STUFF
#Disable Windows Seach Webresults
Set-WindowsSearchSetting -EnableWebResultsSetting 0

Install-OpenSSHServer

Remove-WindowsOptionalFeatures($WindowsOptionalFeatures2Remove)

Remove-OneDrive

Remove-AppXPackages $AppXNames2Exclude