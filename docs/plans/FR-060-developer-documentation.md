# FR-060 Developer Documentation — Plan

> Request (verbatim): FR-060 Developer Documentation
> Status: **approved**
> GitHub issue: #101

## Request
Write the FR-060 developer documentation (GitHub issue #101). It covers the architecture overview, the extension structure, the CI/CD process, the testing strategy, the API documentation and AppSource readiness. It uses the issue's target folders (`docs/architecture`, `docs/setup`, `docs/api`, `docs/user-guide`, `docs/release-notes`) and documents the current source layout (`app/`, `test/`, `.github/`, `.AL-Go/`, `docs/`) without renaming anything. Documentation only: no AL, no `app.json`, no workflow and no test change.
Target: AppSource

Issue #101 body (verbatim):
> The repository shall provide technical documentation. Deliverables: Architecture Overview, Extension Structure, CI/CD Process, Testing Strategy, API Documentation, AppSource Readiness. Target documentation structure: docs/ with architecture, setup, api, user-guide, release-notes. Note: the source layout stays as it is today: `/app` (main app), `/test` (test app), `.github/` and `docs/`. A rename to `src/` would break the build, test and AL-Go paths and is not part of this issue; document the existing structure instead.

## Definition of done
- [ ] These new files exist, each with an H1, a status line, "In this article", task or reference sections and a "Related" list: `docs/README.md`, `docs/architecture/README.md`, `docs/architecture/extension-structure.md`, `docs/architecture/testing-strategy.md`, `docs/architecture/appsource-readiness.md`, `docs/setup/README.md`, `docs/setup/ci-cd.md`, `docs/api/README.md`, `docs/api/endpoints.md`, `docs/api/events.md`, `docs/release-notes/README.md`.
- [ ] `docs/user-guide/` keeps all 19 files where they are. The only edits there are three sentences that now link to the developer docs (Step 13).
- [ ] `CHANGELOG.md` stays at the repository root (repo_checks needs it there). `docs/user-guide/releases.md` is not moved. `docs/release-notes/README.md` indexes both.
- [ ] Every object ID, name and file in `extension-structure.md` matches `app/src` and `test/src`, checked by the script in Step 15. No object is missing.
- [ ] Every event signature in `docs/api/events.md` is copied word for word from its publisher in `app/src`.
- [ ] Every API property in `docs/api/endpoints.md` (APIPublisher, APIGroup, APIVersion, EntityName, EntitySetName, InsertAllowed/ModifyAllowed/DeleteAllowed, bound actions) matches `app/src/API/*.Page.al`.
- [ ] Every relative link in the new and changed files resolves (Step 15).
- [ ] `git diff --stat origin/main -- app/ test/ .github/ .AL-Go/` is empty.
- [ ] `docs/plans/FR-060-developer-documentation.md` has `> Status: **approved**` in its first 12 lines. `docs/features/FR-060-developer-documentation.md`, `docs/help/FR-060-developer-documentation.md` and a CHANGELOG heading `## FR-060 Developer Documentation (version stays 29.0.0.0, no bump)` exist.
- [ ] `python3 .github/scripts/repo_checks.py --base origin/main --branch feature/FR-060-developer-documentation` passes (the main agent runs it).
- [ ] `README.md` has one added line that links `docs/README.md`. `docs/TODO.md` has a new "FR-060 checks" section.
- [ ] Reports say: "No AL change, no tests. Not verified in a Business Central sandbox. No separate AppSource validation ran."

## Out of scope
- Renaming `app/` or `test/` to `src/` (breaks AL-Go `appFolders`/`testFolders`, `repo_checks.py`, `coverage_check.py`).
- Moving or editing existing `docs/features/*`, `docs/help/*`, `docs/plans/*`, `docs/validation/*`, `docs/examples/*`.
- Fixing the stale README text ("V4 progress" and the API route `/api/equipment/v1.0/...`). Recorded in docs/TODO.md (Step 14).
- Generating AL reference docs with AL-Go `DeployReferenceDocumentation.yaml` (ALDoc): phase 2, user's call.
- Any change to `repo_checks.py`, the workflows, `.AL-Go/*`, `app.json`, `.claude/agents/*` or the skills.
- Changing app metadata (`help`, `url`, `privacyStatement`, `EULA`, `logo`): stop list, open AppSource item.

Later phases:
- Phase 2: publish the docs (ALDoc or a static site), add a markdown link check and an object-inventory check to `repo_checks.py`, and tell al-docs to maintain `docs/architecture`, `docs/api` and `docs/release-notes` (configuration change, user decision).
- Phase 3: update `appsource-readiness.md` as the release steps in docs/TODO.md close.

## Objects
No AL objects are created or changed; `al_getnextobjectid` is not needed.

| File | New/Changed | Written by |
|---|---|---|
| docs/README.md | New | developer |
| docs/architecture/README.md | New | developer |
| docs/architecture/extension-structure.md | New | developer |
| docs/architecture/testing-strategy.md | New | developer |
| docs/architecture/appsource-readiness.md | New | developer |
| docs/setup/README.md | New | developer |
| docs/setup/ci-cd.md | New | developer |
| docs/api/README.md | New | developer |
| docs/api/endpoints.md | New | developer |
| docs/api/events.md | New | developer |
| docs/release-notes/README.md | New | developer |
| docs/user-guide/README.md (line 34), integration.md (line 81), advanced-scenarios.md (line 81) | Changed (one sentence each) | developer |
| README.md | Changed (one line after line 86) | developer |
| docs/TODO.md | Changed (new section at end) | developer |
| docs/features/FR-060-developer-documentation.md | New | al-docs |
| docs/help/FR-060-developer-documentation.md | New | al-docs |
| CHANGELOG.md | Changed (new top entry) | al-docs |
| docs/plans/FR-060-developer-documentation.md | New | main agent |

## Events and standard symbols
No AL code is written. `docs/api/events.md` and `docs/architecture/README.md` quote publishers and subscribers word for word from `app/src`, which compiles in CI, so the source is the reference.

## Steps

**Step 0: rules for every new page (read before Step 1)**
- Audience: AL developers, contributors, reviewers and ISV partners. Object IDs and AL object names are allowed and expected here, unlike the user guide.
- Template: H1, then one line `> Applies to Equipment Management 29.0.0.0 (not released). Facts are taken from the repository on branch feature/FR-060-developer-documentation; nothing is verified in a Business Central sandbox.`, a 1–3 sentence intro, an "In this article" list of anchors, H2 sections, "Related" (relative links to repo files and Microsoft Learn URLs), and no Previous/Next footer.
- Sources, in this order of trust: (1) the files themselves (`app/src`, `test/src`, `app/app.json`, `test/app.json`, `.AL-Go/settings.json`, `.AL-Go/equipment.ruleset.json`, `app/AppSourceCop.json`, `.github/workflows/*.yaml`, `.github/scripts/*.py`, `.github/coverage/coverage-register.json`); (2) the newest feature doc on the topic (FR-061 > FR-049 > FR-048 for CI; FR-047 > FR-046 > FR-045 for tests; FR-026/027/028/036 for the API; FR-029/030/031 for events; FR-044 for upgrade); (3) `docs/TODO.md`. When sources disagree, the higher one wins. List every conflict in the developer report under "Conflicts found" and do not edit the older doc.
- Link to existing feature docs for detail instead of copying them. Summarise in at most a table plus a few bullets.
- Keep every `TODO(verify)` and "not verified" statement from the source. Never claim that tests pass, builds are green or anything was checked in a sandbox, unless a feature doc records a CI result with its PR or run number. Quote that number.
- English, present tense, short sentences, no marketing language. Code identifiers in backticks. Mermaid diagrams allowed; images are not.
- Relative links only, so the docs work on GitHub.

1. `docs/README.md` (documentation index). H1 "Equipment Management documentation". A table `| Folder | Audience | Contents |` with rows: `architecture/` (developers: overview, structure, testing strategy, AppSource readiness), `setup/` (developers: development environment, contribution workflow, CI/CD), `api/` (integrators and partner developers: REST API, events), `user-guide/` (end users and administrators, FR-059), `release-notes/` (everyone: changelog, user release notes, versioning). A second table covers the per-FR record folders: `features/`, `help/`, `plans/`, `validation/`, `examples/`. Add a note: "The issue's target folders are added next to the existing per-FR folders. Existing files are not moved, because the CHANGELOG, plans, issues and `repo_checks.py` (check 2 expects `docs/plans`, `docs/features`, `docs/help`) refer to them."

2. `docs/architecture/README.md` (Architecture Overview). Sections:
   - "Platform and manifest": table from `app/app.json` (id, name, publisher, version 29.0.0.0, application 29.0.0.0, platform, runtime 18.0, target Cloud, idRanges 50100–50149, features NoImplicitWith and TranslationFile, dependencies none, internalsVisibleTo the test app). Note that the `description` mentions resources, which the app does not support (see docs/TODO.md).
   - "Design principles": extend only through events and extension objects; one codeunit per responsibility; subscriber codeunits only delegate; `Access = Internal` by default, public surface listed in extension-structure.md; the `EQM` affix; labels and ErrorInfo. Cite CLAUDE.md and the al-patterns skill.
   - "Functional modules": one row per folder under `app/src` (list with Glob `app/src/*/`; expected: API, Assignment, Attachments, AuditTrail, BusinessEvents, ChangeLog, Dashboard, DemoData, Employee, Equipment, ErrorLog, Features, Install, Integration, Maintenance, Monitoring, Notes, Notifications, Permissions, PowerAutomate, Reports, Request, Setup, Telemetry, UsageAnalytics, Warranty, plus any others). Columns: `| Module | Responsibility | Key objects | Feature docs |`.
   - "Data model": a mermaid `erDiagram` of the core tables and relations from `TableRelation` properties in `app/src`: EQM Equipment (50100) → EQM Equipment Category (50101), Employee (standard); EQM Equipment Assignment (50103) → Equipment, Employee; EQM Maintenance Record (50105) → Equipment; EQM Maintenance History Entry (50106) → Equipment; EQM Maintenance Log Entry (50108); EQM Warranty Alert (50107); EQM Equipment Note (50109); EQM Integration Event Entry (50110); EQM Equipment Request (50111); EQM Equipment Audit Entry (50112); setup tables 50102 and 50114. Include only relations visible in source.
   - "Key flows": short numbered flows for assignment (EQM Equipment `AssignEmployee` → codeunit 50106 → audit and integration outbox → business and external events), maintenance registration and posting (50105 → 50108/50109 → 50106 history → status), request approval (50111 → 50132), and the background jobs (Warranty Alert Job, Maintenance Monitor Job, Maintenance Calc. Job, scheduled and run through the job codeunits, errors logged by the error-log codeunit). Confirm each call in source before writing it.
   - "Cross-cutting concerns": feature switches (enum 50112), setup (50102), telemetry (FR-050), error log (FR-051), usage analytics (FR-052), change log registration (FR-034), translations (`app/Translations/*.xlf`; FR-055), regional settings (FR-056), data classification (FR-058), performance rules (FR-053, FR-054).
   - "Install and upgrade": EQM Install, EQM Upgrade and EQM Upgrade Mgt. codeunits; the upgrade tag table from FR-044; "never change a shipped tag"; new-company behaviour (docs/TODO.md "New companies").
   - "Extension points into standard Business Central": every `tableextension`, `pageextension`, `enumextension`, `permissionsetextension` and every `[EventSubscriber(ObjectType::` in `app/src` whose publisher is a standard object, copied word for word. Columns: `| Standard object | Event or extension | Our object | Why |`.
   - Related: per-FR feature docs and Learn (events in AL, extensibility).

3. `docs/architecture/extension-structure.md` (Extension Structure). Sections:
   - "Repository layout": tree of the top level (`app/`, `test/`, `.github/` with workflows, scripts, coverage and AL-Go settings, `.AL-Go/`, `docs/`, `.claude/`, `CHANGELOG.md`, `DECISIONS.md`, `CLAUDE.md`, `README.md`, `LICENSE`), one line each. State that `src/` is not used and why.
   - "App folder": `app/app.json`, `app/AppSourceCop.json` (mandatoryAffixes EQM), `app/.vscode/settings.json`, `app/src/<Module>/`, `app/src/Reports/Layouts/*.xlsx`, `app/Translations/` (never edit `.g.xlf` by hand; use `xlf_sync.py`, FR-055), `app/.alpackages` (check `.gitignore` and state the fact).
   - "Naming conventions": file name pattern `EQM<Name>.<ObjectType>.al` (confirm from file list), object names start with `EQM `, the affix on members added to standard objects, label suffixes from al-patterns.
   - "Object ID allocation": app 50100–50149, test app 50150–50199. IDs unique per object type (repo_checks check 1). New IDs only from `al_getnextobjectid`. Widening a range is on the stop list.
   - "Object inventory (app)": one table `| Type | ID | Name | Access | File |` for every object in `app/src`, sorted by type then ID, generated with the Step 15 script, not typed by hand. Profiles have no ID. Access is `Public` or `Internal` from `Access =`, or "default (Public)". Give counts per type.
   - "Public surface": objects with `Access = Public` (re-grep), the API pages, the permission sets, the enums with `Extensible = true`. After the first AppSource release these cannot be removed, renamed or retyped; obsolete them (CLAUDE.md target profile).
   - "Permission sets": 50100 EQM - Reader, 50101 EQM - Manager, 50102 EQM - Administrator, 50104 EQM - API Consumer, 50105 EQM - Operator, extension 50103 of D365 BASIC. Take the `IncludedPermissionSets` hierarchy from source. Rule: every new object goes into the existing sets in the same change.
   - "Test app": `test/app.json` (dependencies on Equipment Management and Library Assert 29.0.0.0, no TranslationFile feature), `test/src/`. Test object inventory generated the same way.
   - Related: FR-036, FR-057, FR-055, FR-058, FR-061.

4. `docs/architecture/testing-strategy.md` (Testing Strategy). Sections:
   - "Test layers": unit (FR-045), integration (FR-046, codeunit 50158 EQM Process Integration Tests), API table-level tests (50180, 50181, 50182: why table-level and not HTTP, per docs/TODO.md FR-026), permission tests (50162 EQM Role Permission Tests), data classification tests (FR-058), upgrade tests (50177), performance tests, translation tests.
   - "Test codeunit catalogue": table `| ID | Name | Area | Feature |` generated from `test/src` (Step 15). Mark helper/subscriber codeunits (`*TestSubscr`) as helpers.
   - "Conventions": `Subtype = Test`; `TestPermissions = Disabled`; `[TransactionModel(TransactionModel::AutoRollback)]`; `[SCENARIO]/[GIVEN]/[WHEN]/[THEN]`; at most one `asserterror` as the last action; Locked `Tok` data labels with prefix, counter plus `Random()`; handlers for every UI interaction; internals via `internalsVisibleTo`. Confirm each by grepping two or three test files before stating it. Say Permissions Mock did not lower rights in CI (FR-023 note in docs/TODO.md).
   - "Coverage targets": summary of FR-047 (procedure reach for Business Logic and APIs at 80%, rule coverage for Critical Processes at 100%, `enforce` false, the register file, the rule "a new `Error(`/`TestField(` in a CP object needs a register entry in the same change"). Read the current `enforce` value from `.github/coverage/coverage-register.json`. Do not copy FR-047 baseline numbers as current: either run `python3 .github/scripts/coverage_check.py` (or repo_checks without `--base`) and quote today's result lines with the date, or link the FR-047 baseline and label it "baseline 2026-11-19".
   - "How tests run": in CI through AL-Go; locally only with AL Test Runner / Test Explorer against a sandbox; agents cannot run tests (CLAUDE.md); reading counts (`gh run view <id> --log | grep -E "tests,|passed"`); the manual coverage run (FR-047).
   - "Python checks": `.github/scripts/test_coverage_check.py`, `test_version_check.py`, `test_xlf_sync.py`, run with `python3 <file>`.
   - "Known gaps": API page reach, CP gaps, test-app analyzers off in CI, tests recorded as written but not executed in docs/TODO.md. Link; do not restate.
   - Related: FR-045, FR-046, FR-047 and Learn.

5. `docs/architecture/appsource-readiness.md` (AppSource Readiness). Verdict at top: "**Not ready for submission.**" with one sentence of reason. One table `| Checklist requirement (Microsoft Learn) | Status | Evidence | Next step |`, one row per item of the Learn technical validation checklist:
   - app.json mandatory properties: Open (`privacyStatement`, `EULA`, `help`, `url`, `logo` empty).
   - Affix registered and used: Partial (used and enforced; not registered).
   - ID range registered: Open (demo range; AS0084 downgraded in the ruleset).
   - Signed .app: Open.
   - AppSourceCop clean: Partial (ruleset downgrades AS0051, AS0052, AS0084; exception register AS0081 and AS0092 from FR-061; no baseline until first release; FR-062 not built).
   - ApplicationArea set: status with evidence (FR-034 validation report noted API pages have no ApplicationArea; check whether it still applies).
   - Permission sets without SUPER: Met in code, not sandbox-verified.
   - Publish, install, uninstall, reinstall in an environment: Not done.
   - Tested in an environment: Not done (CI tests only).
   - `OnBeforeCompanyOpen`/`OnAfterCompanyOpen` not used: grep `app/src` and report.
   - Upgrade code: Met (with tags; every release after 29.0.0.0 needs a step).
   - Web services do not show UI: status; cite FR-026 decision "confirmations default to Yes without UI" and `GuiAllowed` usage.
   - Translations: Met in code (FR-055; native review open).
   - Data classification: Met (FR-058).
   - Telemetry `applicationInsightsConnectionString`: Open (AS0092).
   - `resourceExposurePolicy` review: Open.
   - Test-app analyzers in CI: Off.
   Add "Release steps that close the open items" (link docs/TODO.md "AppSource FAILs", FR-049, FR-061) and "How to self-validate" (Run-AlValidation needs Windows and Docker, plus AL-Go PR builds). Note the skill copy of the checklist is dated 2026-02-26; the Learn page is the reference.

6. `docs/setup/README.md` (development environment and contribution workflow). Sections: "Prerequisites" (VS Code + AL Language extension; BC 29 sandbox; Python 3.9+; `gh` optional); "Get the code and symbols" (clone, open `app/`, then `test/`, AL: Download Symbols; `.AL-Go/localDevEnv.ps1` and `cloudDevEnv.ps1`, one line each after reading their headers); "Build" (AL: Package per folder, `app/` first; analyzers from `.vscode/settings.json`; FR-061 test app CodeCop and UICop only; warnings are defects; no `#pragma`, no ruleset edits); "Run the repository checks locally" (`python3 .github/scripts/repo_checks.py --base origin/main --branch <branch>`, the 7 checks one line each from the script docstring; what a feature branch needs; the xlf sync command from check 4); "Contribution workflow" (branches, `main` protected, al-feature pipeline, plans in `docs/plans/`, DECISIONS.md, definition of done); "Adding things safely" (checklist for a new object and for a new event; new events become public API and are documented in `docs/api/events.md`); Related: CLAUDE.md, al-patterns, FR-048, FR-061.

7. `docs/setup/ci-cd.md` (CI/CD Process). Sections:
   - "Workflows": table `| Workflow file | Name | Trigger | Purpose |` built from `.github/workflows/*.yaml` (read every `name:` and `on:`). At planning time: CICD.yaml on push to main, release/* and feature/*, skips `**.md` and workflow-only changes, manual run possible; PullRequestHandler.yaml on PRs into main and merge_group; RepoChecks.yaml on PRs into main; the rest manual; `_BuildALGoProject.yaml` reusable. Correct from the files.
   - "AL-Go settings": table of every key in `.github/AL-Go-Settings.json` and `.AL-Go/settings.json` with its effect; cite FR-048/FR-061; ruleset table (AS0051, AS0052, AS0084 at Warning, with justifications) and that it must be removed before submission; mention the `Test Current/Next Minor/Next Major.settings.json` files.
   - "Pull request pipeline": mermaid flowchart (PR into main → Pull Request Build: compile app, analyzers, compile test app, run tests → "Pull Request Status Check"; in parallel Repo checks → checks 1–7). Required checks and branch protection are TODO(verify) per FR-048.
   - "Versioning and releases": summary of FR-049 (Major.Minor from app.json, Build = run number, Revision = attempt − 1, artifact names, VER1–VER7) and the release procedure; no release has been created yet.
   - "Reading results": `gh pr checks`, `gh run view --log`; artifacts Apps, TestApps, TestResults, BuildOutput.
   - "Do not edit": AL-Go system workflows; settings, ruleset or analyzer changes are user decisions.
   - Related: FR-048, FR-049, FR-061, Learn AL-Go overview.

8. `docs/api/README.md`. Sections: "Surfaces" (REST API pages, AL events, external business events, integration event outbox); "Route" (`/api/miguelCarvalho/equipment/v1.0/companies({companyId})/<entitySet>`, built from APIPublisher `miguelCarvalho`, APIGroup `equipment`, APIVersion `v1.0`; full URL form per Learn; note README.md shows the wrong `/api/equipment/v1.0/...`); "Authentication and permissions" (Entra app; EQM - API Consumer plus D365 BASIC; FR-036; sandbox checks S1–S4 open); "Feature switch" (API Integration feature must be on; confirm in `OnOpenPage` and quote); "Conventions and versioning" (summarise C1–C10 from `docs/features/FR-026-equipment-api.md`; v1.0 freezes at first AppSource release); "Tests" (50180/50181/50182 table-level; API page reach per FR-047 baseline, quote today's number if run).

9. `docs/api/endpoints.md`. One H2 per API page: 50123 EQM Equipment API (`equipment`/`equipments`), 50124 EQM Category API (`category`/`categories`), 50125 EQM Assignment API (`assignment`/`assignments`), 50126 EQM Integration Event API (`integrationEvent`/`integrationEvents`). For each: property table (ODataKeyFields SystemId, DelayedInsert, InsertAllowed/ModifyAllowed/DeleteAllowed; unset → "not set (allowed)"); operations allowed; field table `| JSON name | Source field | Type | Editable | Notes |`; bound actions with exact signatures copied from source (`assign(var ActionContext: WebServiceActionContext; employeeNumber: Code[20])`, `returnEquipment(var ActionContext: WebServiceActionContext)`, `markProcessed(var ActionContext: WebServiceActionContext)`), plus sample request `POST .../equipments({id})/Microsoft.NAV.assign` with body `{"employeeNumber": "..."}` marked TODO(verify); open TODO(verify) items from docs/TODO.md FR-026/027/028. Cross-link `../user-guide/using-the-api.md`.

10. `docs/api/events.md`. Sections:
    - "Event types used".
    - "Business events for partners" (codeunit 50119 EQM Business Events, `Access = Public`; publishers are `internal procedure`): table of `OnEquipmentCreated`, `OnEquipmentAssigned`, `OnEquipmentReturned`, `OnMaintenanceCreated`, `OnWarrantyExpired`, signatures copied from source, "raised when" and transaction notes from FR-029. Partners can subscribe but not raise them.
    - "Process hooks (IsHandled and validation events)": every other `[IntegrationEvent(false, false)]` publisher in `app/src` with signatures word for word (EQM Equipment 50100: OnBeforeCheckCategoryIsActive, OnBeforeCheckSerialNoIsUnique, OnBeforeCheckEmployeeIsEligible, OnBeforeCheckStatusTransitionAllowed, OnBeforeCheckWarrantyDates, OnBeforeCalcNextMaintenanceDate, OnBeforeUpdateLastMaintenanceFromPosting, OnAfterCheckEquipmentConsistency, OnBeforeStartMaintenance, OnBeforeCompleteMaintenance; EQM Maintenance Record 50105: OnAfterCheckMaintenanceConsistency; EQM Maintenance-Post 50109: OnBeforePostMaintenanceRecord, OnBeforeInsertMaintenanceHistoryEntry, OnAfterPostMaintenanceRecord; EQM Assignment Mgt. 50106: OnBeforeInsertAssignment, OnBeforeCloseAssignment; EQM Equipment Request 50111: OnAfterCheckRequestConsistency; EQM Request Approval Mgt. 50132: OnBeforeCheckApproverAllowed, OnAfterRequestStatusChanged). Columns `| Publisher object | Event | Signature | IsHandled | Feature doc |`. Re-grep `\[IntegrationEvent` so none is missed.
    - "External business events (Power Automate)": codeunit 50130 EQM Power Automate Events, `equipmentAssigned` and `warrantyExpiring`, attribute text, `RequiredPermissions`, enumextension 50100 "EQM Event Category" (FR-031).
    - "Contract rules": signatures never change once released; add a new event and obsolete the old; publishers are `[IntegrationEvent(false, false)]`; subscribers must not `Commit`, must check `IsTemporary`, must not show UI without `GuiAllowed`.
    - "Example subscriber": one short AL block in Markdown subscribing to `OnEquipmentAssigned` with a placeholder affix `ABC`. Markdown only, no `.al` file.

11. `docs/release-notes/README.md`. Sections: "Current version" (29.0.0.0, not released); "Where release information lives" (table: `../../CHANGELOG.md`, `../user-guide/releases.md`, `../../.github/RELEASENOTES.copy.md` described in one line after reading it, GitHub Releases (none yet)); "Versioning policy" (three lines plus FR-049 link); "How to write release notes for a new FR" (CHANGELOG entry format: heading `## FR-NNN <Name>`, Added/Changed/Fixed/Obsolete, "Release notes:" paragraph, "Note:" line; plus `user-guide/releases.md`).

12. `README.md` (root). After line 86 (the user-guide line) add: `Developer documentation (architecture, setup, CI/CD, testing, API, AppSource readiness) starts at [`docs/README.md`](docs/README.md).` Change nothing else.

13. `docs/user-guide/README.md` line 34, `integration.md` line 81, `advanced-scenarios.md` line 81: replace "(FR-060). It is not written yet." / "(FR-060), which is not written yet." with a link (`[developer documentation](../api/events.md)` for the two event sentences, `[developer documentation](../README.md)` for the README sentence). Keep the rest of each sentence.

14. `docs/TODO.md`: at the end add "## FR-060 checks (documentation only; not verified in a sandbox)": README V3 table API route wrong (real route `/api/miguelCarvalho/equipment/v1.0/...`; fix in a chore); README "V4 progress" stale; keep extension-structure.md inventory, events.md and endpoints.md in sync in every FR that adds objects, events or API fields; phase 2 items (inventory and link check in `repo_checks.py`; ALDoc via DeployReferenceDocumentation; al-docs instructions for the new folders: user decisions); clear TODO(verify) samples in endpoints.md in a sandbox; add every conflict from the developer's "Conflicts found" list.

15. Verification (developer, Bash; scripts go in the scratchpad, no file left in the repo).
    a. Inventory script `python3 -I <scratchpad>/inventory.py <repo>` using the same regex as `OBJECT_RE` in `repo_checks.py`, plus `profile "<name>"`; prints Markdown rows `| Type | ID | Name | Access | File |` for `app/src` and `test/src`. Paste into Steps 3 and 4, then re-run in compare mode against the docs. Expected: no differences.
    b. Link check (FR-059 approach): every `](relative...)` target in the 11 new files, the 3 changed user-guide files, README.md and the FR-060 feature doc and help article resolves once the anchor is stripped.
    c. Event check: every signature line in `docs/api/events.md` is found word for word in `app/src` (grep -F). Grep `\[IntegrationEvent|\[ExternalBusinessEvent` in `app/src`; the count must equal the rows in events.md.
    d. API check: every `APIPublisher/APIGroup/APIVersion/EntityName/EntitySetName` value in endpoints.md appears in `app/src/API`.
    e. `git diff --stat origin/main -- app/ test/ .github/ .AL-Go/` is empty.
    f. `grep -rn "OnBeforeCompanyOpen\|OnAfterCompanyOpen" app/src`: result goes in appsource-readiness.md.
    Report all results.

Docs stage (al-docs, after the reviewer approves):

16. `docs/features/FR-060-developer-documentation.md`: Purpose (issue #101, six deliverables mapped to files), Status (branch, docs only, version stays 29.0.0.0), Verification status (no AL, no tests, no sandbox, no separate AppSource validation, "repo_checks.py not run by al-docs"), Structure (target folders → files; why nothing was moved), Source map, "Maintaining the developer docs", Conflicts found (from the developer report), Open items (phases 2 and 3).

17. `docs/help/FR-060-developer-documentation.md`: short article "Developer documentation": where it lives, contents list linking `../README.md`, `../architecture/*.md`, `../setup/*.md`, `../api/*.md`, `../release-notes/README.md`, and who it is for. Required by repo_checks check 2.

18. `CHANGELOG.md`: new top entry `## FR-060 Developer Documentation (version stays 29.0.0.0, no bump)` in the FR-059 format: Added, Changed (three user-guide sentences), Fixed: None, Obsolete: None, "Release notes:" paragraph, "Note:" line (no `app/` change, no `app.json` change, no tests, not verified in a sandbox, no separate AppSource validation ran).

Main agent:

19. Save this plan with the house header and run `python3 .github/scripts/repo_checks.py --base origin/main --branch feature/FR-060-developer-documentation`.

## Tests
No AL change, so no AL tests and no existing tests affected. Documentation acceptance checks (Step 15 and reviewer):
- Inventory complete: compare script finds no missing, extra or mismatched rows. Negative: a scratchpad copy with one row removed is reported; delete the copy afterwards.
- Links resolve: 0 missing targets. Negative: a scratchpad copy with a link to `missing.md` is reported.
- Event signatures exact: all found with `grep -F`; publisher count equals row count. Negative: a scratchpad copy with one changed parameter type is reported as not found.
- No code change: `git diff --stat origin/main -- app/ test/ .github/ .AL-Go/` is empty.
- Repo checks pass: "All repository checks passed."
- Repo checks catch a missing help article (reasoning only): check 2 reports "FR-060: no help article found"; this is why Step 17 is mandatory.
- Reviewer spot check, no overclaiming: each "passes", "green" or "met" claim in testing-strategy.md, ci-cd.md and appsource-readiness.md is traced to a CI run or PR number from a feature doc, or says "not verified".

## Assumptions
- The five target folders are added next to the existing per-FR folders, not in place of them (repo_checks check 2 needs the per-FR folders; the issue says to document the existing structure).
- `docs/user-guide/` (FR-059) already meets the issue's `user-guide` folder; FR-060 only links to it.
- `release-notes` is an index, not a move (`CHANGELOG.md` must stay at the root; `user-guide/releases.md` is part of the FR-059 Previous/Next chain).
- Object IDs and AL names are fine in developer docs.
- "API Documentation" covers the REST API pages and the published events.
- Markdown with mermaid diagrams, no site generator (publishing is phase 2).
- Counts in the docs carry their date or come from a generated table.

## DECISIONS
- FR-060 folder layout | Chose architecture/ (overview, extension-structure, testing-strategy, appsource-readiness), setup/ (dev environment and contribution, ci-cd), api/ (README, endpoints, events) and release-notes/ (index) over separate testing/ or cicd/ folders, to stay within the issue's five target folders | Reversible: yes
- FR-060 no moves | Chose index files over moving CHANGELOG.md, user-guide/releases.md or the per-FR docs, because repo_checks check 2, CHANGELOG references, plans and issue comments link to the current paths | Reversible: yes
- FR-060 identifiers | Chose to show object IDs and AL names in the developer docs, unlike the user guide | Reversible: yes
- FR-060 inventory | Chose a generated object inventory (a one-off script with the repo_checks regex) over a hand-typed list; a permanent repo_checks check is left to phase 2 to keep this change docs-only | Reversible: yes
- FR-060 duplication | Chose summaries that link the FR feature docs (FR-026, 029, 044, 045-049, 061) over copying their content, to limit drift | Reversible: yes
- FR-060 user-guide edits | Chose to update the three "FR-060 not written yet" sentences in docs/user-guide (they become false), and to leave docs/features/FR-059 unchanged as a historical record | Reversible: yes
- FR-060 README errors | Chose to record the README API route and V4 progress errors in docs/TODO.md over fixing them in this feature (no drive-by edits) | Reversible: yes

## Risks
- Drift: inventory, events and endpoints pages go stale with each FR. Mitigation: "Maintaining the developer docs" section and a docs/TODO.md item; a permanent check is phase 2. al-docs does not yet know these pages exist; changing `.claude/agents/al-docs.md` is a user decision. Raise it in the final report.
- Overclaiming verification status: many feature docs say "written, not executed" while later CI runs passed. The reviewer checks each claim against a quoted PR or run number.
- Conflicting sources (e.g. FR-048 forward checks vs NextMajor/NextMinor being `workflow_dispatch` only; the README API route; FR-001 lists three permission sets). The reviewer checks the "Conflicts found" list.
- Internal-publisher nuance: FR-029 events are `internal procedure` publishers in a Public codeunit; the doc must say partners can subscribe but not raise them, and not over-generalise to other events.
- Bound-action samples are not verified: mark TODO(verify).
- Large Markdown diff (about 18 files): the reviewer prioritises appsource-readiness.md, events.md and endpoints.md.
- CI: CICD.yaml ignores `**.md`, so only the PR build and Repo checks run. No AL build impact expected. Repo checks check 4 (xlf warning) does not fire because `app/src` does not change.

## References
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-checklist-submission
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-api-pagetype
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-develop-custom-api
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/webservices/api-endpoint-structure
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-event-types
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-publishing-events
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/business-events-overview
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-test-codeunits-and-test-methods
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/properties/devenv-testpermissions-property
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-test-explorer-vscode#view-code-coverage-information
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/al-go/algo-overview
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/administration/version-numbers
