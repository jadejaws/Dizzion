<#
    .SYNOPSIS
    Starts a Dizzion deploy from the list of available optoins

    .DESCRIPTION
    The purpose of this script is to deploy a UAC appliance using provided Demo materials

    .NOTES
    Author: Kevin McClure

   .PARAMETER Source
    The source of the OVA to deploy the VM from

    .PARAMETER VMName
    The name of the target VM to deploy.

    .PARAMETER TemplateName
    The name of the Template to deploy

    .PARAMETER Cluster
    Target Cluster to deploy to.

    .PARAMETER Datastore
    Target Datastore to deploy to.

    .PARAMETER OVAIP
    The IP Address to set in the OVA Options. Optional parameter for DHCP deployments.

    .PARAMETER OVANETMASK
    The Subnet Mask to set in the OVA Options.

    .PARAMETER OVAGATEWAY
    The Gateway to set in the OVA Options.

    .PARAMETER UAGNAME
    The name of the UAG in the OVA Options.

    .PARAMETER CEIPEnabled
    True or False Value to enable CEIP in the OVA.

    .PARAMETER RootPassword
    The Root Password to set in the OVA options

    .PARAMETER AdminPassword
    The Admin Password to set in the OVA options.

    .PARAMETER CEIPEnabled
    True or False Value to enable SSH in the OVA.

    .PARAMETER DeploymentOption
    OneNic, TwoNic, or ThreeNIc configuration to set in the OVA. There are many more options available in the OVA, but for the purpose of this exercise we are limiting this to these 3.

    .PARAMETER OneNicMappingAll
    The VD Portgroup to map the interfaces to in a One NIC config

    .PARAMETER TwoNicMappingInternet
    The VD Portgroup to map the Internet interface to in a Two NIC config

    .PARAMETER TwoNicMappingManagement
    The VD Portgroup to map the Management and Backend interfaces to in a Two NIC config

    .PARAMETER vCredential
    The credential to use to authenticate to target vCenter


    .PARAMETER LogFolderPath
    The log folder to store the log in

    .PARAMETER LogFileName
    The log file name to use

    .EXAMPLE
    Start-vCenterAudit -InputArray $vCenterList -MGMTCredential $MGMTCredential -AltCredential $AltCredential -SecondAltCredential $SecondAltCredential `
    -ThirdAltCredential $ThirdAltCredential -OtherCredential $OtherCredential -Report -SMTPServer "mail.contoso.com" -DeliveryAddress "Report@contoso.com" -SenderAddress "Report@contoso.com" -Verbose

#>

function Start-DizzionUAGDeploy () {
    [CmdletBinding()]


    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$vCenter,

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $vCredential,

        [Parameter(Mandatory = $true)]
        [string]$OVASource,

        [Parameter(Mandatory = $true)]
        [string]$VMName,

        [Parameter(Mandatory = $true)]
        [string]$Location,

        [Parameter(Mandatory = $true)]
        [string]$Cluster,

        [Parameter(Mandatory = $true)]
        [string]$Datastore,

        [Parameter(Mandatory = $false)]
        [string]$OVAIP,

        [Parameter(Mandatory = $true)]
        [string]$OVANetMask,

        [Parameter(Mandatory = $true)]
        [string]$OVAGateway,

        [Parameter(Mandatory = $true)]
        [string]$UAGName,

        [Parameter(Mandatory = $true)]
        [switch]$CEIPEnabled,

        [Parameter(Mandatory = $true)]
        [string]$RootPassword,

        [Parameter(Mandatory = $true)]
        [string]$AdminPassword,

        [Parameter(Mandatory = $true)]
        [switch]$SSHEnabled,

        [Parameter(Mandatory = $true)]
        [ValidateSet("onenic", "twonic", "threenic")]
        [string]$DeploymentOption,

        [Parameter(Mandatory = $false)]
        [string]$OneNICMappingAll,

        [Parameter(Mandatory = $false)]
        [string]$TwoNICMappingInternet,

        [Parameter(Mandatory = $false)]
        [string]$TwoNICMappingManagement,

        [Parameter(Mandatory = $false)]
        [string]$ThreeNICMappingInternet,

        [Parameter(Mandatory = $false)]
        [string]$ThreeNICMappingManagement,

        [Parameter(Mandatory = $false)]
        [string]$ThreeNICMappingBackend,

        [Parameter(Mandatory = $false)]
        [string]$LogFolderPath = 'C:\Temp',

        [Parameter(Mandatory = $false)]
        [string]$LogFileName = 'Start-DizzionUAGDeploy.log'

    )

    #Set-Variables
    $curloc = Get-Location
    Set-Location -Path $PSScriptRoot
    Set-Location -Path ..\Output
    $StartTimer = (Get-Date)
    $Subject = "DizzionUAGDeploy"
    $outloc = Get-Location

    #Import-Modules and Start Log
    Import-Module PSExcel
    New-Log -FileName $LogFileName -FolderPath $LogFolderPath

    #Create empty array for report
    $VCReport = @()

    #Create the Content Library
    Add-LogEntry "Starting Creation of Library on $Datastore"
    $LibraryCreation = New-DizzionContentLibrary -Datastore $Datastore


    #Create the TemplateVM from OVA
    Add-LogEntry "Starting Template OVA Deploy"
    $TemplateVMName = "Unified Access Gateway 3.7" #Would be parameter with more time

    #Build Splat with mandatory parameters for New-DizzionUAGVM
    $StartDizzionsplat = @{
        Verbose         = $true
        OVASource       = $OVASource
        VMName          = $TemplateVMName
        Cluster         = $Cluster
        Datastore       = $Datastore
        OVAIP           = $OVAIP
        OVANETMASK      = $OVANetMask
        OVAGATEWAY      = $OVAGateway
        UAGNAME         = $VMName
        CEIPEnabled     = $CEIPEnabled
        RootPassword    = $RootPassword
        AdminPassword   = $AdminPassword
        SSHEnabled      = $SSHEnabled
    }

    #Determine Deployment Option and add to splat accordingly
    if ($DeploymentOption -eq "OneNic"){
        Add-LogEntry "Setting OneNic Splat options"
        $StartDizzionsplat.DeploymentOption = "onenic"
        $StartDizzionsplat.OneNicMappingAll = $OneNICMappingAll
    }
    elseif ($DeploymentOption -eq "TwoNic"){
        Add-LogEntry "Setting TwoNic Splat options"
        $StartDizzionsplat.DeploymentOption = "twonic"
        $StartDizzionsplat.TwoNicMappingInternet = $TwoNICMappingInternet
        $StartDizzionsplat.TwoNicMappingManagement = $TwoNICMappingManagement
    }

    elseif ($DeploymentOption -eq "ThreeNic"){
        Add-LogEntry "Setting ThreeNic Splat options"
        $StartDizzionsplat.DeploymentOption = "threenic"
        $StartDizzionsplat.ThreeNicMappingInternet = $ThreeNICMappingInternet
        $StartDizzionsplat.ThreeNicMappingManagement = $ThreeNICMappingManagement
        $StartDizzionsplat.ThreeNICMappingBackend = $ThreeNICMappingBackend
    }


    Add-LogEntry "Calling Deploy OVA to Template VM"
    $TemplateDeployed = New-DizzionUAGVM @StartDizzionsplat

    #Connect to CIS Service for API calls --- would be a try catch in another function in final product
    Add-LogEntry "Connecting to CIS Server $VCenter"
    Connect-CISServer -Server $vCenter -Credential $vCredential



    #Copy Template VM to Content Library
    $LibaryName = $LibraryCreation.ContentLibraryName
    $LibraryItemName = $TemplateVMName + " Template"

    $LibraryTransferStatus = Add-DizzionTemplateToLibrary -LibraryName $LibaryName -VMname $TemplateVMName -LibItemName $LibraryItemName -Description '3.7 UAG'

    #Sleep for now and wait for the operations to complete with transfer to library. Final product would query the task status and wait to start next operations when completed.
    Start-Sleep -Seconds 600

    #Deploy VM from Content Library
    $VMDeploy = New-DizzionUAG -ContentLibraryItem $LibraryItemName -VMName $VMName -Location $Location -Datastore $Datastore -ResourcePool $Cluster



    $obj = @()
    $obj = " " | Select-Object vCenterName, LibraryCreation, ContentLibraryName, ContentLibraryDatastore, TemplateDeployed, LibraryTransferStatus, VMDeployStatus
    $obj.vCenterName = $vCenter
    $obj.LibraryCreation = $LibraryCreation.Status
    $obj.ContentLibraryName = $LibraryCreation.ContentLibraryName
    $obj.ContentLibraryDatastore = $Datastore
    $obj.TemplateDeployed = $TemplateDeployed.DeployStatus
    $obj.LibraryTransferStatus = $LibraryTransferStatus.TemplatetoLibraryStatus
    $obj.VMDeployStatus = $VMDeploy.Status
    $VCReport += $obj


    #Cleanup unnecessary VM
    #Remove-VM $TemplateVMName -DeletePermanently -Confirm:$false

    #Close open Connections
    Disconnect-VIServer * -Confirm:$False | Out-Null
    #Disconnect-CIServer  -Confirm:$false | Out-Null



    #Set static variables for mail delivery. These would be additional parameters if more time was allowed.
    $DeliveryAddress = "Kevin@Jadejaws.org"
    $SenderAddress = "DizzionReport@jadejaws.org"
    $smtpServer = "mail.jadejaws.org"

    #Output report
    $ReportDate = (Get-Date).ToString("MM-dd-yyyy")
    $XLSOut = $Subject + "-" + $ReportDate + ".xlsx"
    $VCReport | Export-XLSX -Table -Autofit -Force -Path "$outloc\$XLSOut"

    $HTMLOutput = $Subject + "-" + $ReportDate + ".htm"
    $message = New-Object System.Net.Mail.MailMessage $SenderAddress, $DeliveryAddress
    $message.Subject = "$Subject"
    $message.IsBodyHTML = $true #force html

    Set-HTMLReportTagging -EmailInput $VCReport -HTMLOutput $HTMLOutput -TotalsInput $Totals

    #Attach files to email
    $attachment = "$outloc\$HTMLOutput"
    $attach = new-object Net.Mail.Attachment($attachment)

    $attachment2 = "$outloc\$XLSOut"
    $attach2 = new-object Net.Mail.Attachment($attachment2)

    $message.Attachments.Add($attach)
    $message.Attachments.Add($attach2)

    #Insert Total Run Time into html email
    $EndTimer = (Get-Date)
    $message.Body += Get-Content $outloc\$HTMLOutput
    $message.Body += "

    Script Process Time: $(($EndTimer-$StartTimer).totalseconds) seconds"

    #Send
    Add-LogEntry "Sending email to $DeliveryAddress"
    $smtp = New-Object Net.Mail.SmtpClient($smtpServer)
    $smtp.Send($message)

    #Destroy attachments
    $attach.Dispose()
    $attach2.Dispose()

    #Remove files in output directory
    Remove-Item $outloc\$HTMLOutput -recurse
    Remove-Item $outloc\$XLSOut -Recurse

    #Output script time to host
    Add-LogEntry "Elapsed Script Time: $(($EndTimer-$StartTimer).totalseconds) seconds"

    #Restore Previous working directory
    Set-Location $curloc



}
