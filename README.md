# Windows-Cleanup-Script
A Powershell script to remove unwanted apps, services, and optional features and setup the ssh server

What it already does:
- Disables WebSearch in WindowsSearch
- Setup sshd
- Removes OneDrive on both x86 and x64 systems
- Removes the optional Features listed in $WindowsOptionalFeatures2Remove
- Removes all Apps except for the Store and .NET,UI and VCLibs as those seem to be important for getting apps reinstalled via Powershell again.

What is planned for it:
- Install Powershell Core 6
- Remove the preinstalled Powershell 2.
  
NOTE:  
Powershell Core 6 is required for Powershell over SSH. Otherwise SSH drops into CMD and requires starting powershell on top of that.
