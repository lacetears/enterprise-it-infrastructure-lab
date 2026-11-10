# 09: Operations user gets access denied

Status: **Simulation / not executed**. All accounts and incidents are synthetic.

## Impact and priority
Access request requires business authorization; reachability is not authorization.

## Symptoms
The user can resolve and reach FS01 but cannot modify the Operations share.

## Controlled fault injection
Remove only the disposable Operations account from GG_Operations, after recording membership, then sign out/in to refresh its token.

## Diagnostic steps
1. Confirm TCP 445 and correct UNC path.
2. Inspect whoami /groups, Get-ADGroupMember, Get-SmbShareAccess and icacls.
3. Compare effective share and NTFS permissions, inherited ACEs and explicit denies.

## Scenario root cause
The user is missing the role group that nests into the share permission group. A stale logon token can preserve the symptom after membership is repaired.

## Resolution
Restore GG_Operations membership and start a fresh user session. Preserve the AGDLP structure; do not grant the user direct Full Control.

## Verification
Operations user can create/read/delete a disposable test file; Support user is still denied after fresh sign-in.

## Rollback and evidence
Restore recorded memberships only; keep a redacted effective-access comparison.

Observed result: **pending operator execution**. Record host/tool versions, exact commands, before/after evidence and any difference from the expected result.
