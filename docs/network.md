# Track A: Packet Tracer build

## Equipment and cabling

Use one 2911 router (R1), one 2960 switch (SW1), three PCs, and three Server-PT nodes. The interface names below are for these models; confirm `show ip interface brief` before pasting. Configurations are templates, not a `.pkt` topology or claimed simulator result.

| Cable | Purpose |
|---|---|
| R1 Gi0/0 -> SW1 Gi0/1 | 802.1Q trunk |
| EMP01 -> SW1 Fa0/1 | VLAN 10 |
| ADMIN01 -> SW1 Fa0/5 | VLAN 20 |
| GUEST01 -> SW1 Fa0/7 | VLAN 30 |
| DHCP-DNS -> SW1 Fa0/9 | VLAN 40 |
| FILE-MODEL -> SW1 Fa0/10 | VLAN 40 |
| PUBLIC-SERVICES -> R1 Gi0/1 | Simulated external network |

Use automatic cable selection. On each Cisco device: `enable`, `configure terminal`, then paste its [R1](../network/R1.cfg) or [SW1](../network/SW1.cfg) configuration. Check every rejected command; do not treat a partial paste as a pass. Run `copy running-config startup-config` after verification.

## Services

1. DHCP-DNS: static 10.10.40.10, mask 255.255.255.224, gateway 10.10.40.1, DNS itself.
2. Under Services > DHCP, enable the service and add the two pools in [dhcp-pools.csv](../network/dhcp-pools.csv). Remove/disable any default pool that could overlap. Relay chooses each scope; do not put both client pools on the server's NIC.
3. Under Services > DNS, enable and add A records `dc01.lab.example.test` -> 10.10.40.10 and `fs01.lab.example.test` -> 10.10.40.11. These are name-resolution models; Server-PT cannot implement AD SRV discovery or a domain join.
4. FILE-MODEL: 10.10.40.11/27, gateway .1, DNS .10. Enable HTTP solely as a reachability stand-in; it is not SMB/NTFS.
5. PUBLIC-SERVICES: 198.51.100.10/24, gateway 198.51.100.1, DNS itself. Enable DNS and HTTP; create `portal.example.test` -> 198.51.100.10. Enable HTTPS if that Packet Tracer build supports it. An ACL permit does not guarantee the simulated application supports a service.
6. Set all three PCs to DHCP. Expected employee .100-.199, IT .10-.29, guest .100-.199 in their respective subnets. Employee/IT DNS should be 10.10.40.10; guest DNS should be 198.51.100.10.

## Console-only management setup

The templates deliberately contain no reusable credentials. Before testing SSH, enter unique lab-only values at the console on both devices:

```text
configure terminal
username labadmin privilege 15 secret <choose-a-unique-local-secret>
enable secret <choose-a-different-local-secret>
crypto key generate rsa
! Choose 2048 bits when prompted and supported.
ip ssh version 2
end
```

Angle-bracket text is a prompt, not a literal command. Do not commit running-config exports containing hashes or secrets. SSH is intended only from VLAN 20; Telnet is disabled on VTY. Use console access to recover a management mistake.

## Verify and record

- `show vlan brief`: access ports in intended VLANs; no user ports in VLAN 1.
- `show interfaces trunk`: VLANs 10,20,30,40,999 allowed; native 999.
- `show ip interface brief` and `show ip route`: connected subnets exist, physical uplinks up.
- `show access-lists`: counters change for test traffic. Test actual application traffic, not only ping.
- `show ip dhcp binding`: guest lease on R1. Employee/IT leases reside on Server-PT.
- EMP01 resolves internal names and opens HTTP at 10.10.40.11; cannot SSH SW1 or reach guest network.
- GUEST01 resolves portal.example.test and opens its web page; cannot query internal DNS or reach internal hosts. Failure to ping the public model is expected: ICMP to it is not permitted.
- ADMIN01 can SSH R1/SW1 only after local credentials/keys exist. Do not claim employee remote administration works with the baseline ACL.

Use Simulation Mode to inspect DHCP Discover/Offer and relay packets and ACL drops. Capture your Packet Tracer version, exact model, commands rejected, and result for each case. Save your real `.pkt` locally; the ignore rule prevents accidental publication of a credential-bearing topology. Share a sanitized copy only after reviewing every config.

Rollback: reopen a saved baseline `.pkt` or correct the affected stanza through the console. Do not erase devices on a real network.
