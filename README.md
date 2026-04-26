---

## Scripts

| Script | Purpose |
|--------|---------|
| Assign-License-Based-On-Department.ps1 | Assigns correct M365 license based on Entra ID department attribute |
| Generate-License-Report.ps1 | Exports full license inventory to CSV for audit and reporting |
| Remove-UnusedLicenses.ps1 | Identifies and removes licenses from disabled or unlicensed accounts |
| Get-LicenseCostSummary.ps1 | Calculates estimated monthly licensing cost across the tenant |

---

## Key Design Decisions

**Why department attribute instead of group membership?**
Department is a core Entra ID attribute populated during user provisioning.
Using it as the license trigger means new users get the correct license
automatically the moment their account is created — no manual group
assignment required.

**Why not group-based licensing?**
Azure AD group-based licensing is a valid alternative and simpler for
smaller environments. This script-based approach was chosen to give the
IT team visibility into every assignment decision through logging, and to
support environments where group-based licensing is not available on the
current license tier.

**Why F3 for frontline workers?**
Microsoft 365 F3 is designed for frontline workers —
Teams access, shift scheduling, mobile apps. It does not include full
desktop Office but covers everything a factory worker or driver needs.
At $8/user vs $57/user, the cost difference for 400 frontline users is
$235,200/year — the single largest driver of savings in this scenario.

---

## Business Outcomes

- Annual licensing cost reduced from $478,800 to $180,600
- 62% cost reduction — $298,200 in annual savings
- License assignment standardized and automated — no manual provisioning errors
- Audit-ready CSV report generated on demand for compliance reviews
- New user licensing handled automatically at account creation
- IT administrative workload for license management reduced significantly

---

## References
- [Microsoft Graph PowerShell SDK](https://learn.microsoft.com/en-us/powershell/microsoftgraph/)
- [Microsoft 365 Licensing Overview](https://learn.microsoft.com/en-us/microsoft-365/admin/subscriptions-and-billing/licenses)
- [Microsoft 365 F3 for Frontline Workers](https://www.microsoft.com/en-us/microsoft-365/enterprise/f3)
- [Entra ID User Properties](https://learn.microsoft.com/en-us/entra/fundamentals/how-to-manage-user-profile-info)

