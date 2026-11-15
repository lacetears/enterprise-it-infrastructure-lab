# Configuration backup and recovery

A startup config survives a reboot; it is not an off-device backup. Work on disposable lab devices using their consoles.

1. Record simulator version, device model and repository commit. Save a private copy of the clean topology before injecting faults.
2. Run `show running-config`, `show startup-config`, `show vlan brief`, `show interfaces trunk` (switch), `show ip route` (router) and `show access-lists`. Export actual console text to a private dated directory.
3. After successful acceptance, run `copy running-config startup-config` and accept the filename. Confirm with `show startup-config`.
4. Keep full credential-bearing backups private. For a public example, remove username/enable secrets, password hashes, SNMP communities, keys and identifying metadata. Mark omissions; a redacted config is not a complete restore artifact.
5. For a small mistake, restore the specific reviewed stanza at the console, then repeat positive and negative tests. A pasted configuration merges; it does not automatically remove unwanted commands. A full lab restore is safest by reopening the saved clean `.pkt` in this simulator workflow.
6. Prove recovery by restoring a copy and rerunning DHCP, DNS, allowed services and denied flows. Record the recovery time only after measuring it.

No backup or restore execution is claimed. Never erase or reload a device belonging to a real network as part of this exercise.
