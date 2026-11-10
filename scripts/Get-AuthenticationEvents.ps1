<# .SYNOPSIS
Read bounded Security events and extract named XML fields. No log clearing or credential collection.
.EXAMPLE
.\scripts\Get-AuthenticationEvents.ps1 -Hours 4 -MaxEvents 200 | ConvertTo-Json
.NOTES
Security-log permission required. 4624/4625 are logged at the authenticating endpoint;
4740 is normally investigated on a DC. Audit policy must be enabled first.
#>
[CmdletBinding()]
param([ValidateRange(1,720)][int]$Hours=24,[ValidateRange(1,10000)][int]$MaxEvents=500)
$ErrorActionPreference='Stop'
Import-Module "$PSScriptRoot/Lab.Common.psm1" -Force
try { $events=@(Get-WinEvent -FilterHashtable @{LogName='Security';Id=4624,4625,4740;StartTime=(Get-Date).AddHours(-$Hours)} -MaxEvents $MaxEvents -ErrorAction Stop) }
catch {
    if ($_.FullyQualifiedErrorId -like 'NoMatchingEventsFound*') { Write-Verbose 'No matching events in the requested period.'; return }
    throw # Permission, missing-log, and platform failures must not look like zero events.
}
if ($events.Count -eq $MaxEvents) { Write-Warning 'Result limit reached; narrow the time range or increase MaxEvents. This is not a complete event count.' }
foreach ($event in $events) { Convert-LabEvent -Xml $event.ToXml() }
