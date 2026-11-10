# Primary technical references

Consult these alongside the targeted OS/device version. They establish command behavior, not evidence that this lab was deployed.

- [Microsoft: install AD DS](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/deploy/install-active-directory-domain-services--level-100-)
- [Microsoft: New-ADUser](https://learn.microsoft.com/en-us/powershell/module/activedirectory/new-aduser): password failure can leave a created disabled account; this lab separates creation from password assignment.
- [Microsoft: Get-WinEvent](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-winevent): filter bounded log reads and parse EventData XML.
- [Microsoft: Hyper-V virtual switches](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/get-started/create-a-virtual-switch-for-hyper-v-virtual-machines): private/internal/external isolation choices.
- [Cisco: DHCP troubleshooting](https://www.cisco.com/c/en/us/support/docs/ip/dynamic-address-allocation-resolution/27470-100.html): relay configuration and troubleshooting evidence.
- [Cisco: IOS XE DHCP relay](https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/ipaddr_dhcp/configuration/xe-2/dhcp-xe-2-book/dhcp-relay-agent-xe.html): helper-address behavior. IOS XE documentation does not guarantee Packet Tracer feature parity.

Reviewed during source preparation on 2026-11-10. Operational scripts target Windows Server 2022 / Windows PowerShell 5.1; network templates target Packet Tracer 2911/2960 models, with simulator validation pending.
