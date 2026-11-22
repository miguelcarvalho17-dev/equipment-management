# FR-060 Developer Documentation

## Purpose
The repository had no technical documentation for developers, partners or reviewers. Issue #101 asks for six deliverables: an architecture overview, the extension structure, the CI/CD process, the testing strategy, the API documentation and AppSource readiness. This change adds them as Markdown pages under `docs/`. It uses the target folders of the issue (`docs/architecture`, `docs/setup`, `docs/api`, `docs/user-guide`, `docs/release-notes`) and documents the current source layout. Nothing is renamed or moved.

Deliverable to file map:

| Deliverable (issue #101) | File |
|---|---|
| Index of all developer docs | `docs/README.md` |
| Architecture Overview | `docs/architecture/README.md` |
| Extension Structure | `docs/architecture/extension-structure.md` |
| Testing Strategy | `docs/architecture/testing-strategy.md` |
| AppSource Readiness | `docs/architecture/appsource-readiness.md` |
| CI/CD Process | `docs/setup/ci-cd.md` (development setup and contribution in `docs/setup/README.md`) |
| API Documentation | `docs/api/README.md`, `docs/api/endpoints.md`, `docs/api/events.md` |
| User guide (existing, FR-059) | `docs/user-guide/` (linked, not changed) |
| Release notes | `docs/release-notes/README.md` (index of `CHANGELOG.md` and `docs/user-guide/releases.md`) |

## Status
Implemented on branch `feature/FR-060-developer-documentation`, not committed by al-docs, not merged. Plan: `docs/plans/FR-060-developer-documentation.md` (status approved). Target: AppSource. App version stays 29.0.0.0 (unreleased, no bump). No `app/` change, no `app.json` change, no workflow change, no test change, no permission set change, no new event or procedure.

## Verification status
- **AL:** no AL change. The developer pages quote the object inventory, the events and the API properties from `app/src`, `test/src` and `app/src/API`. The developer checked that every quoted item matches the source. The reviewer re-ran the checks.
- **Inventory:** 171 objects (129 in `app/`, 42 in `test/`) match the source. The generated tables are in `docs/architecture/extension-structure.md`.
- **Links:** 395 relative links resolve in the new and changed files.
- **Events:** 26 event signatures in `docs/api/events.md` match the publishers in `app/src`.
- **API:** the API properties in `docs/api/endpoints.md` match `app/src/API/*.Page.al`.
- **Code diff:** `git diff --stat origin/main -- app/ test/ .github/ .AL-Go/` is empty.
- **Tests:** no tests written and none run for this change. Not verified: tests not executed locally. CI results quoted in the developer pages belong to `main`, not to this branch:
  - CI/CD run 44925652127 (`main`, commit e292f84): 569 tests passed.
  - CI/CD run 44920033270 (`main`, commit 0aed031): 563 tests, 1 failed (`InsertedNoteGetsSystemUserAndTime`). The cause is not analysed.
- **Coverage:** `coverage_check.py` run on 2026-11-22: Business Logic 57.8%, API 0.0%, Critical Processes 77.8%. `enforce` is false, so the result is a warning only.
- **Sandbox:** not run. Not verified in a Business Central sandbox. The sample request in `docs/api/endpoints.md` and the other `TODO(verify)` markers are open.
- **AppSource validation:** No separate AppSource validation ran. `docs/architecture/appsource-readiness.md` records the open items.
- **repo_checks.py:** not run by al-docs. The main agent runs it after this change.

## Structure
The developer docs are added next to the existing per-FR folders (`docs/features`, `docs/help`, `docs/plans`, `docs/validation`, `docs/examples`). Nothing is moved. `CHANGELOG.md` stays at the repository root, because `repo_checks.py` reads it there. `docs/user-guide/releases.md` stays in the user guide. `docs/release-notes/README.md` indexes both. The index is in `docs/README.md`.

The root `README.md` has one added line that links `docs/README.md`. Three sentences in the user guide that said the developer documentation was not written yet now link to it:
- `docs/user-guide/README.md` links `docs/README.md`.
- `docs/user-guide/integration.md` and `docs/user-guide/advanced-scenarios.md` link `docs/api/events.md`.

The FR-059 feature doc keeps its original text as a historical record.

## Source map
Each developer page is built from the source first, then from the newest feature doc on the topic, then from `docs/TODO.md`. When sources disagree, the higher one wins. The developer page names the conflict, and the older doc is not edited.

| Developer page | Main sources |
|---|---|
| `docs/architecture/README.md` | `app/app.json`, `app/src`, CLAUDE.md, the al-patterns skill, FR-026 to FR-058 feature docs |
| `docs/architecture/extension-structure.md` | `app/`, `test/`, `.github/`, `.AL-Go/`, `.gitignore` |
| `docs/architecture/testing-strategy.md` | `test/src`, `.github/coverage/coverage-register.json`, FR-045 to FR-047 |
| `docs/architecture/appsource-readiness.md` | `app/app.json`, `app/AppSourceCop.json`, `.AL-Go/equipment.ruleset.json`, Microsoft Learn checklist, `docs/TODO.md` |
| `docs/setup/README.md` | `.AL-Go/`, `.github/scripts/`, FR-048, FR-061 |
| `docs/setup/ci-cd.md` | `.github/workflows/*.yaml`, `.github/AL-Go-Settings.json`, `.AL-Go/settings.json`, FR-048, FR-049, FR-061 |
| `docs/api/README.md`, `docs/api/endpoints.md` | `app/src/API/*.Page.al`, FR-026, FR-027, FR-028, FR-036 |
| `docs/api/events.md` | Publishers in `app/src`, FR-029, FR-030, FR-031 |
| `docs/release-notes/README.md` | `CHANGELOG.md`, `docs/user-guide/releases.md`, `.github/RELEASENOTES.copy.md`, FR-049 |

The developer pages link the feature docs for detail. They summarise and do not copy the feature content.

## Maintaining the developer docs
- Each FR that adds an object, event or API field updates `docs/architecture/extension-structure.md`, `docs/api/events.md` or `docs/api/endpoints.md` in the same change. `docs/TODO.md`, section "FR-060 checks", records this rule.
- Each FR that changes a CI workflow, an analyzer setting or a version rule updates `docs/setup/ci-cd.md`.
- Each FR that changes the appsource checklist status updates `docs/architecture/appsource-readiness.md`.
- The object inventory is generated from the source with the same regex as `OBJECT_RE` in `repo_checks.py`. It is not typed by hand.
- The al-docs agent instructions do not yet name these folders. Changing the agent instructions is a configuration change for the user to decide.

## Conflicts found
The developer found these conflicts between sources. The developer pages follow the side listed. The older docs are not edited.

1. FR-048 and FR-049 name the artifacts differently. The developer pages follow FR-049.
2. FR-042 lists five features. Its feature list has six features. The developer pages state the current list.
3. FR-029 describes the job flow differently from the source. The source runs the job in `RunJob` in codeunit 50143. The developer pages follow the source.
4. FR-044 names one upgrade tag. The source has two upgrade tags. The developer pages follow the source.
5. FR-026 and FR-001 list permission sets that are out of date. The developer pages follow the source (FR-036 and FR-057 add API Consumer and Operator).
6. `.github/RELEASENOTES.copy.md` is the AL-Go template and not the release notes of this app.
7. `test/app.json` declares a minimum dependency version of 1.0.0.0. The developer pages state the value in the file. Not fixed.
8. The `Test*.settings.json` files set `versioningStrategy` to 15. The developer pages state the value in the files.
9. FR-044 to FR-047 say "written, not executed". The CI results on `main` show 569 tests passed (run 44925652127). The developer pages quote the run numbers and do not claim a result for this branch.
10. The FR-047 coverage baseline is older than the current result. The developer pages quote the 2026-11-22 result and label the FR-047 numbers as a baseline.
11. The FR-060 plan, Step 2, has a 50108 table entry, but its codeunit wording differs. The developer pages follow the source. Reviewer MINOR, open: this item is not yet in the conflict list in `docs/TODO.md`.
12. The root `README.md` shows the wrong API route (`/api/equipment/v1.0/...`) and a stale "V4 progress" section. Recorded in `docs/TODO.md`. Not fixed in this change.

## Open items
Phase 2 (publishing and tooling):
- Publish the docs, for example with ALDoc (AL-Go `DeployReferenceDocumentation.yaml`) or a static site. The user decides the host.
- Add a markdown link check and an object-inventory check to `repo_checks.py`.
- Tell al-docs to maintain `docs/architecture`, `docs/api` and `docs/release-notes`. This is a configuration change for the user to decide.
- Decide whether partners can subscribe to events published by internal publishers. The FR-029 publishers are `internal procedure` in a public codeunit. `docs/api/events.md` states that partners can subscribe but not raise them.

Phase 3 (content):
- Keep `docs/architecture/appsource-readiness.md` current as the release steps in `docs/TODO.md` close.
- Clear the `TODO(verify)` samples in `docs/api/endpoints.md` in a sandbox.
- Check the signing evidence in `docs/architecture/appsource-readiness.md`, line 26. The sign step in `_BuildALGoProject.yaml` runs only when `keyVaultCodesignCertificateName` or `trustedSigning` is set. Neither is set, so the page must say that the app is not signed in CI. Reviewer MINOR, open.
- Add the "plan Step 2 50108 table vs codeunit wording" item to the conflict list in `docs/TODO.md`. Reviewer MINOR, open.

Other open items:
- Fix the README API route and the "V4 progress" text in a chore branch. Recorded in `docs/TODO.md`, section "FR-060 checks".
- Analyse the failed test `InsertedNoteGetsSystemUserAndTime` in run 44920033270. The cause is not analysed yet.

## Related
- Plan: `docs/plans/FR-060-developer-documentation.md`
- Developer documentation index: `docs/README.md`
- Help article: `docs/help/FR-060-developer-documentation.md`
- Changelog: `CHANGELOG.md`, entry FR-060
- Open checks: `docs/TODO.md`, section "FR-060 checks"
- User guide (FR-059): `docs/user-guide/README.md`, feature doc `docs/features/FR-059-user-documentation.md`
