function Test-Log {

    <#
        .SYNOPSIS
            Returns a pass/fail value back based on if a "current" log exists


        .DESCRIPTION
            Returns a pass/fail value back based on if a "current" log exists
            It calls the Get-Log function and then ensures an object was returned.
            If an object is returned, then it's considered a pass.
            If no object is returned, then it's considered a fail.

        .Example
            Test-Log

            This will appear in the console:
                    Pass

    #>


    [CmdletBinding()]
    [OutputType([string])]
    Param
    ()


    $Log = Get-Log

    if ([String]::IsNullOrEmpty($Log)) {

        $TestResult = "Fail"
    }
    else {

        $TestResult = "Pass"
    }

    $TestResult
}