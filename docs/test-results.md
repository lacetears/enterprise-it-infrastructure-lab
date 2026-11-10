# Validation results

Source validation performed 2026-11-10. These results are not deployment evidence.

| Check | Environment | Result |
|---|---|---|
| PowerShell parser + offline assertions | PowerShell 7.4.13 on Linux | 12 PowerShell files parsed; 22 assertions passed |
| Addressing and ACL policy evaluator | Python 3.12 on Linux | Seven network tests passed, including 17 packet-policy cases |
| Documentation links / scenario structure / prohibited artifact extensions | Python 3.12 on Linux | Passed; 10 total Python tests including seven network tests |
| Windows PowerShell 5.1 + PowerShell 7 CI | GitHub Actions Windows runner | Pending initial published run |
| AD DS/DNS/DHCP promotion and operation | Windows Server 2022 VM | Not run |
| GPO, domain join, share permissions, account lifecycle | Live Windows domain | Not run |
| Router/switch command acceptance and actual forwarding | Cisco Packet Tracer | Not run |
| Real printer, installer and performance exercises | Windows endpoint/hardware | Not run |

PowerShell offline tests exercise real CSV/XML code and mocked AD functions. They cover invalid schema, duplicate users, unexpected columns, filter-injection input, required fields, UTC conversion, missing event fields, XML DTD rejection, default planning, WhatIf, disabled-first creation, existing-account skips, wrong-domain rejection, preflight failure, and partial failure signaling. Mock success does not establish AD cmdlet behavior or permissions on a real server.

The ACL evaluator reads the actual R1.cfg rules and implements only their documented syntax. It fails on unsupported syntax, checks ordered first-match behavior, and defaults to deny. It does not run IOS, resolve ARP, route packets, implement TCP state, or test a service. Config text checks are consistency checks, not simulator validation.

Review findings addressed: no passwords in CSV; no enabling partially configured users; no swallowing event-log access errors as empty results; bounded event queries; no production domain target parameter; private evidence defaults; no broad firewall disable; no actual-internet claim for documentation addresses. Remaining weaknesses: single DC, nontransactional provisioning, broad employee-to-server permissions, stateless ACLs, no guest peer isolation, no live integration evidence. See SECURITY.md and acceptance procedures.

Reproduce from repository root:

```text
python -m unittest discover -s tests -v
pwsh -NoProfile -File tests/Test-Offline.ps1
powershell -NoProfile -File tests/Test-Offline.ps1
```

The final command requires Windows. GitHub Actions runs both Windows shells with read-only repository permissions. No domain changes are performed by CI.
