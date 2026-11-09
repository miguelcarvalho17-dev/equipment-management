# Equipment Management for Business Central

A Microsoft Dynamics 365 Business Central extension (AL) to register company equipment, track who uses it, and keep maintenance and warranty information in one place.

> **Status:** V1 is built and V2 is in development. Nothing here is released yet.

## The problem

Companies hand out equipment to their employees every day:

- Laptops, cell phones and tablets
- Monitors and other peripherals
- Tools
- Vehicles
- Industrial equipment

In most companies this information lives in **Excel spreadsheets** that are scattered across departments. As a result:

- Nobody knows for sure **who has which item**, or where it is.
- **Maintenance** is forgotten or done late because nothing reminds anyone.
- **Warranties** expire unnoticed, so repairs that should have been free get paid for.
- When an employee leaves, getting their equipment back is a manual, error-prone checklist.
- The data is not connected to the ERP, so it can't be reported on or secured like the rest of the business data.

## The solution

Equipment Management brings this into Business Central, where the people, permissions and reports already live.

## Version 1 (MVP)

### Project objective

The Equipment Management application enables organizations to register, track, and manage company-owned equipment assigned to employees.

The initial release (V1) focuses on equipment registration, categorization, employee assignment tracking, and management visibility through dashboards and KPIs.

### Scope of V1

| Capability | What it gives you |
|---|---|
| **Register equipment** | A central equipment register with serial numbers and key details |
| **Categorize equipment** | Categories such as laptops, phones, vehicles or tools |
| **Track assignments** | Who uses each item now, with a history of previous assignments |
| **Dashboards and KPIs** | Management visibility into the equipment base and how it is assigned |

### Roadmap (after V1)

These address the rest of the problem above and are planned for later versions:

- Maintenance schedules and records
- Warranty tracking
- Location tracking
- Automatic alerts for overdue maintenance and expiring warranties (via Job Queue)

Out of scope for now: depreciation and fixed-asset accounting, purchasing workflows, and mobile or barcode scanning.

## Version 2

### Project objective

The V2 release extends the Equipment Management solution by introducing maintenance management, warranty tracking, automated notifications, and equipment lifecycle monitoring.

The objective is to ensure that equipment remains operational, warranty coverage is monitored proactively, and managers are notified of upcoming actions requiring attention.

### Scope of V2

| Capability | What it gives you |
|---|---|
| **Maintenance management** | Maintenance records and history for each item of equipment, an automatic In Maintenance status that blocks assignment while work is open, and maintenance cost tracking (totals, averages, cost by category and by equipment) |
| **Warranty tracking** | Warranty coverage per item, monitored before it expires |
| **Automated notifications** | Managers are alerted to upcoming actions that need attention |
| **Lifecycle monitoring** | Visibility of equipment across its life, from purchase to disposal |

### V2 progress

| Capability | State |
|---|---|
| Maintenance registration, history, equipment status and cost tracking (FR-010 to FR-013) | Built, not yet verified in a Business Central sandbox |
| Automated background processing, daily job queue entries for warranty alerts and overdue maintenance (FR-018) | Built, not yet verified in a Business Central sandbox |
| Maintenance schedules | Planned |
| Warranty tracking | Planned |
| Automated notifications | Planned |
| Lifecycle monitoring | Planned |

Feature documentation is in `docs/features/`, user help in `docs/help/` and the change history in `CHANGELOG.md`.

### Roadmap (after V2)

- Location tracking

Out of scope for now: depreciation and fixed-asset accounting, purchasing workflows, and mobile or barcode scanning.

## Technical overview

- **Platform:** Business Central 29, AL runtime 18.0
- **Layout:** `app/` (the extension) and `test/` (automated tests, depends on `app/`)
- **Extensibility:** extends Business Central only through events and extension objects. No base application objects are modified.
- **Object prefix:** `EQM`

## Getting started

1. Install the AL Language extension for VS Code.
2. Open `app/` in VS Code, then run **AL: Download Symbols** against your sandbox.
3. Press `F5` to publish to your sandbox, or use **AL: Package** to build the `.app`.

## License

[MIT](LICENSE)
