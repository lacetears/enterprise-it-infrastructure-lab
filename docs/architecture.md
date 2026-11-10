# Addressing and service design

All names, users, and incident scenarios are synthetic. `lab.example.test` is a lab-only DNS namespace. The simulated public subnet uses documentation addresses and has no internet route.

| VLAN | Purpose | Subnet / usable hosts | Gateway | Allocation |
|---|---|---|---|---|
| 10 | Employees | 10.10.10.0/24, 254 | 10.10.10.1 | .100-.199, server DHCP |
| 20 | IT | 10.10.20.0/27, 30 | 10.10.20.1 | .10-.29, server DHCP; SW1 .2 |
| 30 | Guests | 10.10.30.0/24, 254 | 10.10.30.1 | .100-.199, router DHCP |
| 40 | Servers | 10.10.40.0/27, 30 | 10.10.40.1 | Static .10 DHCP/DNS, .11 file-service model |
| 999 | Unused/native | No IP subnet | None | Native trunk VLAN; unused ports shut |

A /27 uses mask 255.255.255.224 and wildcard 0.0.0.31; /24 uses 255.255.255.0 and wildcard 0.0.0.255. VLAN 20/40 network addresses are .0 and broadcast addresses .31. Pools exclude gateways and static hosts. `config/lab.json` is the design inventory, not an automatic device configurator; tests check corresponding values.

## Track A packet paths

Employee DHCP broadcast enters R1 Gi0/0.10. The inbound ACL first permits UDP client port 68 to server port 67, then the helper relays to 10.10.40.10. The relay gateway address identifies the correct scope. Replies return through the router to VLAN 10. IT uses the same process from .20. Guests use R1's separate pool and the public DNS model.

Employee traffic can reach VLAN 40 services and ping its own gateway, but is denied to IT, guests, and other destinations. IT has routed access without an inbound data ACL; VTY login still requires SSH credentials and an IT source address. This is not complete endpoint-management segmentation: the employee ACL does not allow arbitrary return traffic for IT-initiated sessions to employee devices. Remote management of employee machines is outside this baseline.

Guest ingress permits DHCP, gateway ICMP echo, and DNS/HTTP/HTTPS only to 198.51.100.10. It denies everything else. ACLs do not isolate hosts within the same VLAN; guest peer isolation requires wireless AP/switch controls not modeled here. DHCP permits `any` before address-specific rules to support clients starting at 0.0.0.0; DHCP snooping and spoofing protections are future work, not claimed features.

## Track B VM resources

Recommended starting host capacity: 16 GB RAM, virtualization support, roughly 150 GB free SSD. Allocate DC01 2 vCPU/4 GB/60 GB thin disk, FS01 2 vCPU/2 GB/40 GB, CL01 2 vCPU/4 GB/64 GB. These are planning allocations, not measured performance requirements. Use licensed/evaluation Windows Server 2022 and Windows 11 Pro/Enterprise; Home cannot join AD. Windows 11 needs the supported virtual TPM/Secure Boot configuration.

Private vSwitch `LAB-PRIVATE`, no uplink, no host adapter, no NAT. DC01 .10/27, FS01 .11/27; CL01 leases .20-.29. No default gateway in this track. Internet resolution and updates will not work on this network; patch the images before isolation. Never attach the active DHCP server to a bridged production network. Packet Tracer's .40.1 router does not exist in Track B.

## Directory design

`OU=Lab` contains Staff, Workstations, Servers, and Groups. DC01 stays in the built-in Domain Controllers OU. User accounts belong to global groups `GG_Operations` or `GG_Support`; `GG_Operations` nests in domain-local `DL_Operations_Modify` assigned to the Operations share. This follows accounts -> global group -> domain-local group -> permission (AGDLP). Use a separate administrative identity and ordinary staff accounts for testing. Do not add sample staff to Domain Admins.
