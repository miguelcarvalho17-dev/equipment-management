# Developer documentation

This article points to the developer documentation for Equipment Management. The documentation covers the architecture, the extension structure, the setup and CI/CD process, the testing strategy, the API and the events, and AppSource readiness. It is for AL developers, contributors, reviewers and ISV partners. The design is described in `docs/features/FR-060-developer-documentation.md`.

The documentation applies to Equipment Management 29.0.0.0, which is not released yet. Nothing in it is verified in a Business Central sandbox. No separate AppSource validation ran.

## Where the documentation is
The documentation is in the `docs/` folder of the repository. Start with the index page.

## Contents
1. [Documentation index](../README.md): the folders and the per-feature records.
2. [Architecture overview](../architecture/README.md): the manifest, design principles, functional modules, data model and key flows.
3. [Extension structure](../architecture/extension-structure.md): the repository layout, the object inventory, the permission sets and the test app.
4. [Testing strategy](../architecture/testing-strategy.md): the test layers, conventions, coverage targets and known gaps.
5. [AppSource readiness](../architecture/appsource-readiness.md): the checklist status and the open items before submission.
6. [Development setup](../setup/README.md): prerequisites, building, the repository checks and the contribution workflow.
7. [CI/CD process](../setup/ci-cd.md): the workflows, the AL-Go settings, the pull request pipeline and the versioning.
8. [API overview](../api/README.md): the surfaces, the route, authentication and the feature switch.
9. [API endpoints](../api/endpoints.md): the properties, fields and bound actions of each API page.
10. [Events](../api/events.md): the business events for partners, the process hooks and the external business events.
11. [Release notes index](../release-notes/README.md): where the release information lives and how to write a changelog entry.

## Who it is for
- AL developers and contributors who change the app or the tests.
- Reviewers who check a change against the repository rules.
- ISV partners who build on the API or subscribe to events.

End users and administrators use the [user guide](../user-guide/README.md) instead.

## Release notes
Equipment Management has a developer documentation index. It covers the architecture, setup, CI/CD, testing, API, events and AppSource readiness. The documentation adds no change to the app.
