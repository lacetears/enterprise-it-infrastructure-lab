# Acceptance and evidence procedure

Do not mark a test passed until observed. Record date, operator, OS/PT version, commit, expected result, actual result, and sanitized evidence. Screenshot a real result only; no screenshots are supplied because no Windows/PT deployment was available during source preparation.

| ID | Environment | Action | Expected result |
|---|---|---|---|
| N01 | PT | Inspect trunk and VLAN table | Documented VLANs/native 999, correct access ports |
| N02 | PT | Renew employee and IT DHCP | Correct subnet, mask, gateway, internal DNS |
| N03 | PT | Renew guest DHCP | Guest pool and simulated public DNS |
| N04 | PT | Guest DNS/web to public model | DNS response + HTTP page; HTTPS only if service supported |
| N05 | PT | Guest to internal DC/IT/employee | Denied; correlate ACL counters/simulation drops |
| N06 | PT | Employee to server, then IT | Server application succeeds; IT denied |
| N07 | PT | SSH management from IT and guest | IT succeeds after console hardening; guest denied |
| W01 | Windows | SRV lookup + dcdiag | Internal domain discovery and DC tests succeed |
| W02 | Windows | Client DHCP + fresh domain logon | /27 lease, DNS .10, domain identity and DC reachable |
| W03 | Windows | Initialize OU/groups twice | Expected objects, no duplicate objects |
| W04 | Windows | Valid CSV, rerun, invalid CSV | Disabled users/group membership; rerun skips; invalid batch makes no users |
| W05 | Windows | Account disable with WhatIf then apply | No preview change; Enabled=False after confirmation |
| W06 | Windows | gpupdate/gpresult + wait idle | Dedicated GPO applied to CL01; 900-second idle lock observed |
| W07 | Windows | Operations share as both sample users | Operations can modify; Support denied after fresh sign-in |
| W08 | Windows | Generate controlled failed logon | 4625 parsed; lockout 4740 only when policy/test triggers it |
| W09 | Windows | Run inventory/diagnostics/maintenance report | Accurate local data; no mutation from report/default paths |
| W10 | Windows | Maintenance WhatIf then explicit action | No WhatIf change; selected action occurs only on intended VM |

Run `tests/Test-WindowsAcceptance.ps1` on CL01 for a subset (membership, SRV/A DNS, secure channel). It cannot validate GPO application, printer operation, permissions, or all network services. A green source CI run is not a Windows acceptance pass.

For each ticket, save a before/after observation, not just the final command. Keep evidence/local private. Copy redacted summaries into an explicitly named evidence report after reviewing them. For printer/software exercises, document the actual package/device; do not invent one if unavailable.
