<#
    .SYNOPSIS
    Creates a new Content Library on the connected vCenter named "Global Content Library" by default.

    .DESCRIPTION
    The purpose of this script is to check, remediate and report on the status of lockdown mode for target vCenters.

    .NOTES
    Author: Kevin McClure

    .PARAMETER Datastore
    Name of the Datastore to create the Content Library

    .PARAMETER ContentLibraryName
    Name of the Content Library to create. By default this is set to Global Content Library.

    .EXAMPLE
    New-DizzionContentLibrary -Datastore NFS -ContentLibraryName "Global Content Library"
#>
function New-DizzionContentLibrary () {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$Datastore,
        [Parameter(Mandatory = $false)]
        [string]$ContentLibraryName = 'Global Content Library'
    )

    try {
        #Create the Content Library
        Add-LogEntry "Creating Content Library Global Content Library on vCenter: $vCenter on Datastore: $Datastore"
        New-ContentLibrary -Name $ContentLibraryName -Datastore (Get-Datastore $Datastore) -Published

        $DatastoreCreation = "SUCCEEDED"

        $DatastoreCreationStatus = New-Object PSObject -Property @{
            Status             = $DatastoreCreation
            ContentLibraryName = $ContentLibraryName
            Datastore          = $Datastore

        }
    }


    catch {
        $CaughtException = $_
        $DatastoreCreation = "FAILED"
        Add-LogEntry $CaughtException
        Add-LogEntry "Error creating Content Library: $ContentLibraryName"

        $DatastoreCreationStatus = New-Object PSObject -Property @{
            Status             = $DatastoreCreation
            ContentLibraryName = $ContentLibraryName
            Datastore          = $Datastore

        }
    }

    $DatastoreCreationStatus

}
