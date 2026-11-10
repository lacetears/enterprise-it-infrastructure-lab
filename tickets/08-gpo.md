# 08: Workstation idle-lock policy does not apply

Status: **Simulation / not executed**. All accounts and incidents are synthetic.

## Impact and priority
Security configuration issue; scope the correction before broadening GPO links.

## Symptoms
CL01 does not appear in the intended workstation GPO results.

## Controlled fault injection
Move CL01 from Lab/Workstations to the default Computers container using AD Users and Computers; record its original DN first.

## Diagnostic steps
1. Run gpresult /r /scope computer elevated and inspect GroupPolicy Operational events.
2. Check the computer object location, GPO link, enabled status, filtering and DNS connectivity.
3. Distinguish user policy from computer policy.

## Scenario root cause
The computer is outside the OU to which LAB-Workstation-Inactivity is linked.

## Resolution
Move only CL01 back to Lab/Workstations; run gpupdate /force and restart if requested.

## Verification
The GPO appears in resultant policy, InactivityTimeoutSecs equals 900, and the workstation actually locks after the configured idle period.

## Rollback and evidence
Restore the original OU if the exercise is aborted; do not link workstation policy to Domain Controllers.

Observed result: **pending operator execution**. Record host/tool versions, exact commands, before/after evidence and any difference from the expected result.
