<# .SYNOPSIS
Read-only DNS and TCP diagnostics for an explicit host, without changing adapters or firewall rules.
.EXAMPLE
.\scripts\Test-LabNetwork.ps1 -Target DC01.lab.example.test -DnsServer 10.10.40.10 -Port 53,88,389,445
#>
[CmdletBinding()]
param(
    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9.-]{0,252}$')][string]$Target='DC01.lab.example.test',
    [ValidatePattern('^\d{1,3}(\.\d{1,3}){3}$')][string]$DnsServer='10.10.40.10',
    [ValidateCount(1,16)][ValidateRange(1,65535)][int[]]$Port=@(53,88,389,445)
)
$ErrorActionPreference='Stop'
$null=[ipaddress]::Parse($DnsServer)
if ($env:OS -ne 'Windows_NT') { throw 'Windows DNSClient and NetTCPIP modules are required.' }
try {
    $answers=@(Resolve-DnsName -Name $Target -Server $DnsServer -Type A -DnsOnly)
    [pscustomobject]@{Check='DNS';Target=$Target;Port=$null;Success=$true;Detail=($answers | Out-String).Trim()}
} catch { [pscustomobject]@{Check='DNS';Target=$Target;Port=$null;Success=$false;Detail=$_.Exception.Message} }
foreach ($p in $Port) {
    try {
        $result=Test-NetConnection -ComputerName $Target -Port $p -WarningAction SilentlyContinue
        [pscustomobject]@{Check='TCP';Target=$Target;Port=$p;Success=$result.TcpTestSucceeded;Detail=[string]$result.RemoteAddress}
    } catch { [pscustomobject]@{Check='TCP';Target=$Target;Port=$p;Success=$false;Detail=$_.Exception.Message} }
}
# TCP uses the OS resolver. Compare adapter DNS with the explicit query server when results differ.
