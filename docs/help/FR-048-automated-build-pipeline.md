# Automated build pipeline (contributor help)

This article is for people who change this repository. It is not an end-user article. Every pull request into `main` is built and checked automatically by AL-Go for GitHub.

## What runs
| When | What happens |
|---|---|
| You open or update a pull request into `main` | "Pull Request Build" compiles the app and test app, runs CodeCop, UICop and AppSourceCop on the app, and runs the tests. "Repo checks" validates object IDs, plan header and feature files. |
| You push to `main`, `release/*` or `feature/*` | CI/CD runs the same build. It is skipped for pushes that only change markdown files or workflow files other than `CICD.yaml`. |

The analyzers run on the main app only, not on the test app.

## Check the result
1. Open the pull request and read the checks at the bottom. "Pull Request Status Check" and "Repo checks" should be green.
2. For details, open the run under the **Actions** tab and read the build log. Compiler and analyzer warnings are listed there; treat them as defects.
3. A compile error, an analyzer error or a failing test turns the build red. Warnings alone do not (AS0051, AS0052 and AS0084 are lowered to warnings in `.AL-Go/equipment.ruleset.json`).

TODO(verify): analyzer output in CI has not been checked yet.

## Download the build output
Open the run and download the artifacts: Apps, TestApps, TestResults and BuildOutput. Artifact names end in `1.0.<run>.0`. The `.app` inside keeps the version from `app.json` (29.0.x).

## Create a release
Run the **Create release** workflow manually from the Actions tab and give it a version tag. It attaches the artifacts of the latest green CI/CD run on `main` to a GitHub release and does not rebuild. Make sure that run is green first.

TODO(verify): this workflow has not been run for this repository.

## Change pipeline settings
Edit `.AL-Go/settings.json`, not the workflow files. AL-Go overwrites system workflows when it updates. Settings are described at https://aka.ms/ALGoSettings.

## Repo checks on feature branches
A branch named `feature/FR-NNN-...` needs a plan in `docs/plans/`, a feature doc in `docs/features/`, a help article in `docs/help/` and a `## FR-NNN` section in `CHANGELOG.md`. Otherwise "Repo checks" fails. The plan's `> Status:` header must not say DRAFT or waiting for approval.
