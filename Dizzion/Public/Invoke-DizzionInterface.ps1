<#
    .SYNOPSIS
    Invokes a text based user interface to enter the necessary values for deploying the UAG OVA.

    .DESCRIPTION
    The purpose of this function is to present and save to variables all aspects of the Dizzion OVA deployment.

    .NOTES
    Author: Kevin McClure

    .PARAMETER LogFolderPath
    The log folder to store the log in

    .PARAMETER LogFileName
    The log file name to use

    .EXAMPLE
    Invoke-DizzionInterface

#>

function Invoke-DizzionInterface () {
    [CmdletBinding()]

    param
    (

    )

    #Starting Building Splat for Variables
    $InvokeDizzionSplat = @{
        Verbose         = $true
    }

    Write-Host "**************This program is designed to deploy the EUC Unified Access Gateway from a Content Library*****************" -ForegroundColor Green
    Write-Host "**************Answer the prompts that follow to start the deployment***************************************************" -ForegroundColor Green

    $vCenter = $(Write-Host "Please specify a valid vCenter to connect to: " -ForegroundColor Green -NoNewline; Read-Host)

    Write-Host "Testing basic connectivity to vCenter $vCenter" -ForegroundColor Gray
    $TestConnect = Test-NetConnection $vCenter

    if ($TestConnect.PingSucceeded -eq $true) {
        Write-Host "Ping successful to $vCenter"
        $InvokeDizzionSplat.vCenter = $vCenter
    }
    else {
        Write-Host "You need to enter a valid vCenter" -ForegroundColor Red
        exit
    }

    Write-Host "Please enter valid administrative credentials for vCenter specified"

    try {
        $VICredential = $host.ui.PromptForCredential("Need administrative credentials to vCenter", "Please enter your user name and password.", "", "UPN vCenter Credentials")


    }

    catch {
        $CaughtException = $_
        Write-Host $CaughtException
        Write-Host 'Error saving credentials provided'
    }

    #Verify Authentication to vCenter with Provided credentials
    Write-Host "Attempting Authentication to vCenter with provided credentials" -ForegroundColor Gray

    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false -Scope AllUsers | Out-Null
    $VCConnection = Connect-VIServer -Server $vcenter -Credential $VICredential


    if ($VCConnection) {
        Write-Host "Account successfully authenticated" -ForegroundColor Green
        $InvokeDizzionSplat.vCredential = $VICredential

        #Retrieve and present available clusters
        Write-Host "***List of available clusters to deploy to***" -ForegroundColor Green
        $clusters = Get-Cluster
        $menu = @{ }
        for ($i = 1; $i -le $clusters.count; $i++) {
            Write-Host "$i. $($clusters[$i-1].name)$($clusters[$i-1].status)"
            $menu.Add($i, ($clusters[$i - 1].name))
        }

        [int]$ans = Read-Host 'Enter Cluster selection to deploy to'
        $ClusterSelection = $menu.Item($ans)
        $Cluster = Get-Cluster $ClusterSelection
        $InvokeDizzionSplat.Cluster = $ClusterSelection
        Write-Host "Deployment will occur to the $($Cluster.Name) Cluster" -ForegroundColor Green

        #Retrieve and present available Datastores
        Write-Host "***List of available Datastores to deploy to***" -ForegroundColor Green
        $datastores = Get-Cluster $cluster | Get-Datastore | Where-Object { $_.ExtensionData.Summary.MultipleHostAccess }
        $menu = @{ }
        for ($i = 1; $i -le $datastores.count; $i++) {
            Write-Host "$i. $($datastores[$i-1].name)$($datastores[$i-1].status)"
            $menu.Add($i, ($datastores[$i - 1].name))
        }

        [int]$ans = Read-Host 'Enter Datastore selection to deploy to'
        $DatastoreSelection = $menu.Item($ans)
        $Datastore = Get-Datastore $DatastoreSelection
        $InvokeDizzionSplat.Datastore = $DatastoreSelection
        Write-Host "Deployment will occur to the $($Datastore.Name) Datastore" -ForegroundColor Green

        #Retrieve and present available Locations
        Write-Host "***List of available Folders (Locations) to deploy to***" -ForegroundColor Green
        $locations = Get-Folder | Where-Object { ($_.type -eq "VM") -and ($_.Name -ne "vm") }
        $menu = @{ }
        for ($i = 1; $i -le $locations.count; $i++) {
            Write-Host "$i. $($locations[$i-1].name)$($locations[$i-1].status)"
            $menu.Add($i, ($locations[$i - 1].name))
        }

        [int]$ans = Read-Host 'Enter Folder (Location) selection to deploy to'
        $LocationSelection = $menu.Item($ans)
        $Location = Get-Folder $LocationSelection
        $InvokeDizzionSplat.Location = $LocationSelection
        Write-Host "Deployment will occur to the $($Location.Name) Folder" -ForegroundColor Green


        #Have User select a valid path to deployment OVA
        Write-Host "Please specify a valid path to the euc unified access gateway OVA" -ForegroundColor Green

        #Load the File Browser Windows Form
        Add-Type -AssemblyName System.Windows.Forms
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
            InitialDirectory = 'E:\Dizzion'
            filter           = "OVA File (*.ova)| *.ova"
        }
        $null = $FileBrowser.ShowDialog()
        $OVAPath = $FileBrowser.FileName


        Write-Host "Testing file location provided for presence of valid file and file type" -ForegroundColor Gray
        $OVATestPath = Test-Path $OVAPath -PathType Leaf -Include *.ova
        if ($OVATestPath -eq $true) {
            Write-Host "$OVAPath is a valid filepath, file, and filetype." -ForegroundColor Green
            $InvokeDizzionSplat.OVASource = $OVAPath
        }
        else {
            Write-Host "You need to enter a valid ova file" -ForegroundColor Red

        }

        #Prompt for Appliance Name
        $UACName = $(Write-Host "Please specify a name for the EU Unified Access Gateway Appliance: " -ForegroundColor Green -NoNewline; Read-Host)
        $InvokeDizzionSplat.VMName = $UACName
        $InvokeDizzionSplat.UAGName = $UACName

        #Set template OVAConfig
        $ovaConfig = Get-OvfConfiguration -Ovf $OVAPath


        #Set the type of IP Mode for the Unified Access Gateway
        Write-Host "================ Set the IP Mode of the UA Gateway ================"

        Write-Host "1: STATICV4"
        Write-Host "2: DHCPV4"
        $input = Read-Host "Please make a selection for IP Mode of the UA Gateway"
        switch ($input) {
            '1' {
                $IPModeSelection = 'STATICV4'
            }
            '2' {
                $IPModeSelection = 'DHCPV4'
            }

        }
        Write-Host "OVA will be deployed using the $IPModeSelection IP Mode"
        #This setting has no effect in the demo. All are hardcoded static. This would be set if live.

        #Set the Internet interface address if set to Static
        if ($IPModeSelection -eq "STATICV4") {
            $UACIP = $(Write-Host "STATIC IP Selected. Please Type a valid IPv4 address on target network: " -ForegroundColor Green -NoNewline; Read-Host)
            Write-Host "$UACIP selected as the Static IPv4 Internet interface"
            $InvokeDizzionSplat.OVAIP = $UACIP

        }
        else {
            Write-Host "DHCP Address will be assigned to Internet interface"
        }

        #Set the Subnet Mask on the Internet interface
        #No validation done currently. Would have in final product
        $UACSubnetMask = $(Write-Host "Please Type a valid IPv4 subnet mask on target network: " -ForegroundColor Green -NoNewline; Read-Host)
        Write-Host "$UACSubnetMask will be assigned as the subnet mask for the Internet Interface"
        $InvokeDizzionSplat.OVANetmask = $UACSubnetMask

        #Set the Gateway on the Internet interface
        $UACGateway = $(Write-Host "Please Type a valid IPv4 gateway on target network: " -ForegroundColor Green -NoNewline; Read-Host)
        Write-Host "$UACGateway will be assigned as the gateway for the Internet Interface"
        $InvokeDizzionSplat.OVAGateway = $UACGateway

        #Set if CEIP is enabled
        $YesOrNo = Read-Host "Do you want to enabled CEIP (Customer Experience Improvement Program ) (y/n)"
        while ("y", "n" -notcontains $YesOrNo ) {
            $YesOrNo = Read-Host "Do you want to enabled CEIP (Customer Experience Improvement Program ) (y/n)"
        }

        if ($YesOrNo -eq "y") {
            Write-Host "You elected to enable CEIP" -ForegroundColor Green
            $UACCEIPEnable = $true
        }
        else {
            Write-Host "You elected to disable CEIP" -ForegroundColor Green
            $UACCEIPEnable = $false
        }

        $InvokeDizzionSplat.CEIPEnabled = $UACCEIPEnable

        #Set the Root Password
        do {
            $rootpassword = Read-Host -assecurestring "Please enter the root password to the appliance:"
            $rootpasswordconfirm = Read-Host -assecurestring "Please confirm the root password to the appliance:"
            $rootpasswordtext = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($rootpassword))
            $rootpasswordconfirmtext = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($rootpasswordconfirm))
        }
        while ($rootpasswordtext -ne $rootpasswordconfirmtext)
        Write-Host "Root Password confirmed successfully"
        $InvokeDizzionSplat.rootpassword = $rootpasswordtext


        #Set the Admin Password
        do {
            $adminpassword = Read-Host -assecurestring "Please enter the admin password to the appliance:"
            $adminpasswordconfirm = Read-Host -assecurestring "Please confirm the admin password to the appliance:"
            $adminpasswordtext = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminpassword))
            $adminpasswordconfirmtext = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminpasswordconfirm))
        }
        while ($adminpasswordtext -ne $adminpasswordconfirmtext)
        Write-Host "Admin Password confirmed successfully"
        $InvokeDizzionSplat.adminpassword = $adminpasswordtext

        #Set if SSH is enabled
        $YesOrNo2 = Read-Host "Do you want to enable SSH (y/n)"
        while ("y", "n" -notcontains $YesOrNo2 ) {
            $YesOrNo2 = Read-Host "Do you want to enable SSH (y/n)"
        }

        if ($YesOrNo2 -eq "y") {
            Write-Host "You elected to enable SSH" -ForegroundColor Green
            $UACSSHEnable = $true
        }
        else {
            Write-Host "You elected to disable SSH" -ForegroundColor Green
            $UACSSHEnable = $false
        }

        $InvokeDizzionSplat.SSHEnabled = $UACSSHEnable

        #Set the Deployment Option for the Unified Access Gateway
        Write-Host "================ Set the Deployment Option of the UA Gateway ================"

        Write-Host "1: OneNIC (Single vNIC)---Deploy VM configured with 1 vNIC, 2 core and 4 GB RAM. All servers listen on the same network interface."
        Write-Host "2: TwoNIC (Two vNICs)---Deploy VM configured with 2 vNICs, 2 core and 4 GB RAM. The first NIC is Internet facing while the second NIC is used for a management network that hosts the administrative REST API."
        Write-Host "3: ThreeNIC (Three vNICs)---Deploy VM configured with 3 vNICs, 2 core and 4 GB RAM. The first NIC is Internet facing while the second NIC is used for a management network that hosts the administrative REST API. The third `
        NIC is used to route traffic to backend services."
        $input = Read-Host "Please make a selection for Deployment Option of the UA Gateway"
        switch ($input) {
            '1' {
                $DeploymentOption = 'OneNIC'
            }
            '2' {
                $DeploymentOption = 'TwoNIC'
            }
            '3' {
                $DeploymentOption = 'ThreeNIC'
            }

        }
        Write-Host "OVA will be deployed using the $DeploymentOption DeploymentOption"

        #Retrieve and present available VD PortGroups based on Deployment Option
        if ($DeploymentOption -eq "OneNIC") {
            Write-Host "OneNIC Deployment was selected. All interfaces will share a PortGroup. Only 1 portgroup will be selected" -ForegroundColor Green
            $InvokeDizzionSplat.DeploymentOption = "onenic"

            Write-Host "***List of available PortGroups to deploy to***" -ForegroundColor Green
            $Portgroups1Nic = Get-VDPortgroup
            $menu = @{ }
            for ($i = 1; $i -le $Portgroups1Nic.count; $i++) {
                Write-Host "$i. $($Portgroups1Nic[$i-1].name)$($Portgroups1Nic[$i-1].status)"
                $menu.Add($i, ($PortGroups1Nic[$i - 1].name))
            }

            [int]$ans = Read-Host 'Enter PortGroup selection to deploy to'
            $PortGroup1NICSelection = $menu.Item($ans)
            $PortGroup1NIC = Get-VDPortGroup $PortGroup1NICSelection
            Write-Host "Deployment will occur to the $($PortGroup1Nic.Name) PortGroup" -ForegroundColor Green
            $InvokeDizzionSplat.OneNicMappingAll = $PortGroup1NICSelection

        }

        elseif ($DeploymentOption -eq "TwoNIC") {
            Write-Host "TwoNIC Deployment was selected. Internet interface will have one portgroup. Management and backend will have another. Two Port Groups will be selected." -ForegroundColor Green
            $InvokeDizzionSplat.DeploymentOption = "twonic"

            #Select the Internet Interface PortGroup
            Write-Host "***List of available PortGroups to deploy to***" -ForegroundColor Green
            $Portgroups2Nic = Get-VDPortgroup
            $menu = @{ }
            for ($i = 1; $i -le $Portgroups2Nic.count; $i++) {
                Write-Host "$i. $($Portgroups2Nic[$i-1].name)$($Portgroups2Nic[$i-1].status)"
                $menu.Add($i, ($PortGroups2Nic[$i - 1].name))
            }
            [int]$ans = Read-Host 'Enter PortGroup selection to deploy the Internet Interface'
            $PortGroup2NICInternetSelection = $menu.Item($ans)
            $PortGroup2NICInternet = Get-VDPortGroup $PortGroup2NICInternetSelection
            Write-Host "Deployment of Internet interface will occur to the $($PortGroup2NicInternet.Name) PortGroup" -ForegroundColor Green
            $InvokeDizzionSplat.TwoNicMappingInternet = $PortGroup2NICInternetSelection


            #Select the Management/Backend Portgroup
            $Portgroups2NicManage = Get-VDPortgroup | Where-Object { $_.Name -ne $PortGroup2NICInternet.Name }
            $menu = @{ }
            for ($i = 1; $i -le $Portgroups2NicManage.count; $i++) {
                Write-Host "$i. $($Portgroups2NicManage[$i-1].name)$($Portgroups2NicManage[$i-1].status)"
                $menu.Add($i, ($PortGroups2NicManage[$i - 1].name))
            }
            [int]$ans = Read-Host 'Enter PortGroup selection to deploy the Management/Backend Interface'
            $PortGroup2NICManageSelection = $menu.Item($ans)
            $PortGroup2NICManagement = Get-VDPortGroup $PortGroup2NICManageSelection
            Write-Host "Deployment of Management interface will occur to the $($PortGroup2NicManagement.Name) PortGroup" -ForegroundColor Green
            $InvokeDizzionSplat.TwoNicMappingManagement = $PortGroup2NICManageSelection

        }

        elseif ($DeploymentOption -eq "ThreeNIC") {
            Write-Host "ThreeNIC Deployment was selected. Internet interface will have one portgroup. Management will have one portgroup. Backend will have one portgroup. Three portgroups will be selected." -ForegroundColor Green
            $InvokeDizzionSplat.DeploymentOption = "threenic"

            #Select the Internet Interface PortGroup
            Write-Host "***List of available PortGroups to deploy to***" -ForegroundColor Green
            $Portgroups3Nic = Get-VDPortgroup
            $menu = @{ }
            for ($i = 1; $i -le $Portgroups3Nic.count; $i++) {
                Write-Host "$i. $($Portgroups3Nic[$i-1].name)$($Portgroups3Nic[$i-1].status)"
                $menu.Add($i, ($PortGroups3Nic[$i - 1].name))
            }
            [int]$ans = Read-Host 'Enter PortGroup selection to deploy the Internet Interface'
            $PortGroup3NICInternetSelection = $menu.Item($ans)
            $PortGroup3NICInternet = Get-VDPortGroup $PortGroup3NICInternetSelection
            Write-Host "Deployment of Internet interface will occur to the $($PortGroup3NicInternet.Name) PortGroup" -ForegroundColor Green
            $InvokeDizzionSplat.ThreeNicMappingInternet = $PortGroup3NICInternetSelection

            #Select the Management Portgroup
            $Portgroups3NicManage = Get-VDPortgroup | Where-Object { $_.Name -ne $PortGroup3NICInternet.Name }
            $menu = @{ }
            for ($i = 1; $i -le $Portgroups3NicManage.count; $i++) {
                Write-Host "$i. $($Portgroups3NicManage[$i-1].name)$($Portgroups3NicManage[$i-1].status)"
                $menu.Add($i, ($PortGroups3NicManage[$i - 1].name))
            }
            [int]$ans = Read-Host 'Enter PortGroup selection to deploy the Management Interface'
            $PortGroup3NICManageSelection = $menu.Item($ans)
            $PortGroup3NICManagement = Get-VDPortGroup $PortGroup3NICManageSelection
            Write-Host "Deployment of Management interface will occur to the $($PortGroup3NicManagement.Name) PortGroup" -ForegroundColor Green
            $InvokeDizzionSplat.ThreeNicMappingManagement = $PortGroup3NICManageSelection

            #Select the Backend Portgroup
            $Portgroups3NicBackend = Get-VDPortgroup | Where-Object { ($_.Name -ne $PortGroup3NICManagement.Name) -and ($_.Name -ne $PortGroup3NICInternet.Name) }
            $menu = @{ }
            for ($i = 1; $i -le $Portgroups3NicBackend.count; $i++) {
                Write-Host "$i. $($Portgroups3NicBackend[$i-1].name)$($Portgroups3NicBackend[$i-1].status)"
                $menu.Add($i, ($PortGroups3NicBackend[$i - 1].name))
            }
            [int]$ans = Read-Host 'Enter PortGroup selection to deploy the Backend Interface'
            $PortGroup3NICBackendSelection = $menu.Item($ans)
            $PortGroup3NICBackendPG = Get-VDPortGroup $PortGroup3NICBackendSelection
            Write-Host "Deployment of Backend interface will occur to the $($PortGroup3NicBackendPG.Name) PortGroup" -ForegroundColor Green
            $InvokeDizzionSplat.ThreeNicMappingBackend = $PortGroup3NICBackendSelection
        }



    }
    else {
        Write-Host 'Error authenticating with provided credentials.' -ForegroundColor Red
    }

    Write-Host "Starting Start-DizzionUAGDeploy with options specified" -ForegroundColor Green
    try {
        Start-DizzionUAGDeploy @InvokeDizzionSplat
    }
    catch {
        $CaughtException = $_
        Write-Host $CaughtException
        Write-Host 'Error running Start-DizzionUAGDeploy'
    }
}