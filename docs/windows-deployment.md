# Track B: Windows domain deployment

This runbook targets Windows Server 2022 Desktop Experience and Windows 11 Pro/Enterprise in isolated VMs. It has not been executed against live Windows Server here. Use local VM consoles, elevated Windows PowerShell 5.1, and checkpoints of disposable VMs. Never run it against an employer's domain.

## 1. Build and isolate

Install Hyper-V on a supported host, or use the equivalent internal network in another hypervisor. On a Hyper-V host, create `New-VMSwitch -Name LAB-PRIVATE -SwitchType Private`, then attach DC01, FS01, and CL01 only to that switch. Install Windows from official licensed/evaluation media. Set unique local administrator passwords. Patch images before enabling the isolated lab DHCP service. Disable extra VM NICs and do not bridge this switch to your home network.

During installation choose Windows Server 2022 Standard Evaluation (Desktop Experience) for the servers, Custom installation, and the blank VM disk. Complete the local Administrator setup at the VM console. On CL01 use a domain-join-capable Windows 11 edition and finish its local setup before joining. Never select a physical host disk.

Use the resources in [architecture](architecture.md). Name the servers DC01 and FS01 (`Rename-Computer -NewName DC01 -Restart`, substituting FS01 on that VM). Name the client CL01. A name change needs a restart before promotion/join.

## 2. Static server networking

Inspect `Get-NetAdapter` and substitute the actual adapter alias below. On DC01:

```powershell
New-NetIPAddress -InterfaceAlias 'Ethernet' -IPAddress 10.10.40.10 -PrefixLength 27
Set-DnsClientServerAddress -InterfaceAlias 'Ethernet' -ServerAddresses 10.10.40.10
Get-NetIPConfiguration
```

On FS01 use 10.10.40.11/27 and DNS 10.10.40.10. There is **no gateway** in this private single-subnet track. Remove a conflicting old address only after inspecting it; do not rerun New-NetIPAddress blindly. Record the original adapter configuration for recovery. Keep Windows Firewall enabled.

## 3. Install AD DS and DNS on DC01

```powershell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
$dsrm = Read-Host 'Unique DSRM recovery password' -AsSecureString
Install-ADDSForest -DomainName 'lab.example.test' -DomainNetbiosName 'LAB' -InstallDns -SafeModeAdministratorPassword $dsrm
```

Review prerequisite output and accept the promotion/reboot prompt. Do not skip prerequisite checks. After reboot, sign in as the new lab domain administrator. Verify `Get-ADDomain`, `Get-Service DNS,NTDS,Netlogon`, `dcdiag /test:dns`, and `Resolve-DnsName _ldap._tcp.dc._msdcs.lab.example.test -Type SRV`. Forwarder/internet failures are expected while isolated; internal SRV failures are not. No public resolver belongs on a domain member's adapter.

Create the reverse zone and FS01 A/PTR record once:

```powershell
Add-DnsServerPrimaryZone -NetworkId '10.10.40.0/24' -ReplicationScope Domain
Add-DnsServerResourceRecordA -ZoneName 'lab.example.test' -Name 'FS01' -IPv4Address '10.10.40.11' -CreatePtr
```

The /24 reverse zone intentionally covers the /27 subnet; it does not change the subnet mask. Check existing zones/records before rerunning. Domain DNS dynamic updates should be secure-only; inspect `Get-DnsServerZone`. Resolve both forward and reverse records.

## 4. DHCP on DC01 (small lab consolidation)

```powershell
Install-WindowsFeature DHCP -IncludeManagementTools
Add-DhcpServerInDC -DnsName 'DC01.lab.example.test' -IPAddress 10.10.40.10
Add-DhcpServerv4Scope -Name 'VM-Clients' -StartRange 10.10.40.20 -EndRange 10.10.40.29 -SubnetMask 255.255.255.224 -State Active
Set-DhcpServerv4OptionValue -ScopeId 10.10.40.0 -DnsServer 10.10.40.10 -DnsDomain 'lab.example.test'
Get-DhcpServerInDC
Get-DhcpServerv4Scope
```

Do not configure router option 003: no router exists in this track. Server-PT DHCP is in a separate simulation and does not conflict. Keep DNS registration by domain clients; dedicated DHCP DNS-update credentials are an optional later exercise, not supplied as a shared password. Consolidating DHCP on a DC is a resource-saving lab decision, not a general production recommendation.

## 5. OUs, groups and users

Copy this repository to DC01. Run:

```powershell
.\scripts\Initialize-LabDirectory.ps1 -WhatIf
.\scripts\Initialize-LabDirectory.ps1
.\scripts\New-LabUsers.ps1 -CsvPath .\config\users.example.csv
.\scripts\New-LabUsers.ps1 -CsvPath .\config\users.example.csv -Apply -WhatIf
.\scripts\New-LabUsers.ps1 -CsvPath .\config\users.example.csv -Apply
```

