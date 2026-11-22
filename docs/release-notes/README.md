# Release notes

> Applies to Equipment Management 29.0.0.0 (not released). Facts are taken from the repository on branch feature/FR-060-developer-documentation; nothing is verified in a Business Central sandbox.

This page is the index of everything that describes a change or a release of Equipment Management. The files stay where they are, because the CHANGELOG, the plans and `repo_checks.py` refer to their current paths.

**In this article**
- [Current version](#current-version)
- [Where release information lives](#where-release-information-lives)
- [Versioning policy](#versioning-policy)
- [How to write release notes for a new FR](#how-to-write-release-notes-for-a-new-fr)
- [Related](#related)

## Current version

The app version is **29.0.0.0** (`app/app.json`). It is **not released**: no GitHub release exists and nothing was submitted to AppSource. Every feature since FR-001 is part of 29.0.0.0, which stays unchanged until the owner decides on a first release ([AppSource readiness](../architecture/appsource-readiness.md)).

## Where release information lives

| Source | What it holds |
|---|---|
| [`CHANGELOG.md`](../../CHANGELOG.md) | The change history, newest first, one section per requirement, grouped by Added, Changed, Fixed and Obsolete, with a "Release notes:" paragraph and a "Note:" line. It must stay at the repository root (`repo_checks.py` check 2 reads it there). |
| [`docs/user-guide/releases.md`](../user-guide/releases.md) | The user-facing summary of what is in 29.0.0.0, written for end users and administrators. Part of the user guide's page chain, so it is not moved. |
| [`.github/RELEASENOTES.copy.md`](../../.github/RELEASENOTES.copy.md) | A copy of the release notes of the AL-Go for GitHub template (v10.0 and earlier). It describes the pipeline tooling, not this app. |
| GitHub Releases | None yet. The first release is created with the **Create release** workflow ([CI/CD](../setup/ci-cd.md#versioning-and-releases)). |
| Feature docs and help articles | Per requirement, in [`docs/features/`](../features/) and [`docs/help/`](../help/). |

## Versioning policy

- Major.Minor come from `version` in `app/app.json`. Major follows the Business Central major version of `application`. Minor is raised by the owner for a feature release.
- Build is the CI run number and Revision is the run attempt minus 1. Both stay 0 in `app.json`; the pipeline stamps them. Agents do not edit `app.json`.
- Every release after 29.0.0.0 that changes data needs an upgrade step ([FR-044](../features/FR-044-data-upgrade-support.md)).

Details and the version checks VER1 to VER7: [FR-049](../features/FR-049-release-management.md).

## How to write release notes for a new FR

Add a section at the top of `CHANGELOG.md`:

```text
## FR-NNN <Name> (version stays 29.0.0.0, no bump)
### Added
- ...
### Changed
- ...
### Fixed
- ...
### Obsolete
- ...

Release notes: <one paragraph a customer can read: what is new, without object IDs.>

Note: <what did not change, what is not verified, and whether a separate AppSource validation ran.>
```

- The heading must start with `## FR-NNN`; Repo checks looks for it on a `feature/FR-NNN-*` branch.
- Write "None." in an empty group.
- When the change is visible to users, add or update the matching entry in [`docs/user-guide/releases.md`](../user-guide/releases.md).
- Obsoleted objects are listed under Obsolete with the reason and the tag.

## Related

- [`CHANGELOG.md`](../../CHANGELOG.md), [User release notes](../user-guide/releases.md)
- [CI/CD process](../setup/ci-cd.md), [FR-049 Release Management](../features/FR-049-release-management.md)
- [Documentation index](../README.md)
- Microsoft Learn: [Version numbers](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/administration/version-numbers)
