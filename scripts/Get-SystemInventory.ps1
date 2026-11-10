<# .SYNOPSIS
Collect read-only local Windows inventory. Output may identify a device; keep it private.
.EXAMPLE
.\scripts\Get-SystemInventory.ps1 | ConvertTo-Json -Depth 5
#>
[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Windows is required for CIM inventory.' }
$os=Get-CimInstance Win32_OperatingSystem
$system=Get-CimInstance Win32_ComputerSystem
[pscustomobject]@{
    CollectedUtc=[DateTime]::UtcNow.ToString('o'); Computer=$env:COMPUTERNAME
    OS=$os.Caption; Build=$os.BuildNumber; LastBoot=$os.LastBootUpTime
    MemoryGB=[math]::Round($system.TotalPhysicalMemory/1GB,2); Domain=$system.Domain
    Disks=@(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | Select-Object DeviceID,@{n='SizeGB';e={[math]::Round($_.Size/1GB,2)}},@{n='FreeGB';e={[math]::Round($_.FreeSpace/1GB,2)}})
    Network=@(Get-NetIPConfiguration | Select-Object InterfaceAlias,IPv4Address,IPv4DefaultGateway,DNSServer)
}
