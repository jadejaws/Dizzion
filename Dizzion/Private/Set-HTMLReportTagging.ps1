<#
.SYNOPSIS
Formats a html file with color code tagging from an array input
.DESCRIPTION
The purpose of this script is to format HTML from an input array.
.NOTES
Author: Kevin McClure
.PARAMETER EmailInput
Input of the email report.
.PARAMETER TotalsInput
Add Totals to the bottom of html report
.PARAMETER HTMLOutput
The name of the html file to export.
.EXAMPLE
Set-HTMLReportTagging -EmailInput $Array -HTMLOutput $HTMLOutput
#>

Function Set-HTMLReportTagging () {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)]
        [array]$EmailInput,
        [Parameter(Mandatory = $false)]
        [array]$TotalsInput,
        [Parameter(Mandatory = $True)]
        [string]$HTMLOutput
    )

    #Define Style of HTML Output
    $Style = @"
<title></title>
<h1></h1>
<style>
body { background-color:#FFFFFF;
font-family:Arial;
font-size:10pt; }
td, th { border:1px solid black;
border-collapse:collapse; }
th { color:black;
background-color:#8DB4E2; }
th {
    background: #8DB4E2;
    position: sticky;
    top: 0;
    box-shadow: 0 4px 4px 1px rgba(0, 0, 0, 0.4);
  }
table, tr, td, th { padding: 2px; margin: 0px }
table { width:100%;margin-left:5px; margin-bottom:20px;}
.yellownotice {background: #FFC300; font-weight: bold;}
.redwarning {background: #D43537; font-weight: bold;}
.greennormal {background: #46D33D;}
.bad {color: Red ; back-ground-color: Red}
.good {color: #207E19 }
.warning {color: #F3DC1B }
.critical {color: #F3351B}
.notice {color: #F3DC1B }
.other {color: #000000 }
</style>
<br>
"@
    #tr:nth-child(odd) {background-color:#d3d3d3;}
    #tr:nth-child(even) {background-color:white;}
    Set-Location -Path $PSScriptRoot
    Set-Location -Path ..\Output
    $outloc = Get-Location
    $HTMLFile = "$outloc\$HTMLOutput"
    New-Item $HTMLFile -type file -force | out-null
    $script:html = @()
    [xml]$script:html = $EmailInput | Select-Object vCenterName, LibraryCreation, ContentLibraryName, ContentLibraryDatastore, TemplateDeployed, LibraryTransferStatus, VMDeployStatus | ConvertTo-Html -Fragment

    #Each of these foreach statments loops through a specific column and sets the class tag for color coding.
    1..($script:html.table.tr.count - 1) | ForEach-Object {
        $td = $script:html.table.tr[$_]
        $class = $script:html.CreateAttribute("class")

        #set the class value based on the item value of Library Creation
        Switch ($td.childnodes.item(1).'#text') {
            "SUCCEEDED" { $class.value = "good" }
            "FAILED" { $class.value = "bad" }
            Default { $class.value = "other" }
        }
        $td.childnodes.item(1).attributes.append($class) | Out-Null
    }#end foreach for table


    1..($script:html.table.tr.count - 1) | ForEach-Object {
        $td = $script:html.table.tr[$_]
        $class = $script:html.CreateAttribute("class")

        #set the class value based on the item value of Template Deployment
        Switch ($td.childnodes.item(4).'#text') {
            "SUCCEEDED" { $class.value = "good" }
            "FAILED" { $class.value = "bad" }
            Default { $class.value = "other" }
        }
        $td.childnodes.item(4).attributes.append($class) | Out-Null
    }#end foreach for table

    1..($script:html.table.tr.count - 1) | ForEach-Object {
        $td = $script:html.table.tr[$_]
        $class = $script:html.CreateAttribute("class")

        #set the class value based on the item value of Library Transfer Status
        Switch ($td.childnodes.item(5).'#text') {
            "SUCCEEDED" { $class.value = "good" }
            "FAILED" { $class.value = "bad" }
            Default { $class.value = "other" }
        }
        $td.childnodes.item(5).attributes.append($class) | Out-Null
    }#end foreach for table

    1..($script:html.table.tr.count - 1) | ForEach-Object {
        $td = $script:html.table.tr[$_]
        $class = $script:html.CreateAttribute("class")

        #set the class value based on the item value of VM Deploy Status
        Switch ($td.childnodes.item(6).'#text') {
            "SUCCEEDED" { $class.value = "good" }
            "FAILED" { $class.value = "bad" }
            "UNKNOWN" { $class.value = "bad" }
            Default { $class.value = "other" }
        }
        $td.childnodes.item(6).attributes.append($class) | Out-Null
    }#end foreach for table


    $UniquevCenters = @()
    #Gather table of unique vCenters
    1..($script:html.table.tr.count - 1) | ForEach-Object {
        $vcenter = $script:html.table.tr[$_].td[0]
        $UniquevCenters += $vcenter
    }



    #Output CSS formatted HTML with tags for columns
    ConvertTo-HTML -Head $style -Body $script:html.InnerXml | Out-file $HTMLOutput -Append
    if ($TotalsInput){
        $script:html2 = @()
    [xml]$script:html2 = $TotalsInput | Select-Object   | ConvertTo-Html -Fragment
    ConvertTo-HTML -Head $style -Body $script:html2.InnerXml | Out-file $HTMLOutput -Append
    }

}
