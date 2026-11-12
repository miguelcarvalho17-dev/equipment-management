# FR-048 Automated Build Pipeline

> Status: approved (user answered Q1 yes, Q2 no, Q3 yes). Source: GitHub issue #89. Branch `feature/FR-048-automated-build-pipeline`. No AL code. No events report (no standard behavior touched).
> Scope: audit the existing AL-Go for GitHub setup (AppSource template, AL-Go-Actions v10.0) against the issue and apply only settings changes. AL-Go system workflows are NOT edited (UpdateGitHubGoSystemFiles overwrites them).

## Goal
Every PR into `main`, every push to `main` and every release is validated automatically: checkout, restore dependencies, compile, CodeCop, UICop, AppSourceCop, run the test app, publish artifacts. Most of this already works. This feature records the audit, closes the gaps through `.AL-Go/settings.json` and documents the pipeline.

## Approach and rejected alternatives
Audit result (from the repo files; the run history is checked in step 1):
| Requirement | Where it happens today | Status |
|---|---|---|
| Checkout | `actions/checkout` in every job | OK |
| Restore dependencies | `_BuildALGoProject.yaml`: DetermineArtifactUrl (`artifact` not set, so latest `us` sandbox, BC 29 for `application` 29.0.0.0), DownloadProjectDependencies; RunPipeline installs the test toolkit for the Library Assert dependency | OK |
| Compile | RunPipeline (container), `appFolders` [app], `testFolders` [test] | OK |
| CodeCop | `enableCodeCop` not set (AL-Go default false) | **GAP** |
| UICop (CLAUDE.md requires it) | `enableUICop` not set (default false) | **GAP** |
| AppSourceCop | on through `type` "AppSource App" (implicit default); `appSourceCopMandatoryAffixes` [EQM]; `rulesetFile` lowers AS0051/AS0052/AS0084 to warnings | OK, but implicit |
| Run tests | `doNotRunTests` default false; the test app runs (FR-023: 15 tests passed in CI). A failing test fails the build | OK (FR-045 adds coverage only) |
| Publish artifacts | Apps, TestApps, TestResults, BuildOutput uploaded per build (PR: short retention; CI/CD: repo default) | OK |
| Trigger PR | `PullRequestHandler.yaml` (pull_request to main, no path filter) plus custom `RepoChecks.yaml` | OK |
| Trigger push to main | `CICD.yaml` push on main, release/*, feature/*; `**.md` is ignored | OK |
| Trigger release creation | `CreateRelease.yaml` (manual): attaches artifacts of the latest green CI/CD run on main to a GitHub release; it does not rebuild | OK under assumption A1 (Q1) |
- Chosen: add `enableCodeCop`, `enableUICop` and an explicit `enableAppSourceCop` (all true) to `.AL-Go/settings.json`. Check the run history and branch protection; write docs.
- Rejected: editing CICD/PullRequestHandler/_Build YAML. They are AL-Go system files and an update overwrites them.
- Rejected: `failOn: "warning"`. The ruleset deliberately lowers AS0051/52/84 to warnings so CI stays green until the AppSource TODO items are done, so this setting would make every build red.
- Rejected: a custom `on: release` workflow that rebuilds. It duplicates CreateRelease, which already ships the verified main build (unless Q1 = B).
- Rejected: `trackALAlertsInGitHub` (SARIF upload) and `CICDPushBranches` trimming. The issue does not ask for them.

## Objects
No AL objects and no IDs. Files: `.AL-Go/settings.json` (modify), `docs/features/FR-048-automated-build-pipeline.md`, `docs/help/FR-048-automated-build-pipeline.md` (new), `CHANGELOG.md`, `docs/TODO.md` (modify).

## Data model and upgrade impact
None. The app version stays 29.0.0.0. No upgrade code. `versioningStrategy` 0 (the default) keeps major.minor from each app.json for the .app files (Equipment Management 29.0.x). The artifact names use `repoVersion` 1.0.<run>.0 (e.g. `equipment-management-main-Apps-1.0.26.0`).

## Events
None subscribed or published.

## Permissions
None (no BC objects). GitHub: no workflow `permissions:` change.

## Compatibility
No public AL API changes, so there is no breaking-change risk. Turning on CodeCop and UICop adds analysis for the main app only: `enableCodeAnalyzersOnTestApps` defaults to false. Decision: it is NOT enabled in this feature (extra scope; AppSourceCop on the test app would likely go red). Test-app analysis is an optional follow-up chore. The new analyzers can add warnings on the main app. With `failOn` at its default (error), the build fails only on error-severity diagnostics. AppSourceCop runs without a baseline until the first GitHub release exists (DownloadPreviousRelease finds none).

## Implementation steps
1. Read-only audit (needs `gh`; the planner had no shell). `gh run list --workflow CICD.yaml --branch main -L 5`, `gh run list --workflow PullRequestHandler.yaml -L 5`, `gh run list --workflow RepoChecks.yaml -L 5`. For the latest main run: `gh run view <id> --log` and look for the analyzer flags passed to the compiler (CodeCop/UICop/AppSourceCop), the AS0051/AS0084 warnings (these prove AppSourceCop runs), and the test totals (expect codeunits 50178 and 50179, 15 + 12 tests). Then `gh api repos/{owner}/{repo}/actions/runs/<id>/artifacts` (expect Apps, TestApps, TestResults). Record the findings in the feature doc.
2. `gh api repos/{owner}/{repo}/branches/main/protection` and record the required status checks. Expected: "Pull Request Status Check" and "Repo checks". If they are missing, do NOT change the settings. Report it to the user (Q3).
3. `.AL-Go/settings.json`: add `"enableCodeCop": true`, `"enableUICop": true`, `"enableAppSourceCop": true` after `rulesetFile`. Change nothing else. Validate with `python3 -m json.tool .AL-Go/settings.json`. No YAML changes, so actionlint is optional (run it on the workflows only if it is installed).
4. Docs: the feature doc (audit table, trigger matrix, how to read results, what is not verified), a short help article for contributors (where to find the status and artifacts, how to create a release; `repo_checks.py` requires the file for FR branches), a CHANGELOG `## FR-048 Automated Build Pipeline` section (version stays 29.0.0.0), and in `docs/TODO.md` tick or reword line 171 (the AL-Go CI part).
5. After the user asks to push: check the CI/CD run on the branch and the PR Build run (scenarios 1, 4, 5). List any new CodeCop/UICop warnings in the feature doc. Fixing them is a follow-up `chore/` branch unless they are errors.
6. Set the plan status to approved and implemented (repo check 3).

## Test scenarios
Done by the tester from `gh` output. GitHub runs cannot be reproduced locally on macOS (Windows + Docker).
1. Given a PR into main, when it is opened or updated, then "Pull Request Build" runs Build (compile, analyzers, tests), "Pull Request Status Check" is green and "Repo checks" is green.
2. Given step 3 is pushed, when CI/CD runs, then the build log shows CodeCop, UICop and AppSourceCop active for the app (AS0051/AS0084 still appear only as warnings).
3. Given the last green main run, then its artifacts include Apps, TestApps and TestResults (artifact names use 1.0.<run>.0; the Equipment Management .app inside is version 29.0.x, and that is what is checked), and the test results contain 50178 and 50179 with 0 failures.
4. (negative, evidence) Given a failing test or a compile error, then the build is red and the status check fails. Use an earlier red run from history as evidence. Do not create a broken branch without user consent.
5. Given a merge into main with AL changes, when it lands, then CI/CD runs on main. Given a markdown-only push, then CI/CD is skipped (paths-ignore, expected).
6. (negative) Given an FR branch without a help article, then Repo checks fails (existing behavior, covered by `repo_checks.py`).
7. Given a green main run, when CreateRelease is run with a semver tag, then a GitHub release has the app artifacts attached. NOT executed in this feature because it creates a real release (Q2).

## Risks and open questions
- Q1 Release trigger. A (recommended): the manual CreateRelease, which promotes the validated main build, counts as "Release Creation". B: also add a custom workflow on `release: published` that rebuilds and tests.
- Q2 Run a first CreateRelease (for example 29.0.0) now to prove scenario 7 and give AppSourceCop a baseline? Recommended: no, defer to the first real release.
- Q3 If branch protection lacks the two required checks, should the user add them in the GitHub settings? Recommended: yes. Agents do not change repo settings.
- R1 Analyzers run on the main app only (`enableCodeAnalyzersOnTestApps` defaults to false). Decision: not enabled here (extra scope, AppSourceCop on the test app would likely go red). Test-app analysis is an optional follow-up chore. Warnings found on the main app go to a follow-up chore (CLAUDE.md treats warnings as defects).
- R2 FR-045 has no plan, doc or changelog entry in the repo; its issue status was not checked (no shell). Assumed FR-045 extends test coverage and is not needed for the Run Tests step, because the test app already runs in CI. The CHANGELOG says FR-024's 12 tests were "NOT run". Confirm them in step 1.
- R3 `artifact` is not pinned: the latest sandbox is used. When BC 30 ships, CI moves to it. Assumed this is acceptable because NextMajor/NextMinor exist for forward checks. Pin to 29 only if CI breaks.
- Assumed AppSourceCop is already on because the AL-Go type is "AppSource App". It is made explicit anyway, so this does not depend on the default.
- Assumed the help article is contributor-facing, because `repo_checks.py` requires it for every FR branch.
