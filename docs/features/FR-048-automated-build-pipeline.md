# FR-048 Automated Build Pipeline

> **Sandbox verification (2026-11-24):** verified in a Business Central sandbox by the project owner; no defects were reported. The detailed results are not recorded here, so statements below that say "not verified" or carry `TODO(verify)` predate this run.

## Purpose
Every pull request into `main`, every push to `main` and every release is validated by AL-Go for GitHub (GitHub issue #89). The pipeline already compiled the app and ran the test app. This feature records the audit and turns on CodeCop and UICop, and makes AppSourceCop explicit, in `.AL-Go/settings.json`. No AL code and no workflow YAML changed.

Status: settings change made on branch `feature/FR-048-automated-build-pipeline`, not committed at the time of writing. **Not verified:** analyzer output in CI (needs a run after the push), branch protection and run history (the audit commands in the plan were not run by the documenter). **Tests:** none added, no AL code changed. App version stays 29.0.0.0. No upgrade code, no event.

## What changed
File `.AL-Go/settings.json`, after `rulesetFile`:

| Setting | Value | Effect |
|---|---|---|
| `enableCodeCop` | `true` | Runs CodeCop on the main app (default is false). |
| `enableUICop` | `true` | Runs UICop on the main app (default is false). CLAUDE.md requires it. |
| `enableAppSourceCop` | `true` | Makes AppSourceCop explicit. It was already on through `type` "AppSource App". |
| `enableCodeAnalyzersOnTestApps` | `false` | Added by FR-061 as `true`, then set to `false` after PR #132 failed on the test app (AS0015 and AS0054). CI does not analyse the test app. Restoring it needs `TranslationFile` in `test/app.json` and `test/AppSourceCop.json` (see Pipeline overview). |

Setting reference: https://aka.ms/ALGoSettings#enableappsourcecop

## Pipeline overview
Taken from the repository files, not from run logs.

| Step | Where | Notes |
|---|---|---|
| Checkout | `actions/checkout` in every job | |
| Restore dependencies | `_BuildALGoProject.yaml` (artifact URL, project dependencies) | `artifact` is not pinned: the latest `us` sandbox for application 29.0.0.0. When a newer major ships, CI may move to it. |
| Compile | RunPipeline, `appFolders` [app], `testFolders` [test] | |
| Analyzers | CodeCop, UICop, AppSourceCop on the main app. The test app is not analysed in CI | Since FR-061, `enableCodeAnalyzersOnTestApps` is `false` (plan Amendment 2). With it `true`, AL-Go applied AppSourceCop to the test app and failed the build on AS0015 and AS0054 (PR #132). Scope and exception register: `docs/features/FR-061-code-quality-compliance.md`. |
| Tests | Test app (codeunits 50178 and 50179) | A failing test fails the build. |
| Artifacts | Apps, TestApps, TestResults, BuildOutput | |

Ruleset `.AL-Go/equipment.ruleset.json` lowers AS0051, AS0052 and AS0084 to warnings. `failOn` is left at its default (error), so only error-severity diagnostics fail the build. AppSourceCop has no baseline until the first GitHub release exists. `appSourceCopMandatoryAffixes` is [EQM].

## Triggers
| Event | Workflow | Notes |
|---|---|---|
| Pull request into `main` | `PullRequestHandler.yaml` ("Pull Request Build", status check "Pull Request Status Check") and `RepoChecks.yaml` ("Repo checks") | No path filter. |
| Push to `main`, `release/*`, `feature/*` | `CICD.yaml` | Skipped when only `**.md` or `.github/workflows/*.yaml` (other than `CICD.yaml`) changed. |
| Release | `CreateRelease.yaml` (manual) | Attaches the artifacts of the latest green CI/CD run on `main` to a GitHub release. It does not rebuild. Counted as "Release Creation" (plan Q1: yes). |
| Forward checks | `NextMajor.yaml`, `NextMinor.yaml` | Inherit the new analyzer flags, so they also run CodeCop, UICop and AppSourceCop. |

## Behavior notes
- Version numbers: the `.app` files keep the app.json version (29.0.x, `versioningStrategy` 0). The artifact names use the repo version `1.0.<run>.0`, for example `equipment-management-main-Apps-1.0.26.0`. The two numbers are independent.
- AL-Go system workflows are not edited, because UpdateGitHubGoSystemFiles overwrites them.
- Rejected: `failOn: "warning"` (would turn every build red while AS0051/52/84 are open), a custom rebuild-on-release workflow (duplicates CreateRelease), SARIF upload and trimming `CICDPushBranches` (not requested).

## Events
None subscribed or published.

## Not verified
- Analyzer output in CI. Local analysis under FR-061 shows 0 errors on both apps, and the main app has only the exception-register warnings. TODO(verify): the next PR build after the fix must show CodeCop, UICop and AppSourceCop for the main app, with only the exception-register warnings, and a green build (FR-061, V4).
- Run history and branch protection (required checks "Pull Request Status Check" and "Repo checks"). TODO(verify). If they are missing, the user adds them in the GitHub settings.
- No tests added: no AL code changed, so the tester was skipped.
- No release run: CreateRelease was not executed (plan Q2: no), so release attachment is untested.
- Test app analysis (FR-061): not run in CI. The first PR build with it on (PR #132, run 43998572748) failed on the test app: AL-Go applied AppSourceCop, and AS0015 and AS0054 were errors. The user turned the setting off. The ruleset and `test/app.json` were not changed. CodeCop and UICop still run on the test app locally.
- FR-024's 12 tests in codeunit 50179 were noted as not run in the CHANGELOG. Their CI result is not confirmed here.
