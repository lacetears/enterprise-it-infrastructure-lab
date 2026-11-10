# 06: Approved MSI will not install

Status: **Simulation / not executed**. All accounts and incidents are synthetic.

## Impact and priority
Routine software request; escalate licensing/security or package-integrity concerns.

## Symptoms
An approved training package fails for a standard user.

## Controlled fault injection
Use a trusted, licensed, nonessential MSI in a disposable CL01 snapshot. Record vendor URL, version and hash locally. Attempt installation without elevated rights; do not download arbitrary installers or intentionally install vulnerable software.

## Diagnostic steps
1. Record the exact installer error and package provenance.
2. Check architecture, disk space and elevation requirements.
3. Run msiexec /i "C:\Lab\approved.msi" /L*v "C:\Windows\Temp\lab-install.log" using authorized admin credentials; inspect the log around Return value 3 if it fails.

## Scenario root cause
For this scenario the package requires machine-wide installation rights. Other MSI failures need their own log-supported diagnosis.

## Resolution
Install only the approved package with authorized elevation. Do not grant permanent local-admin rights or disable antivirus/UAC.

## Verification
Confirm exit status (including 3010 reboot-required), installed version, and launch/functionality from the original standard-user session.

## Rollback and evidence
Use the vendor uninstall procedure or restore the VM snapshot; remove installer logs only under the lab retention process after review.

Observed result: **pending operator execution**. Record host/tool versions, exact commands, before/after evidence and any difference from the expected result.
