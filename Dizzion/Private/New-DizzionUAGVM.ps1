<#
    .SYNOPSIS
    Deploys the initial UAG VM to convert into a template in the content library

    .DESCRIPTION
    The purpose of this function is to Deploy a VM that will be converted to a template in the Content Library with the options specified.

    .NOTES
    Author: Kevin McClure

    .PARAMETER Source
    The source of the OVA to deploy the VM from

    .PARAMETER VMName
    The name of the target VM to deploy.

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



    .EXAMPLE
    Set-PrincipalDuplicate -vCenter vcenter.contoso.com -InputDomain Contoso -TargetDomain TestDomain
#>
function New-DizzionUAGVM () {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$OVASource,

        [Parameter(Mandatory = $true)]
        [string]$VMName,

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
        [string]$ThreeNICMappingBackend


    )

    try {
        #Import the OVA Config from the OVA provided




        Add-LogEntry "Importing Config Values from OVA Path $OVASource"
        $ovaconfig = Get-OvfConfiguration -OvF $OVASource



        if ($OVAIP) {
            Add-LogEntry "Set the IP value for common.IP0 to $OVAIP"
            $ovaconfig.common.ipMode0.value = "STATICV4"
            $ovaconfig.common.ip0.value = $OVAIP
        }
        else {
            $ovaconfig.common.ipMode0.value = "DHCPV4"
        }


        Add-LogEntry "Set the netmask value for common.netmask to $OVANetmask"
        $ovaconfig.common.netmask0.value = $OVANetMask

        Add-LogEntry "Set the gateway value for common.gateway to $OVAGateway"
        $ovaconfig.common.defaultGateway.value = $OVAGateway

        Add-LogEntry "Set the UAG Name value for common.uagname to $UAGName"
        $ovaconfig.common.uagName.value = $UAGName

        Add-LogEntry "Set the value of CEIP for common.ceipEnabled to $CEIPEnabled"
        $ovaconfig.common.ceipEnabled.value = $CEIPEnabled

        Add-LogEntry "Set the root password value"
        $ovaconfig.common.rootPassword.value = $RootPassword

        Add-LogEntry "Set the admin password value"
        $ovaconfig.common.adminPassword.value = $AdminPassword

        Add-LogEntry "Set the value of SSH for common.sshEnabled to $SSHEnabled"
        $ovaconfig.common.sshEnabled.value = $SSHEnabled

        Add-LogEntry "Set the Deployment Option for deploymentoption to $DeploymentOption"
        $ovaconfig.DeploymentOption.value = $DeploymentOption

        if ($DeploymentOption -eq "onenic"){
            Add-LogEntry "Setting OneNic NetworkMappings to $oneNicMappingAll"
            $ovaconfig.NetworkMapping.Internet.value = $OneNICMappingAll
            $ovaconfig.NetworkMapping.ManagementNetwork.value = $OneNICMappingAll
            $ovaconfig.NetworkMapping.BackendNetwork.value = $OneNICMappingAll
        }
        elseif ($DeploymentOption -eq "twonic"){
            Add-LogEntry "Setting TwoNic Internet NetworkMapping to $TwoNicMappingInternet"
            $ovaconfig.NetworkMapping.Internet.value = $TwoNICMappingInternet

            Add-LogEntry "Setting TwoNic Management/Backend NetworkMapping to $TwoNicMappingManagement"
            $ovaconfig.NetworkMapping.ManagementNetwork.value = $TwoNICMappingManagement
            $ovaconfig.NetworkMapping.BackendNetwork.value = $TwoNICMappingManagement
        }

        elseif ($DeploymentOption -eq "threenic"){
            Add-LogEntry "Setting ThreeNic Internet NetworkMapping to $ThreeNicMappingInternet"
            $ovaconfig.NetworkMapping.Internet.Value = $ThreeNICMappingInternet

            Add-LogEntry "Setting ThreeNic Management NetworkMapping to $ThreeNicMappingManagement"
            $ovaconfig.NetworkMapping.ManagementNetwork.Value = $ThreeNICMappingManagement

            Add-LogEntry "Setting ThreeNIC Backend NetworkMapping to $ThreeNicMappingBackend"
            $ovaconfig.NetworkMapping.BackendNetwork.Value = $ThreeNICMappingBackend
        }

        Add-LogEntry "Setting VMhost automatically"
        $VMHost = Get-Cluster $Cluster | Get-VMHost | Sort-Object MemoryGB | Select-Object -first 1
        Add-LogEntry "VMHost $($VMHost.Name) will be used for deployment"


        $OVACluster = Get-Cluster $Cluster
        $OVADataStore = Get-Cluster $cluster | Get-Datastore $Datastore

        Add-Logentry "Deploying OVA with provided options"

        Import-vApp -Source $OVASource -OvfConfiguration $ovaconfig -Name $VMName -VMHost $VMHost -Location $OVACluster -Datastore $OVADatastore -DiskStorageFormat "Thin" -Verbose -Confirm:$false

        $TemplateOVADeploy = "SUCCEEDED"
        $TemplateOVAStatus = New-Object PSObject -Property @{
            DeployStatus = $TemplateOVADeploy
        }
    }



    catch {
        $CaughtException = $_
        $TemplateOVADeploy = "FAILED"
        Add-LogEntry $CaughtException
        Add-LogEntry 'Error deploying template OVA'
        $TemplateOVAStatus = New-Object PSObject -Property @{
            DeployStatus = $TemplateOVADeploy
        }
    }

    $TemplateOVAStatus

}
