<#
.SYNOPSIS 
Installs the HAP Software

#>
Function Check-Folder {
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$SoftwareName
    )

    switch ($SoftwareName) {
        XBuilder { $FolderName = "XBuilder" }
        HAP { $FolderName = "HAP" }
        Default { Write-Output "No Software Name Detected. Exiting Script."; exit 1 }
    }
    $FolderPath = "C:\windows\ltsvc\packages\$FolderName"
    if (!(Test-Path $FolderPath)) {
        Write-Output "$FolderPath does not exist. Creating"
        New-Item -Path "$FolderPath" -ItemType "Directory" -Force
    }
    else {
        Write-Output "$FolderPath exists."
    }
}
Function Get-Software {
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$SoftwareName
    )
    switch ($SoftwareName) {
        XBuilder { $URL = "https://www.shareddocs.com/hvac/docs/1004/public/02/ecat-xbuilder/23/ecat-xbuilder.exe" }
        HAP { $URL = "https://www.shareddocs.com/hvac/docs/1004/public/02/ecat-xbuilder/23/ecat-xbuilder.exe" }
        Default { Write-Output "No Software Name Detected. Exiting Script."; exit 1 }
    }
    $FolderPath = "C:\windows\ltsvc\packages\$Softwarename"
    if (!(Test-Path $FolderPath)) {
        Write-Output "$FolderPath does not exist. Creating"
        New-Item -Path "$FolderPath" -ItemType "Directory" -Force
    }
    else {
        Write-Output "$FolderPath exists."
    }
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
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$SoftwareName
    )

    switch ($SoftwareName) {
        XBuilder {
            $FolderName = "XBuilder"
            $exe = "ecat-xbuilder.exe" 
        }
        HAP { $FolderName = "HAP" }
        Default { Write-Output "No Software Name Detected. Exiting Script."; exit 1 }
    }
    $FilePath = "C:\windows\ltsvc\packages\$FolderName\$exe"
    $Process = Start-Process "$FilePath" -wait -passthru -WindowStyle hidden -ArgumentList "/s"
    if ($Process.ExitCode -ne 0) {
        Write-Output "$_ exited with status code $($Process.ExitCode)"
    }
    else {
        Write-Output "Successfully installed $Softwarename"
    }


}
Check-Folder -SoftwareName "XBuilder"; Get-Software -SoftwareName "XBuilder"; Install-Software -SoftwareName "XBuilder"