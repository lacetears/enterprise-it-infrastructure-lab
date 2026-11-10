# Dependency-free assertions. AD functions below are test doubles, never a live domain.
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$passed=0
function Assert-True($Condition,[string]$Message) { if (-not $Condition) { throw $Message }; $script:passed++; Write-Output "PASS: $Message" }
function Assert-Throws([scriptblock]$Action,[string]$Message) { $threw=$false;try { &$Action | Out-Null } catch { $threw=$true }; Assert-True $threw $Message }
$syntaxCount=0
Get-ChildItem $root -Recurse -Include *.ps1,*.psm1 | ForEach-Object {
    $tokens=$null;$errors=$null
    $null=[System.Management.Automation.Language.Parser]::ParseFile($_.FullName,[ref]$tokens,[ref]$errors)
    if ($errors.Count) { throw ($errors | Out-String) }
    $syntaxCount++
}
Write-Output "Parsed $syntaxCount PowerShell files."
Import-Module "$root/scripts/Lab.Common.psm1" -Force
$users=@(Read-LabUsers "$root/config/users.example.csv")
Assert-True ($users.Count -eq 2) 'Valid CSV has two users'
$tmp=Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
$null=New-Item -ItemType Directory $tmp
try {
    $csv=Join-Path $tmp 'input.csv'
    foreach ($case in @(
        @{Name='duplicate';Body="SamAccountName,GivenName,Surname,Department`naaa,Alex,Rivera,Support`naaa,Alex,Rivera,Support"},
        @{Name='unknown department';Body="SamAccountName,GivenName,Surname,Department`naaa,Alex,Rivera,Executives"},
        @{Name='filter injection';Body="SamAccountName,GivenName,Surname,Department`na'bad,Alex,Rivera,Support"},
        @{Name='missing column';Body="SamAccountName,GivenName,Surname`naaa,Alex,Rivera"},
        @{Name='password column';Body="SamAccountName,GivenName,Surname,Department,Password`naaa,Alex,Rivera,Support,nope"},
        @{Name='empty file';Body=''},
        @{Name='empty surname';Body="SamAccountName,GivenName,Surname,Department`naaa,Alex,,Support"}
    )) {
        Set-Content -LiteralPath $csv -Value $case.Body
        Assert-Throws { Read-LabUsers $csv } "Reject $($case.Name)"
    }
    Assert-Throws { Read-LabUsers (Join-Path $tmp 'missing.csv') } 'Reject nonexistent file'
    $plan=@(& "$root/scripts/New-LabUsers.ps1" -CsvPath "$root/config/users.example.csv")
    Assert-True ($plan.Count -eq 2 -and $plan[0].Action -like 'Plan*') 'Default provisioning is offline plan'
    $xml='<Event xmlns="http://schemas.microsoft.com/win/2004/08/events/event"><System><EventID>4625</EventID><TimeCreated SystemTime="2026-01-01T01:00:00+01:00"/></System><EventData><Data Name="TargetUserName">synthetic.user</Data><Data Name="IpAddress">192.0.2.10</Data></EventData></Event>'
    $event=Convert-LabEvent $xml
    Assert-True ($event.EventId -eq 4625 -and $event.User -eq 'synthetic.user') 'Event fields mapped by name'
    Assert-True ($event.TimeUtc -like '2026-01-01T00:00:00*') 'Event time normalized to UTC'
    Assert-True ($null -eq $event.CallerComputer) 'Missing optional field remains null'
    Assert-Throws { Convert-LabEvent '<Event/>' } 'Reject missing event system fields'
    Assert-Throws { Convert-LabEvent '<!DOCTYPE x [<!ENTITY a "x">]><Event>&a;</Event>' } 'Reject XML DTD'
    # Only AD is mocked. Import the common module normally.
    function Import-Module { param($Name,[switch]$Force) if ($Name -ne 'ActiveDirectory') { Microsoft.PowerShell.Core\Import-Module $Name -Force:$Force } }
    function Get-ADDomain { [pscustomobject]@{DNSRoot=$global:LabTest_mockDomain} }
    function Get-ADOrganizationalUnit { param($Identity) [pscustomobject]@{DistinguishedName=$Identity} }
    function Get-ADGroup { param($Identity) if ($global:LabTest_missingGroup) { throw 'Group unavailable' }; [pscustomobject]@{Name=$Identity} }
    function Get-ADUser { param($Filter) if ($global:LabTest_existing) { [pscustomobject]@{SamAccountName='existing'} } }
    function New-ADUser {
        param($Name,$GivenName,$Surname,$DisplayName,$SamAccountName,$UserPrincipalName,$Department,$Path,$Enabled,[switch]$PassThru)
        $global:LabTest_created++; if ($Enabled) { throw 'Must remain disabled' }; [pscustomobject]@{SamAccountName=$SamAccountName}
    }
    function Add-ADGroupMember { param($Identity,$Members) $global:LabTest_added++; if ($global:LabTest_groupFailure) { throw 'Synthetic group failure' } }
    $global:LabTest_mockDomain='lab.example.test';$global:LabTest_created=0;$global:LabTest_added=0;$global:LabTest_existing=$false;$global:LabTest_missingGroup=$false;$global:LabTest_groupFailure=$false
    & "$root/scripts/New-LabUsers.ps1" -CsvPath "$root/config/users.example.csv" -Apply -WhatIf | Out-Null
    Assert-True ($global:LabTest_created -eq 0 -and $global:LabTest_added -eq 0) 'WhatIf makes zero AD mutations'
    $result=@(& "$root/scripts/New-LabUsers.ps1" -CsvPath "$root/config/users.example.csv" -Apply)
    Assert-True ($global:LabTest_created -eq 2 -and $global:LabTest_added -eq 2 -and $result[0].Result -eq 'CreatedDisabled') 'Provisioning calls create-disabled then group-add'
    $global:LabTest_existing=$true
    & "$root/scripts/New-LabUsers.ps1" -CsvPath "$root/config/users.example.csv" -Apply | Out-Null
    Assert-True ($global:LabTest_created -eq 2) 'Existing users are not modified'
    $global:LabTest_existing=$false;$global:LabTest_mockDomain='production.example.com'
    Assert-Throws { & "$root/scripts/New-LabUsers.ps1" -CsvPath "$root/config/users.example.csv" -Apply } 'Wrong domain rejected'
    $global:LabTest_mockDomain='lab.example.test';$global:LabTest_missingGroup=$true
    Assert-Throws { & "$root/scripts/New-LabUsers.ps1" -CsvPath "$root/config/users.example.csv" -Apply } 'Missing group fails preflight'
    Assert-True ($global:LabTest_created -eq 2) 'Failed preflight makes no accounts'
    $global:LabTest_missingGroup=$false;$global:LabTest_groupFailure=$true
    Assert-Throws { & "$root/scripts/New-LabUsers.ps1" -CsvPath "$root/config/users.example.csv" -Apply } 'Partial failure ends with terminating error'
} finally { Remove-Item -LiteralPath $tmp -Recurse -Force }
Write-Output "Passed $passed assertions; AD calls were mocked. Windows integration was NOT tested."
