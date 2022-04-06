# Requires -Version 3.0
<#
    .SYNOPSIS
        This script is to install Falcon CrowdStrike Sensor on Windows

    .DESCRIPTION
        The script will install Falcon CrowdStrike silently. It requires access or a link
        to the MSI file and a few variables in the Automate script.

#>

$FolderPath = "C:\windows\ltsvc\packages\CrowdStrike"
$Filename = "crowdstrike.exe"
$CustomerID = "@CustomerID@"
$FilePath = "$FolderPath\$FileName"

#Path to Log File
$MSILogFile = "$FolderPath\InstallLog.log"
#Arguments for Installation
$Arguments = @"
/install /quiet /norestart CID=$CustomerID
"@


Function Get-Path{
    # Checks to see if destination folder path exists
if(!(Test-Path -Path $FolderPath)){
    New-Item -ItemType Directory -Path $FolderPath -Force
    Write-Output "Folder did not exist. Created"
    return
}else{
    Write-Output "Folder Exists."
    return
}}

Function Get-Installer{
    #Checks to see if Installer was downloaded properly.
    if(!(Test-Path -Path $FilePath)){
        Write-Output "Installer was not downloaded. Exiting Script"
        exit 1
    } else{
    Write-Output "Installer has been found. Proceeding"
    return
}}
Function Install-Software {
    # Installs the application and provides the Exit Code
    if (!(Test-Path $FilePath)) {
        Write-output "Cannot complete file install. Installer is missing"
        exit 1
    }
    $Process = Start-Process -Wait -FilePath $FilePath -ArgumentList $Arguments -Passthru
    Write-Host "Exit Code: $($Process.ExitCode)";
    switch ($Process.ExitCode) {
        0 { Write-Host "Success" }
        3010 { Write-Host "Success. Reboot required to complete installation" }
        1641 { Write-Host "Success. Installer has initiated a reboot" }
        default {
            Write-Host "Exit code does not indicate success"
            Get-Content $MSILogFile -ErrorAction SilentlyContinue | select -Last 50
        }
    }
}

Get-Path
Get-Installer
Install-Software