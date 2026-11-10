# 10: Local print jobs remain queued

Status: **Simulation / not executed**. All accounts and incidents are synthetic.

## Impact and priority
Normal priority unless a shared business-critical printer affects many users.

## Symptoms
An approved printer is reachable but jobs do not leave the Windows queue.

## Controlled fault injection
Use an installed, authorized lab printer if available. Stop the local Spooler on CL01 only, after confirming no real work is queued. Without a printer, validate service behavior only and mark printing untested.

## Diagnostic steps
1. Identify the exact queue, driver, port and intended device address.
2. Check Get-Printer, Get-PrinterPort and Get-Service Spooler.
3. Check device reachability and the actual printing protocol; do not assume every printer uses TCP 9100.

## Scenario root cause
In this controlled scenario the local Print Spooler service is stopped. An offline device, wrong port or bad driver would need a different resolution.

## Resolution
Preview Invoke-LabMaintenance.ps1 -Action RestartSpooler -WhatIf, then apply to CL01 with confirmation. Do not purge all jobs or reinstall drivers without further evidence.

## Verification
Spooler is Running; an actual test page completes when hardware is available. A running service alone is not proof that printing works.

## Rollback and evidence
Restore initial service state only if appropriate for the exercise; document queued work and actual test-page outcome.

Observed result: **pending operator execution**. Record host/tool versions, exact commands, before/after evidence and any difference from the expected result.
