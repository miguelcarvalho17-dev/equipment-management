# Equipment Management for Business Central

A Microsoft Dynamics 365 Business Central extension (AL) to register company equipment, track who uses it, and keep maintenance and warranty information in one place.

> **Status:** V1 and V2 are built (all V2 GitHub issues are closed) and V3 is planned (requirements written, issues FR-023 to FR-041 created). Nothing has been verified in a Business Central sandbox and nothing is released yet.

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

### V2 status

V2 is complete: all requirements in the V2 milestone are built and merged.

| Capability | Requirements | State |
|---|---|---|
| Maintenance management (registration, history, equipment status, cost tracking, planned and overdue maintenance, maintenance dashboard) | FR-010 to FR-013, FR-019 to FR-021 | Built, not yet verified in a Business Central sandbox |
| Warranty tracking (warranty information, monitoring, alerts, warranty dashboard) | FR-014 to FR-016, FR-022 | Built, not yet verified in a Business Central sandbox |
| Automated notifications and background processing (Job Queue) | FR-017, FR-018, NFR-004 | Built, not yet verified in a Business Central sandbox |
| Auditability (maintenance log entries) | NFR-005 | Built, not yet verified in a Business Central sandbox |

Feature documentation is in `docs/features/`, user help in `docs/help/` and the change history in `CHANGELOG.md`.

## Version 3

### Project objective

The V3 release focuses on integration, extensibility, and user experience enhancements.

The objective is to transform the Equipment Management solution into a connected enterprise application by providing document management, equipment images, API integrations, external system connectivity, approval processes, audit capabilities and advanced permissions.

### Scope of V3

| Area | Requirements | What it gives you |
|---|---|---|
| **Documents and images** | FR-023 Equipment Images, FR-024 Document Attachments, FR-025 Equipment Notes | Multiple pictures (MediaSet), documents (standard Document Attachment framework) and dated, user-stamped notes on each item of equipment |
| **API layer** | FR-026 Equipment API, FR-027 Equipment Categories API, FR-028 Assignment History API | Business Central APIs (`/api/equipment/v1.0/...`) for equipment (GET, POST, PATCH, DELETE), categories and assignment history |
| **Integration events** | FR-029 Business Events, FR-030 Event Subscribers | Published events (equipment created, assigned, returned, maintenance created, warranty expired) and subscribers that show event-driven design |
| **Power Platform** | FR-031 Power Automate Support | Example flows, such as a Teams notification on assignment and an email reminder for expiring warranties |
| **Approval management** | FR-032 Equipment Request Process, FR-033 Approval Workflow | Equipment requests (Open, Pending Approval, Approved, Rejected, Completed) that must be approved by a manager before assignment |
| **Audit and compliance** | FR-034 Change Log Support, FR-035 Equipment Audit Trail | Change Log monitoring and a complete history of created, updated, assigned, returned, maintenance and disposed events |
| **Security** | FR-036 Permission Sets | Equipment Reader, Equipment Manager, Equipment Administrator and API Consumer |
| **User experience** | FR-037 FactBoxes, FR-038 Enhanced Role Center | Summary, statistics and attachments FactBoxes on the Equipment Card, and new Role Center KPIs (requests pending approval, warranties expiring this month, open maintenance, total assets value) |
| **Reporting** | FR-039 Equipment Register Report, FR-040 Asset Utilization Report, FR-041 Maintenance Cost Analysis | Inventory register, utilization % (assigned / total equipment * 100) and maintenance cost by equipment, category, month and year |

### V3 progress

All 19 requirements (FR-023 to FR-041) are tracked as GitHub issues in the V3 milestone. None is built yet.

### Roadmap (after V3)

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
