<# .SYNOPSIS
Disable one ordinary lab staff account; never delete it or remove group memberships.
.EXAMPLE
.\scripts\Disable-LabUser.ps1 -SamAccountName alex.rivera -WhatIf
.NOTES
Disabling does not terminate every existing session or invalidate every issued ticket.
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')]
param([Parameter(Mandatory)][ValidatePattern('^[a-z][a-z0-9.]{2,19}$')][string]$SamAccountName)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module ActiveDirectory
if ((Get-ADDomain).DNSRoot -ne 'lab.example.test') { throw 'Wrong domain.' }
$user=Get-ADUser -Identity $SamAccountName -Properties adminCount,Enabled
if ($user.DistinguishedName -notlike '*,OU=Staff,OU=Lab,DC=lab,DC=example,DC=test' -or $user.adminCount -eq 1) { throw 'Only ordinary Staff OU accounts may be disabled by this script.' }
if (-not $user.Enabled) { Write-Output 'Already disabled; no change.'; return }
if ($PSCmdlet.ShouldProcess($user.SamAccountName,'Disable account')) {
    Disable-ADAccount -Identity $user
    Get-ADUser -Identity $user | Select-Object SamAccountName,Enabled
}
