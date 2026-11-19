# Release management and versions (contributor and release manager help)

This article is for people who change this repository or release the app. It is not an end-user article. The rules are in `docs/features/FR-049-release-management.md`.

## Which version am I running?
The version has four parts: Major.Minor.Build.Revision. The app is 29.0.0.0 today.
- **Major and Minor** come from `version` in `app/app.json`.
- **Build** is the run number of the CI/CD run on `main`. It goes up with each run.
- **Revision** is the run attempt minus 1. It is 0 unless a run was re-run.

To see the version of a build, open the run under the **Actions** tab. The artifact names end in `29.0.<run>.0`, for example `equipment-management-main-Apps-29.0.57.0`. The `.app` inside has the same version. In Business Central, Extension Management shows the installed version.

TODO(verify): the artifact names with `29.0` have not been seen yet. They appear after the change is pushed and merged, and after the next green CI/CD run on `main`.

## Create a release
Do this only after the latest CI/CD run on `main` is green.

1. Check the upgrade steps. Every release after 29.0.0.0 needs an upgrade codeunit if data changes. See `docs/features/FR-044-data-upgrade-support.md`, "How to add an upgrade step".
2. Open the Actions tab and run **Create release** manually. Enter:
   - `buildVersion`: `latest`, or an explicit build version if the latest run is not the one you want;
   - `tag`: `<Major>.<Minor>.<Build>` of the build, for example `29.0.57`;
   - `name`: `Equipment Management 29.0.57`;
   - `releaseType`: `Release`;
   - `updateVersionNumber`: `+0.1`.
3. Review and merge the version-bump pull request that the workflow opens. Repo checks run the version checks on it.
4. Upload the `.app` to Partner Center yourself. The pipeline does not publish to AppSource.

Run the first release only after a green CI/CD run on `main` that has the new `29.0` artifact names. Otherwise pass an explicit `buildVersion`.

TODO(verify): the **Create release** workflow has not been run for this repository.

## Raise the version without a release
Run **Increment Version Number** from the Actions tab. Enter `+0.1` to raise the Minor, or the full new version, for example `29.1`. The workflow opens a pull request. Review and merge it.

Only raise the Major when the Business Central major version of `application` changes. This is a decision for the product owner, not a routine change.

## Version check errors
Repo checks reports these rules. Each message starts with the rule ID.

| Message | What it means | How to fix it |
|---|---|---|
| VER1 | `app/app.json` or `test/app.json` has no version with four numbers, or the file is missing. | Set `version` to four numbers, for example `29.0.0.0`. |
| VER2 | Build or Revision in `app/app.json` is not 0. | Set the last two numbers to 0. AL-Go stamps them in the build. |
| VER3 | `repoVersion` in `.AL-Go/settings.json` does not match the Major.Minor of `app/app.json`. | Set `repoVersion` to the same Major.Minor, for example `"29.1"`. Running **Increment Version Number** does this for you. |
| VER4 | `versioningStrategy` in `.AL-Go/settings.json` is not 0. | Set it to 0, or remove the key. This project uses strategy 0. |
| VER5 | `test/app.json` depends on the app with a version that is higher than the app version, or has no dependency on the app. | Lower the dependency version in `test/app.json` to the app version or below. Check that the app id is the same as in `app/app.json`. |
| VER6 | The app version is lower than on `main`. | Do not lower the version. Use a higher version. |
| VER7 (warning) | Major or Minor was raised. | Before you release, check the upgrade steps and write the release notes in `CHANGELOG.md`. The warning does not block the pull request. |

A warning is printed as a GitHub annotation. Errors fail Repo checks.

## Pull request has no checks
A pull request that a workflow opens with the built-in token does not start other workflows. This includes the version-bump pull request from **Create release** or **Increment Version Number**. It can show no checks.

To start the checks, close the pull request and open it again. Then the checks run.

## Never rename `CICD.yaml`
The build number comes from the run number of the `CICD.yaml` workflow. If you rename or re-create the file, the run number starts again, and the Build numbers go down.

If this happens, set `runNumberOffset` in `.AL-Go/settings.json` to a value that keeps the new numbers above the old ones. Ask the product owner for the value.

## Related
- Feature doc: `docs/features/FR-049-release-management.md`
- Pipeline and Repo checks: `docs/help/FR-048-automated-build-pipeline.md`
- Upgrade steps: `docs/features/FR-044-data-upgrade-support.md`
- Plan: `docs/plans/FR-049-release-management.md`
- Changelog: `CHANGELOG.md`, entry FR-049
