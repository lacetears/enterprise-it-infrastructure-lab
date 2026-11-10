# 03: User repeatedly locks out

Status: **Simulation / not executed**. All accounts and incidents are synthetic.

## Impact and priority
One user blocked: normal; widespread lockouts or suspicious source activity needs security escalation.

## Symptoms
A disposable user is locked shortly after an administrator unlocks it.

## Controlled fault injection
On an isolated lab only, scope a temporary fine-grained policy with a documented small lockout threshold to a disposable test group. Use that account for repeated incorrect network authentication; do not use an administrator or spray multiple accounts. Record and remove the test policy after the exercise.

## Diagnostic steps
1. Confirm LockedOut via Get-ADUser -Properties LockedOut.
2. On DC01 inspect 4740 TargetUserName and CallerComputerName.
3. On that endpoint inspect 4625 and saved credentials, scheduled tasks and mapped connections; audit settings must be enabled.

## Scenario root cause
A stale stored credential or a controlled repeated bad-password test is retrying from the recorded endpoint. Confirm the caller rather than assuming an attack.

## Resolution
Stop the retry source, remove only the affected stored credential using Credential Manager, and unlock the authorized disposable user with Unlock-ADAccount.

## Verification
Fresh sign-in succeeds; observe beyond the retry interval and confirm there are no new 4740 records for that user.

## Rollback and evidence
Remove the temporary fine-grained policy/test group assignment; retain only redacted event fields, not passwords.

Observed result: **pending operator execution**. Record host/tool versions, exact commands, before/after evidence and any difference from the expected result.
