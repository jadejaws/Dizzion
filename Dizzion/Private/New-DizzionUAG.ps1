<#
    .SYNOPSIS
    Creates a new VM from the Content Library

    .DESCRIPTION
    The purpose of this script is to deploy a new UAG VM from a content library template.

    .NOTES
    Author: Kevin McClure

    .PARAMETER ContentLibraryItem
    Name of the Item in the Content Library


    .PARAMETER Location
    The Folder Location in the target cluster of the VM

    .PARAMETER VMName
    The Name of the VM to deploy from Content LIbrary

    .PARAMETER Datastore
    The Datastore to Deploy the VM to

    .PARAMETER ResourcePool
    The Cluster to deploy the VM to


    .EXAMPLE
    New-DizzionUAG -Datastore NFS -ContentLibraryItem "UAG 3.7" -Location "Appliance" -VMName "TestUAG" -ResourcePool "Cluster"
#>
function New-DizzionUAG () {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$Datastore,

        [Parameter(Mandatory = $true)]
        [string]$Location,

        [Parameter(Mandatory = $true)]
        [string]$ContentLibraryItem,

        [Parameter(Mandatory = $true)]
        [string]$VMName,

        [Parameter(Mandatory = $true)]
        [string]$ResourcePool

    )

    #Set Timeout to 10 minutes for slow lab
    Set-PowerCLIConfiguration -WebOperationTimeoutSeconds 3600 -Scope AllUsers -Confirm:$false


    try {
        #Create the Content Library
        Add-LogEntry "Creating VM from ContentLibraryItem $ContentLibraryItem"
        Get-ContentLibraryItem $ContentLibraryItem | New-VM -Name $VMName -Location $Location -Datastore $Datastore -ResourcePool $Cluster

        $VMDeploy = "SUCCEEDED"

        $VMDeployStatus = New-Object PSObject -Property @{
            Status             = $VMDeploy

        }
    }


    catch {
        $CaughtException = $_
        $VMDeploy = "FAILED"
        Add-LogEntry $CaughtException
        Add-LogEntry "Error creating VM from Content Library"

        $VMDeployStatus = New-Object PSObject -Property @{
            Status             = $VMDeploy

        }
    }

    $VMDeployStatus

}
