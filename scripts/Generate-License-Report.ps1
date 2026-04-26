
<#
.SYNOPSIS
    Generates a Microsoft 365 license inventory report.

.DESCRIPTION
    Exports all user license assignments to a timestamped CSV file.
    Includes license name translation so the report is human-readable
    without requiring the reviewer to know internal SKU IDs.
#>

Connect-MgGraph -Scopes 'User.Read.All', 'Organization.Read.All'

# Build SKU ID to friendly name lookup
# This translates internal GUIDs to readable names in the report
$skuLookup = @{}
Get-MgSubscribedSku | ForEach-Object {
    $skuLookup[$_.SkuId] = switch ($_.SkuPartNumber) {
        'ENTERPRISEPREMIUM' { 'Microsoft 365 E5' }
        'ENTERPRISEPACK'    { 'Microsoft 365 E3' }
        'SPE_F1'            { 'Microsoft 365 F3' }
        default             { $_.SkuPartNumber }
    }
}

$users = Get-MgUser -All -Property DisplayName, UserPrincipalName,
    Department, AssignedLicenses, AccountEnabled

$report = foreach ($user in $users) {

    # Translate SKU IDs to friendly names for each assigned license
    $licenseNames = $user.AssignedLicenses |
        ForEach-Object { $skuLookup[$_.SkuId] ?? $_.SkuId } |
        Where-Object { $_ } |
        Join-String -Separator ' | '

    [PSCustomObject]@{
        DisplayName       = $user.DisplayName
        UserPrincipalName = $user.UserPrincipalName
        Department        = $user.Department
        AccountEnabled    = $user.AccountEnabled
        LicenseCount      = $user.AssignedLicenses.Count
        AssignedLicenses  = $licenseNames
    }
}

$reportPath = '.\M365-License-Report_' + (Get-Date -Format 'yyyyMMdd') + '.csv'
$report | Sort-Object Department, DisplayName |
    Export-Csv -Path $reportPath -NoTypeInformation

Write-Host "License report exported: $reportPath" -ForegroundColor Green
Write-Host "Total users: $($report.Count)"
Write-Host "Licensed  : $(($report | Where-Object LicenseCount -gt 0).Count)"
Write-Host "Unlicensed: $(($report | Where-Object LicenseCount -eq 0).Count)"
