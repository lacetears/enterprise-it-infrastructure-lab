# 05: Employee connected to guest VLAN

Status: **Simulation / not executed**. All accounts and incidents are synthetic.

## Impact and priority
Single workstation blocked; avoid changing global routing to solve a port mistake.

## Symptoms
A workstation receives an unexpected subnet and can reach the visitor portal but not internal resources.

## Controlled fault injection
In a Packet Tracer copy, change SW1 Fa0/1 access VLAN from 10 to 30 and renew EMP01 DHCP.

## Diagnostic steps
1. Inspect client subnet/gateway/DNS.
2. Map the cable to its switch port; inspect show vlan brief and show interfaces switchport.
3. Compare the assigned VLAN with the port map before changing ACLs.

## Scenario root cause
The access port is assigned to the guest VLAN, so the guest DHCP and isolation policy correctly apply.

## Resolution
Restore switchport access vlan 10 on Fa0/1, renew DHCP and confirm the employee pool.

## Verification
Correct employee lease and internal access; guest station still cannot reach internal services.

## Rollback and evidence
Restore baseline port assignment; save a sanitized VLAN table and client addressing.

Observed result: **pending operator execution**. Record host/tool versions, exact commands, before/after evidence and any difference from the expected result.
