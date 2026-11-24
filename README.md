# Equipment Management for Business Central

A Microsoft Dynamics 365 Business Central extension (AL) to register company equipment, track who uses it, and keep maintenance and warranty information in one place.

> **Status:** V1 to V4 are built (FR-001 to FR-066, NFR-001 to NFR-005; all GitHub issues are closed). The tests run in CI. **The features have been verified in a Business Central sandbox, but nothing is released yet.** The app is a portfolio project: the object ID range is a demo range and the AppSource marketplace properties are still open (see [AppSource readiness](docs/architecture/appsource-readiness.md)).

## Contents

- [The problem](#the-problem)
- [What the app does](#what-the-app-does)
- [Who uses it](#who-uses-it)
- [Version history](#version-history)
- [Technical overview](#technical-overview)
- [Getting started](#getting-started)
- [Quality and process](#quality-and-process)
- [Documentation](#documentation)
- [Known limits](#known-limits)
- [License](#license)

## The problem

Companies hand out equipment to their employees every day: laptops, phones and tablets, monitors and other peripherals, tools, vehicles and industrial equipment.

In most companies this information lives in **Excel spreadsheets** scattered across departments. As a result:

- Nobody knows for sure **who has which item**, or where it is.
- **Maintenance** is forgotten or done late because nothing reminds anyone.
- **Warranties** expire unnoticed, so repairs that should have been free get paid for.
- When an employee leaves, getting their equipment back is a manual, error-prone checklist.
- The data is not connected to the ERP, so it can't be reported on or secured like the rest of the business data.

Equipment Management brings this into Business Central, where the people, permissions and reports already live.

## What the app does

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

## Who uses it

Five permission sets (and an extension of D365 BASIC) cover the roles:

| Permission set | For |
|---|---|
| `EQM - Reader` | Read-only access to equipment, maintenance and reports |
| `EQM - Operator` | Daily work: assign, return, register maintenance, change existing equipment |
| `EQM - Manager` | Everything an operator does, plus create equipment, work with requests and manage attachments |
| `EQM - Administrator` | Everything a manager can, plus delete equipment, categories, setup, features, error log and demo data |
| `EQM - API Consumer` | Integrations that call the API |

See the [security and permissions guide](docs/user-guide/security-and-permissions.md).

## Version history

| Version | Focus | Requirements | State |
|---|---|---|---|
| **V1 (MVP)** | Equipment registration, categories, status, assignments, history, list and card, dashboard KPIs | FR-001 to FR-009, NFR-001 to NFR-003 | Built |
| **V2** | Maintenance, warranty, notifications, background processing, lifecycle monitoring, auditability | FR-010 to FR-022, NFR-004, NFR-005 | Built |
| **V3** | Integration and extensibility: images, documents, notes, APIs, business events, Power Automate, approvals, change log, audit trail, permission sets, FactBoxes, role center, reports | FR-023 to FR-041 | Built |
| **V4** | Production readiness: feature management, setup, upgrade, tests, CI/CD, telemetry, performance, localization, security and data review, documentation, code quality, dependencies, interfaces | FR-042 to FR-065 | Built |
| **Demo data** | Sample equipment for demos | FR-066 | Built |

Each requirement has a plan in `docs/plans/`, a feature document in `docs/features/`, a help article in `docs/help/` and an entry in [`CHANGELOG.md`](CHANGELOG.md). Some limits are decisions, for example FR-023 keeps one picture per equipment, like Item Picture.

Roadmap after V4: location tracking, and the release steps (first release, AppSource submission). Out of scope: depreciation and fixed-asset accounting, purchasing workflows, and mobile or barcode scanning.

## Technical overview

- **Platform:** Business Central 29 (application `29.0.0.0`), AL runtime 18.0, target `Cloud`, no dependencies.
- **Layout:** `app/` (the extension, 130+ AL files under `app/src`, one folder per module) and `test/` (a separate test extension that depends on `app/`, about 580 test procedures in 38 test codeunits).
- **Extensibility:** extends Business Central only through events and extension objects. No base application objects are modified.
- **Conventions:** object prefix/affix `EQM` on every object; namespace `MiguelCarvalho.EquipmentManagement`; `Access = Internal` by default; object IDs 50100 to 50149 (app) and 50150 to 50199 (tests).
- **API route:** `/api/miguelCarvalho/equipment/v1.0/...`.
- **Build and test:** AL-Go for GitHub (compile, CodeCop, UICop, AppSourceCop and tests on every pull request).

Architecture, module list, data model and key flows: [`docs/architecture/`](docs/architecture/README.md).

## Getting started

1. Install Visual Studio Code with the AL Language extension, and have a Business Central 29 sandbox.
2. Clone the repository. Open `app/` in VS Code, then run **AL: Download Symbols** against your sandbox. Do the same for `test/`.
3. Press `F5` to publish `app/` to your sandbox, or use **AL: Package** to build the `.app` (build `app/` first, then `test/`).
4. In Business Central, give yourself the `EQM - Administrator` permission set, open **Equipment Setup** to create the default number series and categories, and optionally choose **Create Demo Data** there.
5. Follow the [user guide](docs/user-guide/getting-started.md) for the first steps.

Full development setup and contribution workflow: [`docs/setup/README.md`](docs/setup/README.md).

## Quality and process

- **Branches and PRs:** `main` is protected. Work happens on `feature/FR-NNN-...`, `fix/...` or `chore/...` branches and reaches `main` through a pull request.
- **Repository checks:** `python3 .github/scripts/repo_checks.py` validates plans, changelog, docs, schema (breaking changes) and dependencies. Run it before you commit; it also runs in CI.
- **Tests:** written with the app and run by AL-Go in CI. Coverage targets and known gaps are in the [testing strategy](docs/architecture/testing-strategy.md).
- **Analyzers:** warnings are treated as defects.
- **Decisions:** design decisions with alternatives are logged in [`DECISIONS.md`](DECISIONS.md). Open checks are in [`docs/TODO.md`](docs/TODO.md).
- **AI-assisted workflow:** features are built by a planner, developer, reviewer and docs agent team; the rules are in [`CLAUDE.md`](CLAUDE.md).

## Documentation

| Where | For | What |
|---|---|---|
| [`docs/README.md`](docs/README.md) | Everyone | Entry point to all documentation |
| [`docs/user-guide/`](docs/user-guide/README.md) | Users, managers, administrators | 19-page guide in task order |
| [`docs/architecture/`](docs/architecture/README.md) | Developers | Architecture, object inventory, testing, dependencies, AppSource readiness |
| [`docs/setup/`](docs/setup/README.md) | Developers | Environment, contribution workflow, [CI/CD](docs/setup/ci-cd.md) |
| [`docs/api/`](docs/api/README.md) | Integrators | [Endpoints](docs/api/endpoints.md) and [events](docs/api/events.md) |
| `docs/features/`, `docs/help/`, `docs/plans/` | Everyone | Per-requirement records |
| [`CHANGELOG.md`](CHANGELOG.md) | Everyone | Change history |

## Known limits

- The sandbox results are not yet written into the feature documents: many still say "not verified in a sandbox" and carry `TODO(verify)` markers. The remaining open items are in [`docs/TODO.md`](docs/TODO.md).
- Test coverage is below the targets (Business Logic about 58% procedure reach); API pages are covered by table-level tests only, not HTTP tests.
- Not ready for AppSource: demo ID range, empty marketplace properties in `app.json`, no release or baseline yet.
- The pt-PT and es-ES translations have not been reviewed by native speakers.

## License

[MIT](LICENSE)
