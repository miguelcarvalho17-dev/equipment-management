# Dependencies and supported versions

> Applies to Equipment Management 29.0.0.0 (not released). Facts are taken from the repository on branch feature/FR-063-dependency-management; nothing is verified in a Business Central sandbox.

In this article:

- [Minimum Business Central version](#minimum-business-central-version)
- [Manifest values](#manifest-values)
- [Dependency matrix](#dependency-matrix)
- [Removed and unused dependencies](#removed-and-unused-dependencies)
- [Standard modules used](#standard-modules-used)
- [Tooling dependencies](#tooling-dependencies)
- [Upgrade notes](#upgrade-notes)
- [Known gaps](#known-gaps)
- [Related](#related)

## Minimum Business Central version

The minimum is **Business Central 2026 release wave 2 (version 29.0), online** (`target` is `Cloud`).

- `application` is `29.0.0.0`. That is the minimum Application package: System Application, Business Foundation and Base Application.
- `runtime` is `18.0`. Runtime 18.0 ships with Business Central 29.0, and an extension needs a server with the same or a later runtime ([choosing a runtime](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-choosing-runtime)).
- `platform` is `1.0.0.0` and adds no constraint (see [Known gaps](#known-gaps)).

AppSource computes the minimum release from `application` and validates from that release up to the current production release ([validation releases](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-checklist-submission#against-which-releases-of-business-central-is-your-submission-validated)). The app is offered from 29.0 on.

Later versions are supported as long as the symbols the app uses exist. The forward checks are the manual Test Next Minor and Test Next Major workflows (see [Upgrade notes](#upgrade-notes)). This matches [Getting started](../user-guide/getting-started.md), which says "Business Central online, version 29.0 or later".

The minimum is a manifest fact. CI does not build on release 29.0 (see [Known gaps](#known-gaps)), so tested support for exactly 29.0 is not claimed.

## Manifest values

| Property | `app/app.json` | `test/app.json` | Meaning |
|---|---|---|---|
| `application` | `29.0.0.0` | `29.0.0.0` | Minimum Application package (System Application, Business Foundation, Base Application) |
| `platform` | `1.0.0.0` | `1.0.0.0` | Minimum platform (System) symbols; no practical constraint, see Known gaps |
| `runtime` | `18.0` | `18.0` | AL runtime; needs Business Central 29.0 or later |
| `target` | `Cloud` | `Cloud` | Business Central online |

Repo checks check 9 (DEP4) compares this table with both app.json files; update it in the same pull request.

## Dependency matrix

| App | Depends on | Publisher | App ID | Minimum version | Declared as | Why | Installed in customer tenants |
|---|---|---|---|---|---|---|---|
| Equipment Management | Application | Microsoft | – | 29.0.0.0 | `application` property | Standard tables, pages and codeunits | Yes (part of Business Central) |
| Equipment Management | No other app (`dependencies` is empty) | – | – | – | – | – | – |
| Equipment Management Tests | Application | Microsoft | – | 29.0.0.0 | `application` property | Test symbols | No |
| Equipment Management Tests | Equipment Management | Miguel Carvalho | `e6c30407-ec71-4f48-a790-70da80abc992` | 1.0.0.0 | `dependencies` | App under test; internals through `internalsVisibleTo` | No |
| Equipment Management Tests | Library Assert | Microsoft | `dd0be2ea-f733-4d65-bb34-a28f4624fb14` | 29.0.0.0 | `dependencies` | `Codeunit "Library Assert"` in all 37 test codeunits | No (test framework, comes with the container) |

Inbound side: only the test app depends on the app. Partner extensions may depend on the public surface, see [Events](../api/events.md) and [Extension structure](extension-structure.md#public-surface).

## Removed and unused dependencies

| Dependency | State | Reason |
|---|---|---|
| Tests-TestLibraries `5d86850b-0d76-4eca-bd7b-951ad998e997` | Removed in FR-026 | The HTTP tests failed with 401 in the AL-Go container, so the tests became table-level. See [FR-026](../features/FR-026-equipment-api.md). |
| Any (Microsoft test framework, "Any" library) | Never added | Tests use Locked labels with counters and `Random`. |
| Library - Lower Permissions | Not added | Decision of FR-057 phase 4. |
| Library - Report Dataset | Not added | Decision of FR-039. |

The issue text lists Any and Tests-TestLibraries as test dependencies. The manifest has only Library Assert.

## Standard modules used

The app has `using` lines for these 17 namespaces in `app/src`. The example column names one standard object the app refers to in a file with that `using` line.

| Namespace | Example |
|---|---|
| Microsoft.Foundation.Attachment | `Document Attachment` table (`EQMEquipment.Table.al`) |
| Microsoft.Foundation.NoSeries | `No. Series` codeunit (`EQMEquipment.Table.al`) |
| Microsoft.HumanResources.Employee | `Employee` table relation (`EQMEquipmentAssignment.Table.al`) |
| Microsoft.Inventory.Location | `Location` table relation (`EQMEquipment.Table.al`) |
| Microsoft.Purchases.Vendor | `Vendor` table relation (`EQMMaintenanceRecord.Table.al`) |
| System.DataAdministration | Retention policy allowed tables (`EQMUpgradeMgt.Codeunit.al`) |
| System.Device | `Camera` codeunit (`EQMEquipmentPictureMgt.Codeunit.al`) |
| System.Diagnostics | `Change Log Setup (Table)` and `Change Log Setup (Field)` (`EQMChangeLogRegistration.Codeunit.al`) |
| System.Environment | Used in `EQMEquipmentPictureMgt.Codeunit.al` (the exact object is not mapped here) |
| System.Environment.Configuration | `My Notifications` table (`EQMNotificationMgt.Codeunit.al`) |
| System.Integration | `BusinessChart` control add-in (`EQMEquipmentStatusChart.Page.al`) |
| System.Reflection | `Field` table in a FlowField (`EQMMaintenanceLogEntry.Table.al`) |
| System.Security.AccessControl | `User` table relation (`EQMEquipmentAssignment.Table.al`) |
| System.Threading | `Job Queue Entry` table (`EQMMaintenanceMonitorJob.Codeunit.al`) |
| System.Upgrade | `Upgrade Tag` codeunit (`EQMUpgradeMgt.Codeunit.al`) |
| System.Utilities | `Confirm Management` codeunit (`EQMEquipmentPictureMgt.Codeunit.al`) |
| System.Visualization | `Business Chart` codeunit (`EQMEquipmentStatusChart.Page.al`) |

All are provided through the `application` property. Which app (System Application, Business Foundation or Base Application) owns each namespace is not stated here (not verified with symbols). The standard events the app subscribes to are in the [extension points table](README.md#extension-points-into-standard-business-central).

## Tooling dependencies

These are version-controlled in the repository and are not installed in tenants.

- AL-Go for GitHub v10.0 (`$schema` in `.AL-Go/settings.json`, template `AL-Go-AppSource@main`, updated by `UpdateGitHubGoSystemFiles`, a user decision).
- The build artifact: `.AL-Go/settings.json` has no `artifact`, so the AL-Go default applies. TODO(verify) the Business Central version in a CI log.
- Forward-check artifacts `////latest`, `////nextminor` and `////nextmajor` (Test Current, Test Next Minor, Test Next Major).
- Analyzers CodeCop, UICop and AppSourceCop from the AL compiler of the build.
- Python 3.9 or later, standard library only, for `.github/scripts`.
- The VS Code AL Language extension.

## Upgrade notes

### (a) When Business Central gets a new version

The app keeps working, because `application` is a minimum. Before each release wave (April, October):

1. Run Test Next Minor and Test Next Major (Actions tab).
2. Fix compiler obsolete warnings for standard symbols before they become Removed.
3. AppSource revalidates the app.

### (b) Raising the minimum Business Central version

This is a stop-list change (user decision with a line in `DECISIONS.md`).

1. Raise `application` and `runtime` in both app.json files, plus `platform` if it is aligned.
2. Raise the Library Assert minimum to the new application version (DEP5).
3. FR-049 ties the Major version to the Business Central major: set `version` to `<new major>.0.0.0` and `repoVersion` in `.AL-Go/settings.json` (VER3).
4. Download symbols and compile both apps with no warnings.
5. Update the [Manifest values](#manifest-values) table (DEP4).
6. In the CHANGELOG release notes, state that customers on older Business Central keep the previous app version (AppSource availability follows `application`).
7. Add upgrade code only if data changes (FR-044).

### (c) Adding a dependency

This is a stop-list change.

- Never add Base Application or System Application explicitly (AS0085, DEP3).
- Library apps are installed with the app, and a dependency app needs its own AppSource offer ([FAQ](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/app-faq-dependencies-libraries)).
- A library is updated in tenants only when the minimum version in `app.json` is raised.
- Test-only libraries go into `test/app.json` only, and a Microsoft test library's version must not exceed `application` (DEP5).
- Add a matrix row in the same pull request (DEP4).

### (d) Removing a dependency

Confirm that no symbol from it is used. Move its row to [Removed and unused dependencies](#removed-and-unused-dependencies). DEP6 warns on the pull request.

### (e) Upgrading Equipment Management itself

See [FR-044](../features/FR-044-data-upgrade-support.md) ("How to add an upgrade step") and [FR-062](../features/FR-062-breaking-change-validation.md) (schema check). Every release after 29.0.0.0 that changes data needs an upgrade step.

## Known gaps

These are user decisions, not fixed here.

- `platform` is `1.0.0.0`.
- The test app's minimum on the app is `1.0.0.0` (VER5 allows it).
- CI builds on the AL-Go default artifact, not on the minimum release 29.0.
- Forward checks are manual only.
- No `supportedLocales`.

## Related

- Features: [FR-026](../features/FR-026-equipment-api.md), [FR-044](../features/FR-044-data-upgrade-support.md), [FR-049](../features/FR-049-release-management.md), [FR-060](../features/FR-060-developer-documentation.md), [FR-062](../features/FR-062-breaking-change-validation.md)
- [CI/CD](../setup/ci-cd.md), [Architecture overview](README.md), [AppSource readiness](appsource-readiness.md)
- Microsoft Learn: [runtime](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-choosing-runtime), [application file](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-application-app-file), [JSON files](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-json-files#appjson-file), [technical validation](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-checklist-submission), [dependencies FAQ](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/app-faq-dependencies-libraries), [AS0085](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/appsourcecop-as0085)
