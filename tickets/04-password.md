# 04: Forgotten password after identity verification

Status: **Simulation / not executed**. All accounts and incidents are synthetic.

## Impact and priority
Identity-sensitive request; prioritize verification over speed.

## Symptoms
User cannot sign in and requests a reset.

## Controlled fault injection
Use only a disposable account. Simulate a forgotten password in the ticket narrative; no identity evidence or real personal information is needed.

## Diagnostic steps
1. Verify the caller using an approved separate identity-verification process; a username alone is insufficient.
2. Distinguish disabled, expired-password and locked-out states.
3. Confirm the account and delegated reset rights before changing it.

## Scenario root cause
The user no longer knows the current password; the account otherwise exists and is permitted to sign in.

## Resolution
Read a unique temporary password using Read-Host -AsSecureString; use Set-ADAccountPassword -Reset -ErrorAction Stop, then Set-ADUser -ChangePasswordAtLogon $true. Unlock only if needed and authorized. Do not enable a deliberately deactivated user.

## Verification
At the VM console the user changes the temporary password, then signs in with the new password. Never record the password in the ticket or screenshot.

## Rollback and evidence
No restoration of an old plaintext password. Document completion time and notification through the approved channel; clear the local password variable.

Observed result: **pending operator execution**. Record host/tool versions, exact commands, before/after evidence and any difference from the expected result.
