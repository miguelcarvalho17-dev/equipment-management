# Dependency checks (contributor help)

This article is for people who change this repository. It is not an end-user article.

The matrix of dependencies, the minimum Business Central version (29.0) and the upgrade notes are on one page: [Dependencies and supported versions](../architecture/dependencies.md). The feature doc is [FR-063](../features/FR-063-dependency-management.md).

## Before you add a dependency or raise the Business Central version
Both are changes to `app.json`, which is on the stop list: they need the owner's decision and a line in `DECISIONS.md`. Read the [upgrade notes](../architecture/dependencies.md#upgrade-notes) first. They list the steps, for example raising `application` and `runtime` in both manifests, the Library Assert minimum, `version` and `repoVersion`, and the Manifest values table.

## What a failure looks like
The check runs as check 9 of **Repo checks** on every pull request. A message starts with the rule ID.

| Rule | What fails | How to fix |
|---|---|---|
| DEP1 | `app/app.json` is missing, a manifest is not a JSON object, or a manifest has no `application` or `runtime` | Fix the JSON or restore the property in the manifest |
| DEP2 | The test app has another `application` or `runtime` than the app | Set the same values in both manifests |
| DEP3 | Base Application or System Application is listed in `dependencies` | Remove it. The `application` property already covers it. |
| DEP4 | The page has no matching row in the Manifest values table, or lacks a dependency id | Edit the table in `docs/architecture/dependencies.md` to the row printed in the message, or add the dependency to the matrix |
| DEP5 | A Microsoft test library has a malformed version, or a version above the test app's `application` | Use `Major.Minor.Build.Revision`, not above `application` |
| DEP6 (warning) | `application`, `platform`, `runtime` or a dependency changed against `main` | Make sure the change was approved and logged in `DECISIONS.md`, and that the matrix and upgrade notes are updated |

## Run it locally
```text
python3 .github/scripts/dependency_check.py --base origin/main
```
Run `git fetch origin` first. Without `--base`, DEP6 does not run. Expected output ends with `Dependency check: OK`. To run the tests: `python3 .github/scripts/test_dependency_check.py`.
