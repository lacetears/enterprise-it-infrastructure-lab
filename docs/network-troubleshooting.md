# Network troubleshooting exercises

All six are **simulated incidents, not executed**. The listed root causes belong to deliberate fault-injection exercises; they are not claims about observed outages. Save a clean topology, inject one fault, predict the result, diagnose without the solution, then restore and record evidence.

## N1: Workstation cannot reach its gateway

**Symptoms:** HR01 has no gateway reply; other HR hosts work.

**Likely causes:** Wrong access VLAN, bad mask, disconnected cable, shutdown port, ICMP policy.

**Diagnostic commands:** `ipconfig /all; show interfaces status; show vlan brief; show ip interface brief`

**Investigation:** Compare endpoint address with inventory; inspect Fa0/11 membership before changing router routes.

**Scenario root cause:** In this injected scenario Fa0/11 was placed in VLAN 60 while HR01 kept a VLAN 50 lease.

**Corrective action:** On SW1 Fa0/11 restore switchport access vlan 50; renew HR01 DHCP.

**Verification:** Check correct /27 lease, gateway echo and internal HTTP; confirm Finance remains denied.

**Rollback/evidence:** Reopen the saved baseline if recovery fails. Record before/after configuration, actual output, date, simulator version and commit. Result: NOT RUN.

## N2: Incorrect DHCP address

**Symptoms:** HR01 receives 10.10.60.x or 169.254.x.x.

**Likely causes:** Wrong VLAN, competing pool, stale static setting, missing relay or exhausted pool.

**Diagnostic commands:** `ipconfig /all; ipconfig /release; ipconfig /renew; show running-config; show ip dhcp binding`

**Investigation:** Check DHCP Server and lease fields; compare relay subinterface and server pool. R1 bindings show guests only.

**Scenario root cause:** In this injected scenario the HR Server-PT pool default gateway is 10.10.60.1.

**Corrective action:** Correct HR pool gateway to 10.10.50.1, mask /27, DNS .40.10; renew the lease.

**Verification:** Confirm lease .50.10-.29 and gateway .50.1, then DNS and HTTP. A lease alone is insufficient.

**Rollback/evidence:** Reopen the saved baseline if recovery fails. Record before/after configuration, actual output, date, simulator version and commit. Result: NOT RUN.

## N3: Inter-VLAN service fails

**Symptoms:** HR gateway responds but file-service model .40.11 does not.

**Likely causes:** Missing route, bad tag, wrong server gateway, ACL deny, disabled service.

**Diagnostic commands:** `show ip route; show ip interface brief; show access-lists; ping 10.10.40.11`

**Investigation:** Inspect connected .50/27 and .40/27 routes, then server address/gateway and actual HTTP service.

**Scenario root cause:** In this injected scenario FILE-MODEL has the wrong default gateway, so it cannot return off-subnet traffic.

**Corrective action:** Restore server gateway 10.10.40.1 without changing broad ACL policy.

**Verification:** HTTP from HR succeeds; verify original forbidden department session still fails.

**Rollback/evidence:** Reopen the saved baseline if recovery fails. Record before/after configuration, actual output, date, simulator version and commit. Result: NOT RUN.

## N4: ACL blocks legitimate traffic

**Symptoms:** HR can ping its gateway but cannot query internal DNS.

**Likely causes:** An earlier deny, wrong source wildcard, wrong ACL direction, or DNS outage.

**Diagnostic commands:** `nslookup dc01.lab.example.test 10.10.40.10; show access-lists; show running-config`

**Investigation:** Compare DNS from IT and HR; observe HR_IN counters and first matching rule.

**Scenario root cause:** In this injected scenario deny ip any any was moved before the server permit.

**Corrective action:** Using console in a saved disposable topology, restore HR_IN to the reviewed ordered block. Remove the broken ACL only while disconnected from other networks.

**Verification:** Query internal DNS and open HTTP; also verify HR-to-Finance remains denied. Never solve this with permit ip any any.

**Rollback/evidence:** Reopen the saved baseline if recovery fails. Record before/after configuration, actual output, date, simulator version and commit. Result: NOT RUN.

## N5: Switch trunk omits a VLAN

**Symptoms:** All HR endpoints lose routed access while other departments work.

**Likely causes:** VLAN 50 omitted from allowed list, VLAN absent, link down or native mismatch.

**Diagnostic commands:** `show interfaces trunk; show vlan brief; show interfaces GigabitEthernet0/1 switchport`

**Investigation:** Distinguish allowed VLANs from allowed-and-active and forwarding VLANs. Compare router tag 50 with switch VLAN membership.

**Scenario root cause:** In this injected scenario VLAN 50 was removed from trunk allowed VLANs.

**Corrective action:** On SW1 Gi0/1 use switchport trunk allowed vlan add 50; do not replace the list with only 50.

**Verification:** Recheck trunk lists, renew HR DHCP and test allowed/denied flows for HR and another unchanged VLAN.

**Rollback/evidence:** Reopen the saved baseline if recovery fails. Record before/after configuration, actual output, date, simulator version and commit. Result: NOT RUN.

## N6: Internal DNS lookup fails

**Symptoms:** HTTP by server IP works; fs01.lab.example.test fails.

**Likely causes:** Wrong client DNS, missing A record, DNS service down, ACL or wrong search suffix.

**Diagnostic commands:** `ipconfig /all; nslookup fs01.lab.example.test 10.10.40.10; nslookup fs01.lab.example.test`

**Investigation:** Compare explicit DNS query with the default query. Check the DNS model record and service; do not change routing if IP/service works.

**Scenario root cause:** In this injected scenario HR DHCP advertises public-model DNS 198.51.100.10 instead of internal .40.10.

**Corrective action:** Correct the HR DHCP DNS option, renew and flush the Windows client DNS cache where supported.

**Verification:** Default and explicit queries return .40.11; HTTP by name succeeds. Track B also requires SRV lookup before domain join.

**Rollback/evidence:** Reopen the saved baseline if recovery fails. Record before/after configuration, actual output, date, simulator version and commit. Result: NOT RUN.
