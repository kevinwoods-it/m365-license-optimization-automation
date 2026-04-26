
<#
.SYNOPSIS
    Calculates estimated monthly Microsoft 365 licensing cost.

.DESCRIPTION
    Maps assigned license SKUs to approximate monthly per-user costs
    and produces a cost summary by license tier and department.
    Output can be used for management reporting and cost justification.
#>

Connect-MgGraph -Scopes 'User.Read.All', 'Organization.Read.All'

# Approximate monthly per-user costs (USD) — update to match your agreement
$costPerLicense = @{
    'ENTERPRISEPREMIUM' = 57    # M365 E5
    'ENTERPRISEPACK'    = 36    # M365 E3
    'SPE_F1'            = 8     # M365 F3
}

$skuDetails = Get-MgSubscribedSku
$users = Get-MgUser -All -Property DisplayName, Department, AssignedLicenses

$summary = foreach ($user in $users) {
    foreach ($lic in $user.AssignedLicenses) {
        $sku = $skuDetails | Where-Object SkuId -eq $lic.SkuId
        $cost = $costPerLicense[$sku.SkuPartNumber] ?? 0
        [PSCustomObject]@{
            Department   = $user.Department
            LicenseName  = switch ($sku.SkuPartNumber) {
                'ENTERPRISEPREMIUM' { 'M365 E5' }
                'ENTERPRISEPACK'    { 'M365 E3' }
                'SPE_F1'            { 'M365 F3' }
                default             { $sku.SkuPartNumber }
            }
            MonthlyCost  = $cost
        }
    }
}

# Group by license and show count and total monthly cost
Write-Host "`n--- License Cost Summary ---" -ForegroundColor Cyan
$summary | Group-Object LicenseName | ForEach-Object {
    $total = ($_.Group | Measure-Object MonthlyCost -Sum).Sum
    [PSCustomObject]@{
        License      = $_.Name
        UserCount    = $_.Count
        MonthlyCost  = "`$$total"
        AnnualCost   = "`$" + ($total * 12)
    }
} | Format-Table -AutoSize

$grandTotal = ($summary | Measure-Object MonthlyCost -Sum).Sum
Write-Host "Total Monthly Cost  : `$$grandTotal" -ForegroundColor Yellow
Write-Host "Total Annual Cost   : `$($grandTotal * 12)" -ForegroundColor Yellow
