# 07: Windows startup and apps are slow

Status: **Simulation / not executed**. All accounts and incidents are synthetic.

## Impact and priority
User productivity degraded; investigate evidence before recommending a hardware purchase.

## Symptoms
CL01 has limited free memory and sustained resource contention after sign-in.

## Controlled fault injection
Use a VM snapshot with a documented small RAM allocation and ordinary trusted applications; avoid resource-exhaustion scripts or filling the host disk.

## Diagnostic steps
1. Collect Get-SystemInventory output and Task Manager observations.
2. Compare memory use, disk active time, free space, uptime and startup apps.
3. Check System/Application events and recent changes; CPU percentage alone does not establish the cause.

## Scenario root cause
In this scenario the VM is undersized for the workload, confirmed by sustained memory pressure. Do not label every slow PC as a RAM problem.

## Resolution
Close unnecessary lab apps, disable only approved nonessential startup entries, or increase VM RAM within host capacity while powered down.

## Verification
Repeat the same application workflow and record actual before/after observations; do not invent timing or percentage improvements.

## Rollback and evidence
Restore the original VM allocation/startup list if the change causes issues; preserve the measured comparison.

Observed result: **pending operator execution**. Record host/tool versions, exact commands, before/after evidence and any difference from the expected result.
