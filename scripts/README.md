# PowerShell tool reference

Use Windows PowerShell 5.1 on the isolated Windows lab. AD tools require the ActiveDirectory RSAT module and delegated rights; the policy script also requires GroupPolicy. The common module and offline tests run on PowerShell 7 on Linux. PowerShell 7 parsing does not prove Windows cmdlet compatibility; CI also checks 5.1 syntax and mocked behavior.

| File | Behavior and required rights |
|---|---|
| New-LabUsers.ps1 | Offline CSV plan by default; `-Apply` needs AD read/create/group-membership rights in Lab OUs; supports WhatIf |
| Get-LabUserAudit.ps1 | AD read; approximate replicated logon information; never automatically disables |
| Disable-LabUser.ps1 | AD disable rights; Staff OU and adminCount guard; confirmation + WhatIf |
| Initialize-LabDirectory.ps1 | Create OU/groups in the lab; no passwords or domain-admin membership; WhatIf |
| Set-LabWorkstationPolicy.ps1 | GPO create/edit/link rights; dedicated lab GPO only; WhatIf |
| Get-SystemInventory.ps1 | Local read-only CIM/network collection; elevation may be needed for restricted inventory |
| Test-LabNetwork.ps1 | Local DNS/TCP probes to one explicit host, maximum 16 ports; no configuration changes |
| Get-AuthenticationEvents.ps1 | Local Security-log read permission (typically elevated); bounded 4624/4625/4740 query |
| Invoke-LabMaintenance.ps1 | Report by default; explicit FlushDns/RestartSpooler requires appropriate local privilege; confirmation + WhatIf |

Run from the repository root. `Get-Help .\scripts\New-LabUsers.ps1 -Full` shows examples. Store results locally:

```powershell
New-Item -ItemType Directory -Force .\evidence\local | Out-Null
.\scripts\Get-SystemInventory.ps1 | ConvertTo-Json -Depth 8 | Set-Content .\evidence\local\inventory.json
.\scripts\Get-LabUserAudit.ps1 | ConvertTo-Json | Set-Content .\evidence\local\users.json
.\scripts\Test-LabNetwork.ps1 -Target DC01.lab.example.test | Format-Table
.\scripts\Get-AuthenticationEvents.ps1 -Hours 2 -MaxEvents 200 | Format-Table
.\scripts\Invoke-LabMaintenance.ps1 -Action RestartSpooler -WhatIf
```

Do not publish raw account inventories, host identifiers, passwords, credential prompts, or unredacted event exports. JSON is preferred for reports; opening untrusted CSV in spreadsheet software can interpret formula-like fields.

## Failure semantics

CSV schema is strict: four named columns, nonempty names, unique lowercase account names, and one of Operations/Support. Extra columns (including passwords) are rejected. All CSV validation happens before AD mutation. Missing OU/group or wrong domain stops preflight. Each create failure is emitted, subsequent rows are attempted, then a terminating error marks the batch failed. It is not a transaction. If group assignment failed after creation, the user remains disabled; the next run skips the existing user, so inspect and repair membership manually.

WhatIf avoids writes but `-Apply -WhatIf` still performs AD reads and needs a valid lab connection. Offline planning is the way to validate without AD. Mutation scripts do not promise production-grade authorization boundaries; their domain/OU guards are accident prevention, not a replacement for delegated permissions.

A DNS test may pass while TCP name resolution fails: the explicit DNS query uses `-DnsServer`, but Test-NetConnection uses the operating system's DNS configuration. Inspect the configured adapter servers. TCP success does not prove LDAP bind, SMB access, authentication, or UDP availability.
