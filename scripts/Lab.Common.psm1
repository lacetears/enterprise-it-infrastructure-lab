Set-StrictMode -Version Latest
function Read-LabUsers {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "CSV file not found: $Path" }
    $rows = @(Import-Csv -LiteralPath $Path -ErrorAction Stop)
    if ($rows.Count -eq 0) { throw 'CSV must contain at least one user.' }
    $required = @('SamAccountName','GivenName','Surname','Department')
    foreach ($name in $required) {
        if ($rows[0].PSObject.Properties.Name -notcontains $name) { throw "Missing CSV column: $name" }
    }
    if (@($rows[0].PSObject.Properties.Name).Count -ne $required.Count) { throw 'Unexpected CSV columns; passwords and arbitrary OUs are not accepted.' }
    $seen = @{}
    foreach ($row in $rows) {
        foreach ($field in $required) { $row.$field = ([string]$row.$field).Trim() }
        if ($row.SamAccountName -cnotmatch '^[a-z][a-z0-9.]{2,19}$') { throw "Invalid account name: $($row.SamAccountName)" }
        if ($seen.ContainsKey($row.SamAccountName)) { throw "Duplicate account: $($row.SamAccountName)" }
        $seen[$row.SamAccountName] = $true
        foreach ($field in @('GivenName','Surname')) {
            if ($row.$field.Length -lt 1 -or $row.$field.Length -gt 60 -or $row.$field -match '[,=+<>;"\\\x00-\x1f]') { throw "Invalid $field for $($row.SamAccountName)" }
        }
        if ($row.Department -notin @('Operations','Support')) { throw "Unknown department: $($row.Department)" }
    }
    return $rows
}
function Convert-LabEvent {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Xml)
    # Reject DTD/entity expansion; named EventData fields are independent of display language.
    $settings = New-Object System.Xml.XmlReaderSettings
    $settings.DtdProcessing = [System.Xml.DtdProcessing]::Prohibit
    $settings.XmlResolver = $null
    $reader = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($Xml)), $settings)
    try { $doc = New-Object System.Xml.XmlDocument; $doc.XmlResolver=$null; $doc.Load($reader) }
    finally { $reader.Dispose() }
    $data = @{}
    foreach ($node in $doc.SelectNodes("//*[local-name()='EventData']/*[local-name()='Data']")) { $data[$node.GetAttribute('Name')] = $node.InnerText }
    $idNode = $doc.SelectSingleNode("//*[local-name()='System']/*[local-name()='EventID']")
    $timeNode = $doc.SelectSingleNode("//*[local-name()='System']/*[local-name()='TimeCreated']")
    if (-not $idNode -or -not $timeNode) { throw 'Event XML requires EventID and TimeCreated.' }
    $time = [DateTimeOffset]::Parse($timeNode.GetAttribute('SystemTime'), [Globalization.CultureInfo]::InvariantCulture)
    [pscustomobject]@{ EventId=[int]$idNode.InnerText; TimeUtc=$time.UtcDateTime.ToString('o'); User=$data['TargetUserName']; SourceIp=$data['IpAddress']; CallerComputer=$data['CallerComputerName']; Status=$data['Status']; LogonType=$data['LogonType'] }
}
Export-ModuleMember -Function Read-LabUsers,Convert-LabEvent
