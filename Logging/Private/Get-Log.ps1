function Get-Log {

    <#
        .SYNOPSIS
            Returns the current log object


        .DESCRIPTION
            Returns the current log object


        .Example
            Get-Log

            This will appear in the console:
                    Directory: C:\DeploymentLogs\orchestrate


                Mode                LastWriteTime         Length Name
                ----                -------------         ------ ----
                -a----        2/27/2018  10:23 AM          10812 orchestrate_xyz_Linux_20180227_102324AM.log

    #>


    [CmdletBinding()]
    Param
    ()

    try {

        $Log = Get-Item -Path $Script:LogFilePath -ErrorAction SilentlyContinue
    }
    catch {

        Write-Verbose -Message 'Unable to get log'
    }

    $Log
}