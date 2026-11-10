# 02: Employee receives APIPA address

Status: **Simulation / not executed**. All accounts and incidents are synthetic.

## Impact and priority
New endpoint blocked: normal priority; multiple failed leases raise impact.

## Symptoms
A new employee PC has a 169.254.x.x address and cannot access services.

## Controlled fault injection
In a saved Packet Tracer copy, remove ip helper-address 10.10.40.10 only from R1 Gi0/0.10. Renew EMP01 DHCP; do not alter the IT VLAN.

## Diagnostic steps
1. Confirm link, access VLAN and trunk membership.
2. Inspect the client address and Server-PT scope capacity.
3. Inspect R1 Gi0/0.10 and Simulation Mode DHCP Discover packets. Compare with working ADMIN01.

## Scenario root cause
DHCP broadcasts cannot cross the router because the employee relay address is missing.

## Resolution
Restore ip helper-address 10.10.40.10 on the employee subinterface and request a new lease.

## Verification
EMP01 receives .100-.199 in 10.10.10.0/24, gateway .1 and DNS 10.10.40.10; internal name lookup works.

## Rollback and evidence
Restore the saved topology if needed; record helper configuration and DHCP packet path.

Observed result: **pending operator execution**. Record host/tool versions, exact commands, before/after evidence and any difference from the expected result.
