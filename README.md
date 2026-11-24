# Equipment Management for Microsoft Dynamics 365 Business Central

## Overview

Equipment Management is a Microsoft Dynamics 365 Business Central extension (AL) to register company equipment, track who uses it, and keep maintenance and warranty information in one place.

> **Status:** V1 to V4 are built (FR-001 to FR-066, NFR-001 to NFR-005; all GitHub issues are closed). The tests run in CI. **The features have been verified in a Business Central sandbox, but nothing is released yet.** The app is a portfolio project: the object ID range is a demo range and the AppSource marketplace properties are still open (see [AppSource readiness](docs/architecture/appsource-readiness.md)).

### The problem

Companies hand out equipment to their employees every day: laptops, phones and tablets, monitors and other peripherals, tools, vehicles and industrial equipment. In most companies this information lives in **Excel spreadsheets** scattered across departments. As a result:

- Nobody knows for sure **who has which item**, or where it is.
- **Maintenance** is forgotten or done late because nothing reminds anyone.
- **Warranties** expire unnoticed, so repairs that should have been free get paid for.
- When an employee leaves, getting their equipment back is a manual, error-prone checklist.
- The data is not connected to the ERP, so it can't be reported on or secured like the rest of the business data.

Equipment Management brings this into Business Central, where the people, permissions and reports already live.

### Who uses it

Five permission sets (and an extension of D365 BASIC) cover the roles:

| Permission set | For |
|---|---|
| `EQM - Reader` | Read-only access to equipment, maintenance and reports |
| `EQM - Operator` | Daily work: assign, return, register maintenance, change existing equipment |
| `EQM - Manager` | Everything an operator does, plus create equipment, work with requests and manage attachments |
| `EQM - Administrator` | Everything a manager can, plus delete equipment, categories, setup, features, error log and demo data |
| `EQM - API Consumer` | Integrations that call the API |

See the [security and permissions guide](docs/user-guide/security-and-permissions.md).

## Features

| Area | What you can do |
|---|---|
| **Equipment register** | Register equipment with serial number, category, purchase and cost data. Statuses: Available, Assigned, In Maintenance, Disposed, Lost. Pictures, documents (standard Document Attachments) and dated notes on each item. |
| **Assignments** | Assign equipment to an employee and return it. Every assignment stays in an immutable history. |
| **Maintenance** | Register and post maintenance, plan recurring maintenance, see overdue work. Open maintenance sets the status In Maintenance and blocks assignment. Cost totals by equipment, category, month and year. |
| **Warranty** | Warranty period per item, a calculated warranty status, and alerts 90, 60 and 30 days before expiry. |
| **Requests and approvals** | Employees request equipment; a manager approves or rejects through the app's own approval process. Approval creates the assignment. |
| **Dashboards and reports** | A role center (profile `EQM EQUIPMENT MANAGER`) with KPIs and charts, FactBoxes on the Equipment Card, and reports: Equipment Register, Asset Utilization, Maintenance Cost Analysis. |
| **Automation** | Job Queue jobs for warranty and maintenance monitoring, notifications, and a retention policy for log tables. |
| **Integration** | REST API v1.0 for equipment, categories and assignment history; business events for Power Automate; published integration events for partner extensions. |
| **Audit and compliance** | Change Log support, an equipment audit trail, an error log, and a data classification review. |
| **Operations** | Feature Management (switch features on or off), a central setup page, install and upgrade codeunits, telemetry and usage analytics, demo data. |
| **Localization** | English, Portuguese (pt-PT) and Spanish (es-ES) translations; regional formats respected. |

Each requirement has a plan in `docs/plans/`, a feature document in `docs/features/`, a help article in `docs/help/` and an entry in [`CHANGELOG.md`](CHANGELOG.md). Some limits are decisions, for example FR-023 keeps one picture per equipment, like Item Picture.

## Architecture

