<#
.SYNOPSIS
Validate a CSV and provision DISABLED lab users. Default is an offline plan.
.EXAMPLE
.\scripts\New-LabUsers.ps1 -CsvPath .\config\users.example.csv
.EXAMPLE
.\scripts\New-LabUsers.ps1 -CsvPath .\config\users.example.csv -Apply -WhatIf
.NOTES
Windows PowerShell 5.1 with RSAT AD module for -Apply. No passwords in CSV or output.
After creation, set a unique password interactively and enable each account separately.
#>
[CmdletBinding(SupportsShouldProcess)]
param([Parameter(Mandatory)][string]$CsvPath, [switch]$Apply)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module "$PSScriptRoot/Lab.Common.psm1" -Force
$rows = @(Read-LabUsers -Path $CsvPath) # Validate entire input before any write.
$base='OU=Staff,OU=Lab,DC=lab,DC=example,DC=test'
if (-not $Apply) {
    $rows | Select-Object SamAccountName,Department,@{n='Action';e={'Plan: create disabled user'}},@{n='Path';e={$base}}
    return
}
Import-Module ActiveDirectory -ErrorAction Stop
if ((Get-ADDomain).DNSRoot -ne 'lab.example.test') { throw 'Refusing to operate outside lab.example.test.' }
$null = Get-ADOrganizationalUnit -Identity $base
# Preflight every dependency before creating accounts.
foreach ($dept in @($rows.Department | Sort-Object -Unique)) { $null=Get-ADGroup -Identity "GG_$dept" }
$failures=0
foreach ($row in $rows) {
    $sam=$row.SamAccountName
    try {
        $existing=@(Get-ADUser -Filter "SamAccountName -eq '$sam'")
        if ($existing.Count) { [pscustomobject]@{Account=$sam;Result='SkippedExisting';Detail='No account or group changes'}; continue }
        if ($PSCmdlet.ShouldProcess($sam,'Create disabled user and add department group')) {
            $user=New-ADUser -Name $sam -GivenName $row.GivenName -Surname $row.Surname -DisplayName "$($row.GivenName) $($row.Surname)" -SamAccountName $sam -UserPrincipalName "$sam@lab.example.test" -Department $row.Department -Path $base -Enabled $false -PassThru
            Add-ADGroupMember -Identity "GG_$($row.Department)" -Members $user
            [pscustomobject]@{Account=$sam;Result='CreatedDisabled';Detail='Set unique password and enable manually'}
        }
    } catch {
        $failures++
        # No automatic rollback/deletion: a partial account stays disabled for inspection.
        [pscustomobject]@{Account=$sam;Result='Failed';Detail=$_.Exception.Message}
    }
}
if ($failures) { throw "$failures user(s) failed. Inspect disabled partial accounts before retrying; existing users are skipped." }
