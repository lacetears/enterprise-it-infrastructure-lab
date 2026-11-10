<# .SYNOPSIS
Report disk/service status or explicitly flush DNS/restart Print Spooler on a local Windows workstation.
.EXAMPLE
.\scripts\Invoke-LabMaintenance.ps1
.EXAMPLE
.\scripts\Invoke-LabMaintenance.ps1 -Action RestartSpooler -WhatIf
.NOTES
Restart interrupts local printing. No temporary-file deletion, registry cleaning, updates, or log deletion.
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')]
param([ValidateSet('Report','FlushDns','RestartSpooler')][string]$Action='Report')
$ErrorActionPreference='Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Windows is required.' }
if ($Action -eq 'Report') {
    Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | Select-Object DeviceID,Size,FreeSpace
    Get-Service -Name Spooler | Select-Object Name,Status,StartType
    return
}
if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME,$Action)) {
    switch ($Action) {
        'FlushDns' { Clear-DnsClientCache; Write-Output 'DNS client cache cleared.' }
        'RestartSpooler' { Restart-Service -Name Spooler -ErrorAction Stop; Get-Service -Name Spooler }
    }
}
