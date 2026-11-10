<# .SYNOPSIS
Create the lab OU hierarchy and ordinary department groups in an existing lab domain.
.EXAMPLE
.\scripts\Initialize-LabDirectory.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param()
$ErrorActionPreference='Stop'
Import-Module ActiveDirectory
$domain=Get-ADDomain
if ($domain.DNSRoot -ne 'lab.example.test') { throw 'Wrong domain.' }
$root=$domain.DistinguishedName
$ous=@(@{Name='Lab';Path=$root},@{Name='Staff';Path="OU=Lab,$root"},@{Name='Workstations';Path="OU=Lab,$root"},@{Name='Servers';Path="OU=Lab,$root"},@{Name='Groups';Path="OU=Lab,$root"})
$existing=@(Get-ADOrganizationalUnit -Filter * | Select-Object -ExpandProperty DistinguishedName)
foreach ($ou in $ous) {
    $dn="OU=$($ou.Name),$($ou.Path)"
    if ($dn -notin $existing -and $PSCmdlet.ShouldProcess($dn,'Create protected OU')) { New-ADOrganizationalUnit @ou -ProtectedFromAccidentalDeletion $true }
}
foreach ($name in @('GG_Operations','GG_Support','DL_Operations_Modify')) {
    if (-not @(Get-ADGroup -Filter "SamAccountName -eq '$name'").Count -and $PSCmdlet.ShouldProcess($name,'Create security group')) {
        $scope=if ($name -like 'DL_*') {'DomainLocal'} else {'Global'}
        New-ADGroup -Name $name -SamAccountName $name -GroupScope $scope -GroupCategory Security -Path "OU=Groups,OU=Lab,$root"
    }
}
if ($PSCmdlet.ShouldProcess('DL_Operations_Modify','Nest GG_Operations (AGDLP)')) {
    $members=@(Get-ADGroupMember 'DL_Operations_Modify' | Select-Object -ExpandProperty SamAccountName)
    if ('GG_Operations' -notin $members) { Add-ADGroupMember 'DL_Operations_Modify' -Members 'GG_Operations' }
}
