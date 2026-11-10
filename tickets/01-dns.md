# 01: Domain resources fail by name

Status: **Simulation / not executed**. All accounts and incidents are synthetic.

## Impact and priority
Multiple affected staff: high impact; triage shared infrastructure before resetting individual accounts.

## Symptoms
Several users cannot open the Operations share by name; an existing IP connection still works.

## Controlled fault injection
On CL01 only, record the current DNS setting, then set its DNS server to the unused lab address 10.10.40.30. Do not change DC01.

## Diagnostic steps
1. Run ipconfig /all; compare adapter DNS with the DHCP design.
2. Query Resolve-DnsName FS01.lab.example.test using the default resolver, then explicitly -Server 10.10.40.10.
3. Query the domain SRV record; compare name resolution with Test-NetConnection 10.10.40.11 -Port 445.

## Scenario root cause
The client points to a non-authoritative, unreachable DNS server. This fault is deliberately injected; a similar symptom in a real incident needs evidence.

## Resolution
Restore automatic DNS with Set-DnsClientServerAddress -InterfaceAlias Ethernet -ResetServerAddresses, renew the lease, then Clear-DnsClientCache.

## Verification
Default-resolver A and SRV queries succeed; open the share as an authorized user and verify the configured DNS is .10.

## Rollback and evidence
Restore the recorded adapter values if different from the baseline; retain before/after DNS output.

Observed result: **pending operator execution**. Record host/tool versions, exact commands, before/after evidence and any difference from the expected result.
