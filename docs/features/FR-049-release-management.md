# FR-049 Release Management

## Purpose
Makes the version of the app predictable and automatic (issue #90). The version has four parts, Major.Minor.Build.Revision. Major and Minor are set in the app. Build and Revision are set by the build pipeline on every run. The app keeps version 29.0.0.0. This change does not bump it.

The change is build tooling only. No AL file, no `app.json` and no permission set changes. No AL-Go system workflow is edited.

Status: implemented on branch `feature/FR-049-release-management`, not committed, not merged. Plan: `docs/plans/FR-049-release-management.md` (status approved). Target: AppSource.

## Versioning policy
| Part | Set by | Value now | Rule |
|---|---|---|---|
| Major | `version` in `app/app.json` | 29 | The Business Central major version of `application` (29.0.0.0). Raised only with `application`, as a user decision. |
| Minor | `version` in `app/app.json` | 0 | Raised by the user for a feature release to AppSource. |
| Build | AL-Go CI/CD | Run number, for example 57 | Stamped on every CI/CD run on `main`. It goes up with each run. |
| Revision | AL-Go CI/CD | Run attempt minus 1 | 0 on the first attempt of a run. |

Build and Revision in `app/app.json` stay at 0. The pipeline stamps them. Agents do not edit `app/app.json` or `test/app.json`.

The test app keeps its own version (1.0.x). It is never submitted to AppSource, so its version does not matter for a release. Only its dependency on the app is checked (VER5).

## Where to see the version
- **Build output.** Artifact names carry the Major.Minor from the project settings and the build number: `equipment-management-main-Apps-29.0.<run>.0`. The Apps, TestApps, TestResults and BuildOutput artifacts use the same pattern.
- **The `.app` file.** Its file name and its version are the same as the app version, for example `Miguel Carvalho_Equipment Management_29.0.<run>.0.app`.
- **Business Central.** Extension Management shows the installed version of the app. See [Install and update extensions](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/administration/version-numbers).

Before FR-049 the artifact name carried `1.0.<run>.0` and the `.app` carried `29.0.<run>.0`. The two numbers did not match. The `.app` version was always right. FR-049 aligns the artifact names with it.

## Release procedure
Follow these steps for a release to AppSource. This is the procedure. It has not been run for this repository yet.

1. Make sure the latest CI/CD run on `main` is green.
2. Check the FR-044 upgrade checklist for every release after 29.0.0.0. Each release that changes data needs an upgrade codeunit. See `docs/features/FR-044-data-upgrade-support.md`, "How to add an upgrade step".
3. Run the **Create release** workflow manually from the Actions tab with these inputs:
   - `buildVersion`: `latest` (the artifacts of the latest green CI/CD run on `main`);
   - `tag`: `<Major>.<Minor>.<Build>` of the promoted build, for example `29.0.57`;
   - `name`: `Equipment Management 29.0.57`;
   - `releaseType`: `Release`;
   - `updateVersionNumber`: `+0.1`.
4. Review and merge the version-bump pull request that the workflow opens. The version checks (VER1 to VER7) run on it.
5. Upload the `.app` to Partner Center manually. Publishing to AppSource is not automated (see "Out of scope").

Partner Center rejects a second upload of the same version with different content. Strategy 0 gives each CI/CD run a new Build number, so each run has a unique version.

## Bump without a release
Use the **Increment Version Number** workflow to raise the version without creating a release. Enter `+0.1` to raise the Minor, or the full Major.Minor, for example `29.1`. The workflow opens a pull request with the change. Review and merge it. The version checks run on it.

## Version check (Repo checks, check 6)
`.github/scripts/version_check.py` runs in Repo checks on every pull request. Each message starts with its rule ID.

| Rule | Level | What it checks |
|---|---|---|
| VER1 | Error | `app/app.json` (and `test/app.json` when present) has a `version` with four numbers. |
| VER2 | Error | Build and Revision in `app/app.json` are 0. AL-Go stamps them. |
| VER3 | Error | `repoVersion` in `.AL-Go/settings.json` equals the Major.Minor of `app/app.json`. |
| VER4 | Error | `versioningStrategy` in `.AL-Go/settings.json` is 0, when the key is present. |
| VER5 | Error | `test/app.json` depends on the app, and the minimum version is not above the app version. Skipped with a note when there is no `test/app.json`. |
| VER6 | Error | On a pull request: the app version is not lower than on the base branch. If the base cannot be read, a warning is printed instead. |
| VER7 | Warning | On a pull request: Major or Minor was raised. It reminds you to check the upgrade steps and the release notes. |

The summary line is `App version: <version> (Major.Minor from app/app.json; Build and Revision stamped by AL-Go CI/CD, versioningStrategy 0)`. On the current app it reads `App version: 29.0.0.0`.

The script is stdlib Python and runs on Python 3.9 or later.

## Verification gate
Before the change was built, these AL-Go facts were checked against the AL-Go for GitHub sources at tag v10.0. The gate was read-only.

**0a. `versioningStrategy` and `repoVersion` (AL-Go Scenarios/settings.md, v10.0).**
- Strategy 0: Major and Minor are read from each `app.json`.
- Build is the GitHub `run_number` of the current workflow run, plus `runNumberOffset`. When another workflow starts the build (for example Test Next Major), that workflow's `run_number` is used.
- Revision is `run_attempt` minus 1.
- `repoVersion` (default 1.0) is used in artifact names: `<project>-Apps-<repoVersion>.<build>.<revision>`. It is used as Major.Minor for individual apps only with strategy +16, which this project does not use.
- `runNumberOffset` applies to strategies 0, 3 and 15. It can be negative.
- `skipUpgrade` ignores previous releases. `doNotPerformUpgrade` skips only the upgrade phase. It still passes the previous release apps to the AppSourceCop breaking-change check.

**0b. Does IncrementVersionNumber update `repoVersion` (AL-Go-Actions v10.0, IncrementVersionNumber.ps1).**
- It updates `repoVersion` in the project settings file when the key exists there. Otherwise it updates the repo-level file when the key is there. Otherwise it creates the key in the project settings file.
- `repoVersion` is now in `.AL-Go/settings.json`. So the plan applies as written and VER3 is an error.

**0c. Artifacts and build log before FR-049 (last completed `main` CI/CD run 44437945581).**
- Artifacts: `equipment-management-main-Apps-1.0.92.0`, plus BuildOutput, TestApps and TestResults.
- Build log: `Using Version 29.0.92.0`, and the `.app` file `Miguel Carvalho_Equipment Management_29.0.92.0.app`.
- So the artifact name said 1.0 and the `.app` said 29.0. FR-049 changes the artifact name to 29.0.

Gate result: all three checks match the plan. No fallback was needed.

## Verification status
- **Gate 0a, 0b, 0c:** done. Findings above.
- **Version check script:** `.github/scripts/version_check.py`, called as check 6 of `.github/scripts/repo_checks.py`.
- **Unit tests:** `.github/scripts/test_version_check.py`, 22 tests, all OK, run locally in this session with Python 3.9.6.
- **Coverage check tests:** `.github/scripts/test_coverage_check.py`, 27 tests, all OK, run locally in this session.
- **Repo checks script:** `repo_checks.py not run by al-docs`. The main agent runs it after this change.
- **CI result:** Not verified: CI result pending. It is known after the push.
- **New artifact names:** Not verified: they appear after the push and the next CI/CD run on `main`.
- **AL compile and AL tests:** not needed. This change has no AL change.
- **AppSource validation:** No separate AppSource validation ran. The reviewer checked the change against the plan and the AppSource rules.
- **Review:** APPROVED by al-reviewer.

## Open items
- **m1 (reviewer MINOR, open):** `version_check.py` crashes when `app/app.json` or `test/app.json` contains valid JSON that is not an object, for example `[]`. The script catches only parse errors. Fix: check that the loaded value is a dict before reading it. The fix needs a new unit test.
- The first release is phase 2. It is a user decision. See `docs/TODO.md`, section "FR-049 checks".

## Out of scope
- Bumping the version in `app/app.json` or `test/app.json`. The app stays at 29.0.0.0.
- Running **Create release** or **Increment Version Number**. This is the user's decision.
- Changes to AL-Go system workflows. The update tool would overwrite them.
- Publishing to AppSource and Partner Center delivery, and their secrets.
- Release branches, the hotfix procedure, the AppSourceCop baseline (FR-062) and app signing.

## Related
- Help article: `docs/help/FR-049-release-management.md`
- Changelog: `CHANGELOG.md`, entry FR-049
- Plan: `docs/plans/FR-049-release-management.md`
- Check: `.github/scripts/version_check.py`
- Unit tests: `.github/scripts/test_version_check.py`
- Pipeline and Repo checks: `docs/help/FR-048-automated-build-pipeline.md`
- Upgrade steps: `docs/features/FR-044-data-upgrade-support.md`
- Microsoft Learn: [Version numbers](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/administration/version-numbers), [App identity](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-app-identity), [AL-Go for GitHub overview](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/al-go/algo-overview)
