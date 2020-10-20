function Add-LogEntry {

    <#
        .SYNOPSIS
            Adds entry into the log and displays a verbose message


        .DESCRIPTION
            Adds entry into the log and displays a verbose message


        .PARAMETER LogEntry
            Contains the information to be added to the log


        .Example
            Add-LogEntry -LogEntry "Starting Get-ProcessList Function", ""
            Add-LogEntry -LogEntry "Gathering Processes"

            This will now be in the log:
                20180226_094941AM ----- Starting Get-ProcessList Function
                20180226_094941AM -----
                20180226_094941AM ----- Gathering Processes

            The purpose of this example is show that you can insert blank lines, by using an empty string


        .Example
            Get-Process | Select-Object -First 5 | Add-LogEntry

            This will now be in the log:
                20180227_071503AM ----- System.Diagnostics.Process (ApMsgFwd)
                20180227_071503AM ----- System.Diagnostics.Process (ApntEx)
                20180227_071503AM ----- System.Diagnostics.Process (Apoint)
                20180227_071503AM ----- System.Diagnostics.Process (armsvc)
                20180227_071503AM ----- System.Diagnostics.Process (atieclxx)

            The purpose of this example is to show that the command accepts pipline input

            If you want more details in the output, then see the example below


        .Example
            Get-Process | Sort-Object -Property CPU -Descending |Select-Object -Property ProcessName, CPU -First 5 | Out-String | Add-LogEntry

            This will now be in the log:
                20180227_071647AM -----
                ProcessName               CPU
                -----------               ---
                powershell_ise     125.765625
                OUTLOOK             89.453125
                ipoint              78.640625
                ApMsgFwd             45.34375
                QtWebEngineProcess    31.1875

            The purpose of this example is to show that more detailed output can achieved, but you need to format it properly first


        .Example
            Add-LogEntry "Starting Get-ProcessList Function", "" -Verbose
            Add-LogEntry "Gathering Processes" -Verbose

            This will appear in the console:
                VERBOSE: Starting Get-ProcessList Function
                VERBOSE:
                VERBOSE: Gathering Processes

            This will now be in the log:
                20180226_094941AM ----- Starting Get-ProcessList Function
                20180226_094941AM -----
                20180226_094941AM ----- Gathering Processes

            The purpose of this example is to show that it accepts a positional parameter and that if you use the verbose option, it will
            show the messages on screen in addition to logging them.

    #>


    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [AllowNull()]
        [string[]]$LogEntry
    )


    begin {

        $DateTimeString = (Get-Date).ToString("yyyyMMdd_hhmmsstt")
    }

    process {

        foreach ($Line in $LogEntry) {

            Out-File -FilePath $Script:LogFilePath -InputObject "$DateTimeString ----- $Line"  -Append -NoClobber

            Write-Verbose -Message $Line -Verbose
        }
    }
}
