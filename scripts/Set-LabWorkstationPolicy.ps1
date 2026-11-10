<# .SYNOPSIS
Create a dedicated workstation GPO with a 15-minute inactivity lock. Does not edit Default Domain Policy.
.EXAMPLE
.\scripts\Set-LabWorkstationPolicy.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param()
$ErrorActionPreference='Stop'
Import-Module ActiveDirectory
Import-Module GroupPolicy
if ((Get-ADDomain).DNSRoot -ne 'lab.example.test') { throw 'Wrong domain.' }
$target='OU=Workstations,OU=Lab,DC=lab,DC=example,DC=test'
$null=Get-ADOrganizationalUnit -Identity $target
$name='LAB-Workstation-Inactivity'
$gpo=Get-GPO -All | Where-Object DisplayName -eq $name
if ($PSCmdlet.ShouldProcess($target,'Create/update and link 900-second workstation inactivity policy')) {
    if (-not $gpo) { $gpo=New-GPO -Name $name }
    Set-GPRegistryValue -Guid $gpo.Id -Key 'HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System' -ValueName InactivityTimeoutSecs -Type DWord -Value 900 | Out-Null
    $links=@((Get-GPInheritance -Target $target).GpoLinks | Select-Object -ExpandProperty DisplayName)
    if ($name -notin $links) { New-GPLink -Guid $gpo.Id -Target $target -LinkEnabled Yes | Out-Null }
    Get-GPO -Guid $gpo.Id
}
