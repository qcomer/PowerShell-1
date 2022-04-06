function Install-ClickOnce {
    [CmdletBinding()] 
    Param(
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "URL",
            HelpMessage = "Please provide the URL to the .application manifest. This can be found in the website")]
        [ValidateNotNullorEmpty()]
        [Alias("URL")]
        $Manifest,
        #AssertApplicationRequirements
        $ElevatePermissions = $true
    )
    Try { 
        Add-Type -AssemblyName System.Deployment
            
        Write-Verbose "Start installation of ClickOnce Application $Manifest "
    
        $RemoteURI = [URI]::New( $Manifest , [UriKind]::Absolute)
        if (-not  $Manifest) {
            throw "Invalid ConnectionUri parameter '$ConnectionUri'"
        }
    
        $HostingManager = New-Object System.Deployment.Application.InPlaceHostingManager -ArgumentList $RemoteURI , $False
        
        #register an event to trigger custom event (yep, its a hack)
        Register-ObjectEvent -InputObject $HostingManager -EventName GetManifestCompleted -Action { 
            new-event -SourceIdentifier "ManifestDownloadComplete"
        } | Out-Null
        #register an event to trigger custom event (yep, its a hack)
        Register-ObjectEvent -InputObject $HostingManager -EventName DownloadApplicationCompleted -Action { 
            new-event -SourceIdentifier "DownloadApplicationCompleted"
        } | Out-Null
    
        #get the Manifest
        $HostingManager.GetManifestAsync()
    
        #Waitfor up to 5s for our custom event
        $event = Wait-Event -SourceIdentifier "ManifestDownloadComplete" -Timeout 5
        if ($event ) {
            $event | Remove-Event
            Write-Verbose "ClickOnce Manifest Download Completed"
    
            $HostingManager.AssertApplicationRequirements($ElevatePermissions)
            #todo :: can this fail ?
                
            #Download Application
            $HostingManager.DownloadApplicationAsync()
            #register and wait for completion event
            # $HostingManager.DownloadApplicationCompleted
            $event = Wait-Event -SourceIdentifier "DownloadApplicationCompleted" -Timeout 500
            if ($event ) {
                $event | Remove-Event
                Write-Verbose "ClickOnce Application Download Completed"
            }
            else {
                Write-error "ClickOnce Application Download did not complete in time (15s)"
            }
        }
        else {
            Write-error "ClickOnce Manifest Download did not complete in time (5s)"
        }
    
        #Clean Up
    }
    finally {
        #get rid of our eventhandlers
        Get-EventSubscriber | ? { $_.SourceObject.ToString() -eq 'System.Deployment.Application.InPlaceHostingManager' } | Unregister-Event
    }
}