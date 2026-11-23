# Equipment Management documentation

> Applies to Equipment Management 29.0.0.0 (not released). Facts are taken from the repository on branch feature/FR-060-developer-documentation; nothing is verified in a Business Central sandbox.

This is the entry point to all documentation of the repository. The developer documentation (FR-060) describes the architecture, the extension structure, the CI/CD process, the testing strategy, the API and the AppSource readiness. The user guide (FR-059) is for end users and administrators.

**In this article**
- [Documentation folders](#documentation-folders)
- [Per-feature record folders](#per-feature-record-folders)
- [Where to start](#where-to-start)
- [Related](#related)

## Documentation folders

| Folder | Audience | Contents |
|---|---|---|
| [`architecture/`](architecture/README.md) | Developers | Architecture overview, [extension structure](architecture/extension-structure.md) with the object inventory, [testing strategy](architecture/testing-strategy.md) and [AppSource readiness](architecture/appsource-readiness.md), and [dependencies and supported versions](architecture/dependencies.md). |
| [`setup/`](setup/README.md) | Developers | Development environment, contribution workflow, and the [CI/CD process](setup/ci-cd.md). |
| [`api/`](api/README.md) | Integrators and partner developers | The REST API ([endpoints](api/endpoints.md)) and the AL and external [events](api/events.md). |
| [`user-guide/`](user-guide/README.md) | End users and administrators | The consolidated user guide (FR-059), 19 pages in task order. |
| [`release-notes/`](release-notes/README.md) | Everyone | Index of the change log, the user release notes and the versioning policy. |

The issue's target folders are added next to the existing per-FR folders. Existing files are not moved, because the CHANGELOG, plans, issues and `repo_checks.py` (check 2 expects `docs/plans`, `docs/features`, `docs/help`) refer to them.

## Per-feature record folders

Each requirement (FR-NNN) leaves one file in each of these folders. The files are the history of the project and the detail behind the pages above.

| Folder | Contents |
|---|---|
| [`features/`](features/) | Feature documentation per requirement: purpose, objects, verification status, compatibility. |
| [`help/`](help/) | Short help article per requirement. |
| [`plans/`](plans/) | The approved technical plan per requirement, and the events reports. |
| [`validation/`](validation/) | Static validation reports for some requirements. |
| [`examples/`](examples/) | Example agent reports. |
| [`TODO.md`](TODO.md) | Open checks and release steps, grouped by requirement. |

## Where to start

- To understand how the app is built, read the [architecture overview](architecture/README.md), then the [extension structure](architecture/extension-structure.md).
- To check the supported Business Central versions or add a dependency, read [dependencies](architecture/dependencies.md).
- To set up a development environment or contribute, read [setup](setup/README.md).
- To integrate with the app, read the [API overview](api/README.md) and the [events](api/events.md).
- To see how far the app is from a submission, read [AppSource readiness](architecture/appsource-readiness.md).

## Related

- [Repository README](../README.md)
- [CHANGELOG](../CHANGELOG.md)
- [CLAUDE.md](../CLAUDE.md) (project facts and rules)
- [Business Central developer documentation](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-dev-overview)
