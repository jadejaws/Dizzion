function New-Log {

    <#
        .SYNOPSIS
            Creates a new log file


        .DESCRIPTION
            Creates a new log file
            Uses the following format for the file name
                <calling script name/custom name> _ <vmname> _ <OS> _ <date> _  <time> .log
            The underscores are kept, even if vmname and OS aren't provided, it's setup this way to make it easier
            to parse for the Rename-Log function


        .PARAMETER FileName
            The name to be used for the log
            if this is not provided, it will be set to the name of the calling script


        .PARAMETER FolderPath
            The folder path to where the log will be saved. The folder will be created, if it does not already exist.
            if this is not provided, it will be stored in C:\DeploymentLogs


        .PARAMETER VMName
            Name of the VM, this is used to modify the name of the log file
            Example:
                New-Log -VMName 'vm-test-01'

                ..\<script_name>_vm-test-01_<date_time>.log


        .PARAMETER OS
            Name of the OS, this is used to modify the name of the log file
            Example:
                New-Log -OS 'Windows'

                ..\<script_name>_Windows_<date_time>.log


        .Example
            New-Log -VMName 'vm-test-02' -OS 'Linux'

            In a script named, "Orchestrate.ps1", the above command is run

            This is the file that will be created:
            C:\DeploymentLogs\Orchestrate\Orchestrate_vm-test-02_Linux_<date-time>.log


        .Example
            New-Log -VMName 'vm-test-03' -OS 'Windows' -FileName 'CustomName-5'

            In a script named, "VMWare.ps1", the above command is run

            This is the file that will be created:
            C:\DeploymentLogs\VMWare\CustomName-5_vm-test-03_Linux_<date-time>.log


        .Example
            New-Log -VMName 'vm-test-04' -OS 'Windows' -FolderPath "C:\Temp"

            In a script, named "Windows.ps1", the above command is run

            This is the file that will be created:
            C:\Temp\Windows_vm-test-04_Windows_<date-time>.log

    #>


    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
        [String]$FileName,

        [Parameter(Mandatory = $false)]
        [String]$FolderPath,

        [Parameter(Mandatory = $false)]
        [String]$VMName,

        [Parameter(Mandatory = $false)]
        [String]$OS,

        [Parameter(Mandatory = $false)]
        [Switch]$Force
    )


    # if force is NOT true, then test to see if a log already exists
    if ($Force -ne $true) {

        $TestResult = Test-Log

        if ($TestResult -eq 'Pass') {

            Write-Warning -Message 'Log already exists, use Force parameter'

            $ReturnObject = [PSCustomObject] @{
                ExitCode  = 0
                ExitError = ''
            }

            # used return here to exit this function, without stopping the execution of the calling script
            return $ReturnObject
        }
    }


    # Determine name of the calling script
    try {

        $CallingScriptFullName = $MyInvocation.PSCommandPath.Split("\")[-1]
        $CallingScriptBaseName = $CallingScriptFullName.Split(".")[0]
    }
    catch {

        $CallingScriptBaseName = "NoFileName"
    }


    # Set FileName, if not provided, to the name of the script that called it
    if ([String]::IsNullOrEmpty($FileName)) {

        $FileName = $CallingScriptBaseName
    }


    # Set FolderPath, if not provided, to a hardcoded "default" value
    if ([String]::IsNullOrEmpty($FolderPath)) {

        $Script:LogFolderPath = "C:\ServiceNow\EquinixVMDeployment\Logs\$FileName"
    }
    else {

        $Script:LogFolderPath = $FolderPath
    }


    # Build LogFileName
    $DateTimeString = (Get-Date).ToString("yyyyMMdd_hhmmsstt")
    $LogFileName = $FileName + "_"

    if (!([String]::IsNullOrEmpty($VMName))) {

        $LogFileName = $LogFileName + $VMName + "_"
    }
    else {

        $LogFileName = $LogFileName + "" + "_"
    }

    if (!([String]::IsNullOrEmpty($OS))) {

        $LogFileName = $LogFileName + $OS + "_"
    }
    else {

        $LogFileName = $LogFileName + "" + "_"
    }

    $LogFileName = $LogFileName + $DateTimeString + ".log"


    $ExitCode = 0
    $ExitError = ''

    # Create the Log folder, if it doesn't already exist
    try {

        if (!(Test-Path -Path $Script:LogFolderPath)) {

            New-Item -Path $Script:LogFolderPath -ItemType Directory -Force | Out-Null
        }
    }
    catch {

        $ExitError = 'Error while creating the log folder'
        Write-Warning -Message $ExitError

        $ExitCode = 1
    }


    # Create the log file
    try {

        $Script:LogFilePath = "$Script:LogFolderPath\$LogFileName"
        New-Item -Path $Script:LogFilePath -ItemType File -Force | Out-Null
    }
    catch {

        $ExitError += 'Error while creating the log file'
        Write-Warning -Message $ExitError

        $ExitCode = 1
    }

    Add-LogEntry "Script Name: $CallingScriptFullName", ""


    $ReturnObject = [PSCustomObject] @{
        ExitCode  = $ExitCode
        ExitError = $ExitError
    }

    $ReturnObject
}
