# Microsoft 365 License Optimization Automation

## Overview

This repository documents the automation used to optimize Microsoft 365
licensing for a mid-sized organization of approximately 700 employees
using Microsoft Graph PowerShell.

The organization previously assigned **Microsoft 365 E5 licenses to all
users** regardless of role, resulting in significant licensing waste.
This solution implements role-based license assignment automation to ensure
users receive only the licenses their job function requires.

---

## The Business Problem

| Metric | Value |
|--------|-------|
| Total Users | 700 |
| Previous License | Microsoft 365 E5 (all users) |
| E5 Monthly Cost | $57/user |
| Previous Annual Cost | **$478,800** |

Many frontline users — factory workers, truck drivers, call center staff,
and contractors — did not require:
- Advanced Security & Compliance features
- Power BI Pro
- Advanced Threat Protection
- Full desktop Office suite

Assigning E5 to these users was pure licensing waste.

---

## Optimized Licensing Strategy

Users were segmented by department and job function:

| Department | Users | Role Profile | License | Monthly Cost/User |
|------------|-------|-------------|---------|------------------|
| IT | 50 | Power users, admin tools, security | E5 | $57 |
| Finance | 50 | Full productivity, compliance | E3 | $36 |
| HR | 30 | Full productivity, compliance | E3 | $36 |
| Corporate | 70 | Full productivity suite | E3 | $36 |
| Call Center | 100 | Basic productivity, Teams | E3 | $36 |
| Factory | 200 | Frontline, shift scheduling | F3 | $8 |
| Logistics | 100 | Frontline, mobile access | F3 | $8 |
| Contractor | 100 | Basic access only | F3 | $8 |

---

## Financial Impact

| | Before | After | Savings |
|--|--------|-------|---------|
| Monthly Cost | $39,900 | $15,050 | $24,850 |
| Annual Cost | $478,800 | $180,600 | **$298,200** |

> A 62% reduction in Microsoft 365 licensing costs achieved through
> role-based assignment automation — without reducing user productivity.
> The largest savings driver: 400 frontline users moved from E5 ($57)
> to F3 ($8), saving $49/user/month across that group alone.

---

## Architecture

```
Microsoft Entra ID (user directory + department attributes)
        |
        | Microsoft Graph API
        v
PowerShell Automation Scripts
  |
  +-- Read department attribute from Entra ID
  +-- Map department to license SKU
  +-- Assign correct license
  +-- Remove over-assigned licenses
  +-- Generate audit report (CSV)
        |
        v
License Report (.csv) --> IT Admin Review --> Cost Reporting
```
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
