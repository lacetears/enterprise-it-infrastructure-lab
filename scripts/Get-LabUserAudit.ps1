<# .SYNOPSIS
Read-only inventory of lab staff. LastLogonDate is replicated and approximate, not proof of inactivity.
.EXAMPLE
.\scripts\Get-LabUserAudit.ps1 | ConvertTo-Json | Set-Content .\evidence\local\users.json
#>
[CmdletBinding()]
param([ValidateRange(1,3650)][int]$InactiveDays=90)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module ActiveDirectory
if ((Get-ADDomain).DNSRoot -ne 'lab.example.test') { throw 'Wrong domain.' }
$cutoff=(Get-Date).AddDays(-$InactiveDays)
Get-ADUser -Filter * -SearchBase 'OU=Staff,OU=Lab,DC=lab,DC=example,DC=test' -Properties Enabled,LockedOut,PasswordNeverExpires,LastLogonDate,whenCreated,PasswordLastSet |
    Select-Object SamAccountName,Enabled,LockedOut,PasswordNeverExpires,LastLogonDate,PasswordLastSet,@{n='ReviewReason';e={
        if (-not $_.LastLogonDate) { 'No replicated logon recorded; investigate, do not auto-disable' }
        elseif ($_.LastLogonDate -lt $cutoff) { 'Approximate inactivity threshold reached' }
        else { 'Recent replicated logon' }
    }}
