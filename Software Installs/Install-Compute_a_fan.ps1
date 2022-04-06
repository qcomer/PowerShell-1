<#
.SYNOPSIS 
Installs the Compute A Fan Software

#>

$SoftwareName = "Compute-A-Fan"
[string]$Version = "10.2"
$FolderPath = "C:\windows\ltsvc\packages\$SoftwareName"
$FilePath = "$FolderPath\$Softwarename`_$version.exe"
$URL = "https://downloads.lorencook.com/downloads/cafwin/$SoftwareName`_$version.exe"
$params = @(
    '/S',
    '/v/qn'
)
Function Get-Folder ($SoftwareName) {
    if (!(Test-Path $FolderPath)) {
        Write-Output "$FolderPath does not exist. Creating"
        New-Item -Path "$FolderPath" -ItemType "Directory" -Force
    }
    else {
        Write-Output "$FolderPath exists."
    }
}
Function Get-Software {
    Write-Output "Downloading installer files for $Softwarename"    
    $Download = Start-BitsTransfer -Source "$URL" -Destination "$FolderPath" -Description "Downloading install files for $Softwarename" -DisplayName "$SoftwareName Download" -Asynchronous
    while (($Download.JobState -eq "Transferring") -or ($Download.JobState -eq "Connecting")) {
        Start-Sleep 5
    }
    switch ($Download.JobState) {
        "Transferred" { Complete-BitsTransfer -BitsJob $Download }
        "Error" { $Download | Format-List }
        default { Write-Output "Failed to Download"; }
    }
}

Function Install-Software {
    $Process = Start-Process $FilePath -wait -passthru -nonewwindow -ArgumentList $params
    if ($Process.ExitCode -ne 0) {
        Write-Output "$_ exited with status code $($Process.ExitCode)"
    }
    else {
        Write-Output "Successfully installed $Softwarename"
    }

}
Get-Folder
Get-Software
Install-Software