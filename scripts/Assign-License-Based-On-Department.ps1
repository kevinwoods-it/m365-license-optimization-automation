<#
.SYNOPSIS
    Assigns Microsoft 365 licenses based on Entra ID department attribute.

.DESCRIPTION
    Connects to Microsoft Graph, reads all users, maps department to
    license SKU, assigns the correct license, and logs all actions.
    Designed to run as a scheduled task or on-demand after user provisioning.

.NOTES
    Author  : Kevin Woods
    Version : 1.0
    Requires: Microsoft.Graph PowerShell module
    Scopes  : User.ReadWrite.All, Organization.Read.All
#>

#region Setup — Logging
# All actions write to a timestamped log file
# This means you have an audit trail of every license change
$logPath = '.\LicenseAssignment_' + (Get-Date -Format 'yyyyMMdd_HHmm') + '.log'

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  [$Level]  $Message"
    $entry | Out-File -FilePath $logPath -Append -Encoding utf8
    Write-Host $entry
}
#region Connect to Microsoft Graph
Write-Log 'Connecting to Microsoft Graph...'

try {
    Connect-MgGraph -Scopes 'User.ReadWrite.All', 'Organization.Read.All' -ErrorAction Stop
    Write-Log 'Connected to Microsoft Graph successfully.'
} catch {
    Write-Log "Failed to connect to Microsoft Graph: $($_.Exception.Message)" 'ERROR'
    exit 1
}

#endregion

#region License SKU Map
# Retrieve license SKUs from the tenant
# SkuPartNumber is the internal name Microsoft uses for each license
# E5 = ENTERPRISEPREMIUM, E3 = ENTERPRISEPACK, F3 = SPE_F1

Write-Log 'Retrieving license SKUs from tenant...'

$allSkus = Get-MgSubscribedSku

$licenseMap = @{
    'IT'          = ($allSkus | Where-Object SkuPartNumber -eq 'ENTERPRISEPREMIUM').SkuId
    'Finance'     = ($allSkus | Where-Object SkuPartNumber -eq 'ENTERPRISEPACK').SkuId
    'HR'          = ($allSkus | Where-Object SkuPartNumber -eq 'ENTERPRISEPACK').SkuId
    'Corporate'   = ($allSkus | Where-Object SkuPartNumber -eq 'ENTERPRISEPACK').SkuId
    'Call Center' = ($allSkus | Where-Object SkuPartNumber -eq 'ENTERPRISEPACK').SkuId
    'Factory'     = ($allSkus | Where-Object SkuPartNumber -eq 'SPE_F1').SkuId
    'Logistics'   = ($allSkus | Where-Object SkuPartNumber -eq 'SPE_F1').SkuId
    'Contractor'  = ($allSkus | Where-Object SkuPartNumber -eq 'SPE_F1').SkuId
}

Write-Log "License map built — $($licenseMap.Count) department rules loaded."
#endregion

#region Process Users
Write-Log 'Retrieving all users from Entra ID...'

$users = Get-MgUser -All -Property Id, DisplayName, Department,
    UserPrincipalName, AssignedLicenses, AccountEnabled

# Only process enabled accounts — skip disabled users
$activeUsers = $users | Where-Object { $_.AccountEnabled -eq $true }
Write-Log "Found $($activeUsers.Count) active users to process."

$assigned = 0
$skipped  = 0
$errors   = 0

foreach ($user in $activeUsers) {

    $dept = $user.Department

    # Look up the correct SKU ID for this user's department
    if (-not $licenseMap.ContainsKey($dept)) {
        Write-Log "SKIPPED: $($user.DisplayName) — department '$dept' has no license rule." 'WARN'
        $skipped++
        continue
    }

    $targetSkuId = $licenseMap[$dept]

    # Check if user already has the correct license — skip if so
    $currentSkuIds = $user.AssignedLicenses | Select-Object -ExpandProperty SkuId
    if ($currentSkuIds -contains $targetSkuId) {
        Write-Log "UNCHANGED: $($user.DisplayName) already has correct license."
        continue
    }

    try {
        Set-MgUserLicense ``
            -UserId        $user.Id ``
            -AddLicenses   @{ SkuId = $targetSkuId } ``
            -RemoveLicenses @()

        Write-Log "ASSIGNED: $($user.DisplayName) [$dept] -> license SkuId $targetSkuId"
        $assigned++
    } catch {
        Write-Log "ERROR: $($user.DisplayName) — $($_.Exception.Message)" 'ERROR'
        $errors++
    }
}
#endregion

#region Summary
Write-Log '--- Assignment Summary ---'
Write-Log "Assigned : $assigned"
Write-Log "Skipped  : $skipped  (no department rule or already correct)"
Write-Log "Errors   : $errors"
Write-Log "Log file : $logPath"
#endregion
