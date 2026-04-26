<#
.SYNOPSIS
    Removes Microsoft 365 licenses from disabled Entra ID accounts.

.DESCRIPTION
    Disabled accounts that still hold licenses are one of the most
    common sources of M365 licensing waste. This script finds them,
    removes all licenses, and logs what was recovered.

    Run with -WhatIf to preview changes before executing.
#>

param(
    [switch]$WhatIf = $false
)

Connect-MgGraph -Scopes 'User.ReadWrite.All'

$disabledWithLicenses = Get-MgUser -All ``
    -Property Id, DisplayName, UserPrincipalName, AccountEnabled, AssignedLicenses |
    Where-Object { $_.AccountEnabled -eq $false -and $_.AssignedLicenses.Count -gt 0 }

Write-Host "Disabled accounts with active licenses: $($disabledWithLicenses.Count)"

foreach ($user in $disabledWithLicenses) {

    $skuIds = $user.AssignedLicenses | Select-Object -ExpandProperty SkuId

    if ($WhatIf) {
        Write-Host "[WHATIF] Would remove $($skuIds.Count) license(s) from: $($user.DisplayName)"
    } else {
        try {
            Set-MgUserLicense ``
                -UserId         $user.Id ``
                -AddLicenses    @() ``
                -RemoveLicenses $skuIds
            Write-Host "Removed $($skuIds.Count) license(s) from: $($user.DisplayName)" -ForegroundColor Green
        } catch {
            Write-Host "ERROR for $($user.DisplayName): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}