- **Platform:** Business Central 29 (application `29.0.0.0`), AL runtime 18.0, target `Cloud`, no dependencies.
- **Layout:** `app/` (the extension, 130+ AL files under `app/src`, one folder per module) and `test/` (a separate test extension that depends on `app/`, about 580 test procedures in 38 test codeunits).
- **Extensibility:** extends Business Central only through events and extension objects. No base application objects are modified.
- **Conventions:** object prefix/affix `EQM` on every object; namespace `MiguelCarvalho.EquipmentManagement`; `Access = Internal` by default; object IDs 50100 to 50149 (app) and 50150 to 50199 (tests).
- **API route:** `/api/miguelCarvalho/equipment/v1.0/...`.
- **Quality:** `main` is protected and changes arrive through pull requests. AL-Go for GitHub compiles and tests every pull request with CodeCop, UICop and AppSourceCop; warnings are treated as defects. `python3 .github/scripts/repo_checks.py` validates plans, changelog, docs, breaking schema changes and dependencies. Coverage targets and gaps: [testing strategy](docs/architecture/testing-strategy.md).

More detail: the [architecture overview](docs/architecture/README.md) (modules, data model, key flows), the [object inventory](docs/architecture/extension-structure.md), the [API](docs/api/README.md) and [events](docs/api/events.md), and [CI/CD](docs/setup/ci-cd.md). Design decisions are logged in [`DECISIONS.md`](DECISIONS.md) and the project rules are in [`CLAUDE.md`](CLAUDE.md).

## Screenshots

Screenshots of the Equipment Card, the Role Center and the reports will be added here. Until then, the [user guide](docs/user-guide/README.md) describes every page, and **Create Demo Data** on Equipment Setup gives you sample data to look at.

## Installation

1. Install Visual Studio Code with the AL Language extension, and have a Business Central 29 sandbox.
2. Clone the repository. Open `app/` in VS Code, then run **AL: Download Symbols** against your sandbox. Do the same for `test/`.
3. Press `F5` to publish `app/` to your sandbox, or use **AL: Package** to build the `.app` (build `app/` first, then `test/`).
4. In Business Central, give yourself the `EQM - Administrator` permission set, open **Equipment Setup** to create the default number series and categories, and optionally choose **Create Demo Data** there.
5. Follow the [user guide](docs/user-guide/getting-started.md) for the first steps.

Full development setup and contribution workflow: [`docs/setup/README.md`](docs/setup/README.md).

## Roadmap

| Version | Focus | Requirements | State |
|---|---|---|---|
| **V1 (MVP)** | Equipment registration, categories, status, assignments, history, list and card, dashboard KPIs | FR-001 to FR-009, NFR-001 to NFR-003 | Built |
| **V2** | Maintenance, warranty, notifications, background processing, lifecycle monitoring, auditability | FR-010 to FR-022, NFR-004, NFR-005 | Built |
| **V3** | Integration and extensibility: images, documents, notes, APIs, business events, Power Automate, approvals, change log, audit trail, permission sets, FactBoxes, role center, reports | FR-023 to FR-041 | Built |
| **V4** | Production readiness: feature management, setup, upgrade, tests, CI/CD, telemetry, performance, localization, security and data review, documentation, code quality, dependencies, interfaces | FR-042 to FR-065 | Built |
| **Demo data** | Sample equipment for demos | FR-066 | Built |

**Next:** location tracking, the first release and the AppSource submission. **Out of scope:** depreciation and fixed-asset accounting, purchasing workflows, and mobile or barcode scanning.

**Known limits**
- The sandbox results are not yet written into the feature documents: many still say "not verified in a sandbox" and carry `TODO(verify)` markers. The remaining open items are in [`docs/TODO.md`](docs/TODO.md).
- Test coverage is below the targets (Business Logic about 58% procedure reach); API pages are covered by table-level tests only, not HTTP tests.
- Not ready for AppSource: demo ID range, empty marketplace properties in `app.json`, no release or baseline yet.
- The pt-PT and es-ES translations have not been reviewed by native speakers.

## Technologies Used

| Technology | Use |
|---|---|
| **AL** (runtime 18.0) and the AL Language extension for VS Code | The extension and its tests |
| **Microsoft Dynamics 365 Business Central 29** | Platform; extended through events and extension objects |
| **Business Central APIs (OData v4, REST)** | Equipment, categories and assignment history |
| **Power Automate** | Flows on business events |
| **Job Queue, Change Log, Document Attachments, No. Series** | Standard Business Central features the app builds on |
| **Application Insights telemetry** | Telemetry and usage analytics |
| **AL-Go for GitHub, GitHub Actions** | Build, test and release pipeline |
| **CodeCop, UICop, AppSourceCop** | Static analysis |
| **Python 3** (standard library) | Repository checks in `.github/scripts` |
| **XLIFF** | Translations (en, pt-PT, es-ES) |

License: [MIT](LICENSE).
