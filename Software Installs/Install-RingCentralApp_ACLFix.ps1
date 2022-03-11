# Requires -Version 3.0
<#
    .SYNOPSIS
        This script is to install RingCentral

    .DESCRIPTION
        The script will check for the existence of the PrinterNightmare mitigation. If it applied It will remove it.

#>

$URL = "https://downloads.ringcentral.com/sp/RingCentralForWindows"

$FolderPath = "C:\windows\temp"
$FilePath = "$Folderpath\RingCentral.msi"
$MSILogFile = "$FolderPath\InstallLog.log"
$Arguments = @"
/c msiexec /i "$FilePath" /qn /norestart /L*v "$MSILogFile"
"@

Function Get-PrinterACL {
    # This ACL gets the current printer ACL to determine if PrinterNightmare workaround is applied
    $Path = "C:\Windows\System32\spool\drivers"
    $CheckRight = (Get-Item $Path).GetAccessControl().Access | ? { $_.IdentityReference -eq "NT AUTHORITY\SYSTEM" -and $_.AccessControlType -eq "Deny" }
    If ($CheckRight.Count -gt 0) {
        Write-Output "Rule Exists"
    }

    else {
        Write-Output "Rule Not Exists"
    }
}

Function Clear-PrinterNightmare {
    # This function will clear the DENY rule for SYSTEM on the ACL of the spool folder
    $Path = "C:\Windows\System32\spool\drivers"
    $Acl = (Get-Item $Path).GetAccessControl('Access')
    $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("System", "Modify", "ContainerInherit, ObjectInherit", "None", "Deny")
    $Acl.RemoveAccessRule($Ar)
}
Function Set-PrinterNightmare {
    # This function will set the DENY rule for SYSTEM on the ACL of spool folder
    $Path = "C:\Windows\System32\spool\drivers"
    $Acl = (Get-Item $Path).GetAccessControl('Access')
    $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("System", "Modify", "ContainerInherit, ObjectInherit", "None", "Deny")
    $Acl.AddAccessRule($Ar)
    Set-Acl $Path $Acl
}


function Get-Folder {
    # Checks that the destination folder exists
    if (!(Test-Path $FolderPath)) {
        Write-Output "Creating Folder"
        cmd /c "mkdir $FolderPath"
    }
}

Function Get-Software {
    # Downloads the installer(s) for the application
    $Installer = Get-Item "$FilePath" -ErrorAction SilentlyContinue

    if (Test-Path $Installer) {
        Write-Output "Installer found."
        return
    }
    else {    
        Write-Output "File missing. Begin downloading from $DownloadURL"
        Invoke-WebRequest -uri $URL -OutFile $FilePath
        return
    }
}

Function Install-Software {
    # Installs the application and provides the Exit Code
    if (!(Test-Path $FilePath)) {
        Write-output "Cannot complete file install. Installer is missing"
        exit 1
    }
    $Process = Start-Process -Wait cmd -ArgumentList $Arguments -Passthru
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

Get-Folder
Invoke-WebRequest -uri $url -outfile $FilePath
$GetPrinterAcl = Get-PrinterACL
if ($GetPrinterAcl -eq "Rule Exists") {
    Clear-PrinterNightmare
}
Install-Software
if ($GetPrinterAcl -eq "Rule Exists") {
    Set-PrinterNightmare
}