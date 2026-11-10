<# .SYNOPSIS
Read-only acceptance checks on a domain-joined Windows lab client. Does not prove GPO or permissions.
.EXAMPLE
.\tests\Test-WindowsAcceptance.ps1
#>
[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$checks=@()
try {
    $system=Get-CimInstance Win32_ComputerSystem
    $checks += [pscustomobject]@{Check='Domain membership';Passed=($system.PartOfDomain -and $system.Domain -eq 'lab.example.test');Detail=$system.Domain}
} catch { $checks += [pscustomobject]@{Check='Domain membership';Passed=$false;Detail=$_.Exception.Message} }
foreach ($query in @(@{Name='DC01.lab.example.test';Type='A'},@{Name='_ldap._tcp.dc._msdcs.lab.example.test';Type='SRV'})) {
    try { $answer=@(Resolve-DnsName -Name $query.Name -Type $query.Type -Server 10.10.40.10 -DnsOnly);$checks += [pscustomobject]@{Check=$query.Name;Passed=($answer.Count -gt 0);Detail='DNS answered'} }
    catch { $checks += [pscustomobject]@{Check=$query.Name;Passed=$false;Detail=$_.Exception.Message} }
}
try { $channel=Test-ComputerSecureChannel; $checks += [pscustomobject]@{Check='Secure channel';Passed=$channel;Detail='No repair requested'} }
catch { $checks += [pscustomobject]@{Check='Secure channel';Passed=$false;Detail=$_.Exception.Message} }
$checks
if (@($checks | Where-Object { -not $_.Passed }).Count) { throw 'Windows acceptance failed; investigate the reported checks.' }
