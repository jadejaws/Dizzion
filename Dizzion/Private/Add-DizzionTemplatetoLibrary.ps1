function Add-DizzionTemplateToLibrary {
    <#
    .SYNOPSIS
    Converts a VM deployed from OVA to a Template in a specified Content Library

    .DESCRIPTION
    The purpose of this script is to convert an OVA Deployed VM to a Template in an existing Content Library

    .NOTES
    Author: Kevin McClure

    .PARAMETER LibraryName
    Name of the libray to which item needs to be uploaded.

    .PARAMETER VMname
    Name of the VM to upload.

    .PARAMETER LibItemName
    Name of the template after imported to library.

    .PARAMETER Description
    Description of the imported item.

    .EXAMPLE
    Add-DizzionTemplateToLibrary -LibraryName 'Global Content Library' -VMname 'EUC Unified Access Gateway' -LibItemName 'EUC Unified Access Gateway Template' -Description '3.7 UAG'
#>


    param(
        [Parameter(Mandatory = $true)]
        [string]$LibraryName,

        [Parameter(Mandatory = $true)]
        [string]$VMname,

        [Parameter(Mandatory = $true)]
        [string]$LibItemName,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    try {
        Add-LogEntry "Saving Content Library API to Variable"
        $ContentLibraryService = Get-CisService com.vmware.content.library

        #Loop through and locate Library from available
        $libaryIDs = $contentLibraryService.list()
        foreach ($libraryID in $libaryIDs) {
            $library = $contentLibraryService.get($libraryID)
            if ($library.name -eq $LibraryName) {
                $library_ID = $libraryID
                break
            }
        }
        $TemplatetoLibrary = "SUCCEEDED"
        $TemplateLibraryStatus = New-Object PSObject -Property @{
            TemplatetoLibraryStatus = $TemplatetoLibrary
        }

    }

    catch {
        $CaughtException = $_
        $TemplatetoLibrary = "FAILED"
        Add-LogEntry $CaughtException
        Add-LogEntry 'Error moving template to Library'
        $TemplateLibraryStatus = New-Object PSObject -Property @{
            TemplatetoLibraryStatus = $TemplatetoLibrary
        }

    }

    #Move VM to Content Library
    if (!$library_ID) {
        write-host -ForegroundColor red "$LibraryName does not exist"
    }
    else {
        $ContentLibraryOvfService = Get-CisService com.vmware.vcenter.ovf.library_item
        $UniqueChangeId = [guid]::NewGuid().tostring()

        $createOvfTarget = $ContentLibraryOvfService.Help.create.target.Create()
        $createOvfTarget.library_id = $library_ID

        $createOvfSource = $ContentLibraryOvfService.Help.create.source.Create()
        $createOvfSource.type = ((Get-VM $VMname).ExtensionData.MoRef).Type
        $createOvfSource.id = ((Get-VM $VMname).ExtensionData.MoRef).Value

        $createOvfCreateSpec = $ContentLibraryOvfService.help.create.create_spec.Create()
        $createOvfCreateSpec.name = $LibItemName
        $createOvfCreateSpec.description = $Description

        Add-LogEntry "Creating Library Item $LibItemName"
        $libraryTemplateId = $ContentLibraryOvfService.create($UniqueChangeId, $createOvfSource, $createOvfTarget, $createOvfCreateSpec)
    }

    $TemplateLibraryStatus
}