Accounts are disabled. For each disposable user, set a different initial password interactively, then enable:

```powershell
$password = Read-Host 'Unique temporary password for alex.rivera' -AsSecureString
Set-ADAccountPassword -Identity alex.rivera -Reset -NewPassword $password -ErrorAction Stop
Set-ADUser -Identity alex.rivera -ChangePasswordAtLogon $true -ErrorAction Stop
Enable-ADAccount -Identity alex.rivera -ErrorAction Stop
Remove-Variable password
```

Run these as separate checked steps; do not enable an account if password assignment failed. Do the same for jordan.chen with a different password. Inspect `Get-ADUser` and `Get-ADGroupMember GG_Operations`. No automatic privileged-group membership is configured.

## 6. Domain join

FS01 already has static DNS .10. Set CL01 IPv4 and DNS to automatic. On CL01 run `ipconfig /renew`, `ipconfig /all`; expect 10.10.40.20-.29, /27, DNS .10, and no gateway. Resolve DC01 and the SRV record before joining. On each member:

```powershell
Add-Computer -DomainName 'lab.example.test' -Credential (Get-Credential 'LAB\Administrator') -Restart
```

This privileged join is only for the disposable lab; production should delegate joins rather than give support staff Domain Admin. On DC01 use AD Users and Computers to move CL01 to Lab/Workstations and FS01 to Lab/Servers. Do not move DC01. Sign in to CL01 with `LAB\alex.rivera`, change the password, then verify `whoami`, `$env:LOGONSERVER`, and `Test-ComputerSecureChannel`. Cached sign-in alone does not prove DC connectivity.

## 7. Group Policy

On DC01 run `Set-LabWorkstationPolicy.ps1 -WhatIf`, then without WhatIf. The dedicated GPO sets the computer inactivity timeout to 900 seconds on the Workstations OU. On CL01 run `gpupdate /force`, then `gpresult /r /scope computer` elevated and `gpresult /h C:\Windows\Temp\lab-gpresult.html`. Confirm the policy registry value and observe an idle lock; don't claim success solely from the GPO existing.

For Security events, create a separate GPO `LAB-Audit-Logons` in Group Policy Management. Configure Computer Configuration > Policies > Windows Settings > Security Settings > Advanced Audit Policy Configuration > Logon/Logoff > Audit Logon: Success and Failure. Link to Workstations. On a separate DC-specific lab GPO, enable Account Management > Audit User Account Management: Success (4740 lockout). Link that policy to Domain Controllers only after reviewing settings. Verify on the relevant host with `auditpol /get /category:*` and generated test events. For a lockout exercise, use a fine-grained password policy scoped to a disposable test group rather than weakening or repeatedly changing the domain default.

## 8. File share on FS01

Create a new empty folder `C:\LabShares\Operations`. On FS01, elevated:

```powershell
New-Item -ItemType Directory -Path C:\LabShares\Operations
icacls C:\LabShares\Operations /inheritance:r
icacls C:\LabShares\Operations /grant:r 'SYSTEM:(OI)(CI)F' 'BUILTIN\Administrators:(OI)(CI)F' 'LAB\DL_Operations_Modify:(OI)(CI)M'
New-SmbShare -Name Operations -Path C:\LabShares\Operations -ChangeAccess 'LAB\DL_Operations_Modify' -FullAccess 'BUILTIN\Administrators'
```

Check `$LASTEXITCODE` after each icacls command; stop on errors. Never substitute a system folder. Enable the File and Printer Sharing (SMB-In) firewall rule for the Domain profile with scope 10.10.40.0/27, using Windows Defender Firewall with Advanced Security; do not disable the firewall. Verify both `Get-SmbShareAccess Operations` and `icacls`.

On CL01 as alex.rivera, create/read/delete a disposable file at `\\FS01\Operations`. Sign out completely, sign in as jordan.chen and verify denial. Log on again after group changes to refresh the token. Do not add Everyone Full Control to fix a test. User group permissions are cumulative; a deny ACE can override an allow.

## 9. Deactivation and recovery

Preview `Disable-LabUser.ps1 -SamAccountName alex.rivera -WhatIf`; apply only to the disposable lab account, review confirmation, and verify `Enabled=False`. Existing sessions/tickets can outlive a disable; sign out and attempt a fresh authenticated connection. Retain account objects/group assignments for review. Restore with `Enable-ADAccount` only when the exercise is complete and authorized.

Checkpoint the lab before fault injection. For full rollback, restore a coordinated set of disposable lab VMs or rebuild. VM checkpoints are not an AD backup strategy. A production recovery plan requires supported system-state backups and recovery testing, beyond this lab.
