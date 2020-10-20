function Rename-Log {

    <#
        .SYNOPSIS
            Renames the current log


        .DESCRIPTION
            Renames the current log


        .PARAMETER VMName
            The new name to use for the VMName portion of the log name


        .PARAMETER OS
            The new name to use for the OS portion of the log name


        .PARAMETER Name
            The new name ot use at the beginning of the log name


        .Example
            Rename-Log -VMName 'TestVm2'

            Starting Log Name:
                orchestrate_xyz_Linux_20180227_104200AM.log

            New Log Name:
                orchestrate_TestVm2_Linux_20180227_104200AM.log

            Inside the log file, it also records that a change was made
                20180227_104302AM ----- Renaming Log
                20180227_104302AM ----- Current Log File Path: C:\DeploymentLogs\orchestrate\orchestrate_xyz_Linux_20180227_104200AM.log
                20180227_104302AM ----- Current Log File Name: orchestrate_xyz_Linux_20180227_104200AM
                20180227_104302AM ----- New Log File Path: C:\DeploymentLogs\orchestrate\orchestrate_TestVm2_Linux_20180227_104200AM.log
                20180227_104302AM ----- New Log File Name: orchestrate_TestVm2_Linux_20180227_104200AM


        .Example
            Rename-Log -OS 'Windows'

            Starting Log Name:
                orchestrate_TestVm2_Linux_20180227_104200AM.log

            New Log Name:
                orchestrate_TestVm2_Windows_20180227_104200AM.log

            Inside the log file, it also records that a change was made
                20180227_104516AM ----- Renaming Log
                20180227_104516AM ----- Current Log File Path: C:\DeploymentLogs\orchestrate\orchestrate_TestVm2_Linux_20180227_104200AM.log
                20180227_104516AM ----- Current Log File Name: orchestrate_TestVm2_Linux_20180227_104200AM
                20180227_104516AM ----- New Log File Path: C:\DeploymentLogs\orchestrate\orchestrate_TestVm2_Windows_20180227_104200AM.log
                20180227_104516AM ----- New Log File Name: orchestrate_TestVm2_Windows_20180227_104200AM

    #>


    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
        [String]$VMName,

        [Parameter(Mandatory = $false)]
        [String]$OS,

        [Parameter(Mandatory = $false)]
        [String]$Name
    )


    if (!([String]::IsNullOrEmpty($VMName)) -or !([String]::IsNullOrEmpty($Name)) -or !([String]::IsNullOrEmpty($OS))) {

        if ((Test-Log) -eq "Pass") {

            $Log = Get-Log

            Add-LogEntry "Renaming Log"
            Add-LogEntry "Current Log File Path: $($Log.FullName)"
            Add-LogEntry "Current Log File Name: $($Log.BaseName)"


            $CurrentBaseName = $($Log.BaseName)
            [System.Collections.ArrayList]$NameSplit = $CurrentBaseName.split("_")

            if (!([String]::IsNullOrEmpty($Name))) {

                $NameSplit[0] = $Name
            }

            if (!([String]::IsNullOrEmpty($VMName))) {

                $NameSplit[1] = $VMName
            }

            if (!([String]::IsNullOrEmpty($OS))) {

                $NameSplit[2] = $OS
            }

            $NewBaseName = $NameSplit -join ("_")
            $NewName = $NewBaseName + ".log"

            $RenamedItem = $Log | Rename-Item -NewName $NewName -Force -PassThru -ErrorAction SilentlyContinue

            if (!([String]::IsNullOrEmpty($RenamedItem))) {

                $Script:LogFilePath = $RenamedItem.FullName

                $Log = Get-Log

                Add-LogEntry "New Log File Path: $($Log.FullName)"
                Add-LogEntry "New Log File Name: $($Log.BaseName)"

                $ExitCode = 0
            }
            else {

                $Message = "Error - File already exists with the new name"
                Write-Verbose -Message "Error - File already exists with the new name"

                $ExitCode = 1
                $ExitError = $Message
            }
        }
        else {

            $Message = "Log NOT found"
            Write-Error -Message $Message

            $ExitCode = 1
            $ExitError = $Message
        }
    }
    else {

        $Message = "Need to provide at least one parameter"
        Write-Error -Message $Message

        $ExitCode = 1
        $ExitError = $Message
    }


    $ReturnObject = [PSCustomObject] @{
        ExitCode  = $ExitCode
        ExitError = $ExitError
    }

    $ReturnObject
}
