# Development environment and contribution workflow

> Applies to Equipment Management 29.0.0.0 (not released). Facts are taken from the repository on branch feature/FR-060-developer-documentation; nothing is verified in a Business Central sandbox.

This page explains how to get the code, build it, run the repository checks locally and contribute a change. The build and test pipeline is in [CI/CD](ci-cd.md).

**In this article**
- [Prerequisites](#prerequisites)
- [Get the code and symbols](#get-the-code-and-symbols)
- [Build](#build)
- [Run the repository checks locally](#run-the-repository-checks-locally)
- [Contribution workflow](#contribution-workflow)
- [Adding things safely](#adding-things-safely)
- [Related](#related)

## Prerequisites

- Visual Studio Code with the AL Language extension.
- A Business Central 29 sandbox for symbols and manual checks. The app targets application `29.0.0.0` and runtime `18.0`. Supported versions: [Dependencies](../architecture/dependencies.md).
- Python 3.9 or newer for the repository checks (they use the standard library only).
- Optional: the GitHub CLI (`gh`) to read pull request checks and run logs.

## Get the code and symbols

1. Clone the repository. The default branch is `main`, which is protected: no direct pushes, pull requests only.
2. Open the folder `app/` in VS Code, then the folder `test/` (two AL projects, `app/` first).
3. Run **AL: Download Symbols** for each project. Symbols go to `.alpackages/`, which git ignores.
4. Optional development environments created by AL-Go (read the script headers before you run them):
   - `.AL-Go/localDevEnv.ps1`: creates a local Business Central container with Docker (Windows containers), compiles and publishes all apps and test apps.
   - `.AL-Go/cloudDevEnv.ps1`: creates a cloud sandbox and publishes the apps there (the script asks you to sign in).

## Build

- Package each project with **AL: Package**, `app/` first, then `test/` (the test app depends on the main app).
- The analyzers come from `app/.vscode/settings.json`: CodeCop, UICop and AppSourceCop, with the ruleset `.AL-Go/equipment.ruleset.json`. The test app (`test/.vscode/settings.json`) runs CodeCop and UICop only (FR-061).
- **Warnings are defects.** Fix them. Do not add `#pragma`, do not suppress a rule and do not edit the ruleset or `AppSourceCop.json`: those are user decisions.
- Never edit `app/Translations/Equipment Management.g.xlf` by hand; the build generates it.

## Run the repository checks locally

```text
python3 .github/scripts/repo_checks.py --base origin/main --branch <branch>
```

Run `git fetch origin` first so `origin/main` is current. Without `--base`, only the checks that need no diff run. The script has nine checks (from its docstring):

1. **Object IDs:** unique per object type and inside the ID range of the app that owns them.
2. **Feature branches** (`feature/FR-NNN-*`): the plan, the feature doc, the help article and a CHANGELOG entry exist.
3. **Plans:** plans changed in the PR no longer say DRAFT or "waiting for approval" in their status header.
4. **Translations (warning only):** AL code under `app/src` changed but the `.g.xlf` did not.
5. **Test coverage register (FR-047):** integrity errors fail; below-target results warn while `enforce` is false.
6. **App version policy (FR-049):** `version_check.py`.
7. **Language files (FR-055):** `xlf_sync.py check`.
8. **Schema compatibility (FR-062):** `schema_check.py`. It runs only with `--base`. It fails on breaking schema changes against `main`.
9. **Dependency matrix (FR-063):** `dependency_check.py`. DEP6 (dependency changes against `main`) runs only with `--base`.

The schema check can also run on its own. It needs the base ref:

```text
python3 .github/scripts/schema_check.py --base origin/main
```

See [FR-062](../features/FR-062-breaking-change-validation.md) for the rules and [the help article](../help/FR-062-breaking-change-validation.md) for how to fix a failure.

What a feature branch needs for check 2:

- `docs/plans/FR-NNN-<name>.md` with a `> Status:` header in its first 12 lines (not DRAFT).
- `docs/features/FR-NNN-<name>.md` and `docs/help/FR-NNN-<name>.md`.
- A `## FR-NNN <Name>` heading in `CHANGELOG.md`.

When captions, ToolTips or labels change (check 4): build `app/` with **AL: Package**, then run `python3 .github/scripts/xlf_sync.py sync`, translate the pending units (`export` and `import` commands, see the script header), run `python3 .github/scripts/xlf_sync.py check`, and commit all `.xlf` files.

## Contribution workflow

The rules are in [`CLAUDE.md`](../../CLAUDE.md). In short:

- **Branches.** Never commit to `main`. Cut a branch from an up-to-date `main`: `feature/<id>-<short-name>`, `fix/<short-name>` or `chore/<short-name>`. Merge only through a pull request into `main`; the merge is left to the repository owner.
- **Pipeline.** A change to AL code runs through the `al-feature` skill: planner, developer, reviewer, docs. The plan is committed as `docs/plans/<feature>.md` and is the handoff file. A human approves the plan before the developer starts.
- **Decisions.** Choices with a reasonable alternative are logged in [`DECISIONS.md`](../../DECISIONS.md) (the main agent writes it).
- **Stop list.** Some changes always need the owner's decision: removing, renaming or retyping published objects, upgrade code, changes to `app.json`, new permission sets, new dependencies or HTTP calls, suppressing a rule, changing the target. See `CLAUDE.md`.
- **Definition of done.** The app and the test app compile without new warnings; new tests exist and the CI result is read from the pull request (`gh pr checks <pr>`); the feature doc, help article and CHANGELOG entry exist; the repository checks pass.
- **Commits.** Commit and push only when asked. After a push, open a pull request (`Closes #<issue>`).

## Adding things safely

**A new object**
1. Take the ID from `al_getnextobjectid`, inside 50100 to 50149 (test app 50150 to 50199).
2. Name it with the `EQM ` affix and put the file in the module folder `app/src/<Module>/EQM<Name>.<Type>.al`.
3. Set `Access = Internal` unless the object is deliberately public API. Enums are `Extensible = false` unless extension is intended.
4. Add `Caption` to every field, `ToolTip` to every page field and action, `ApplicationArea`, `DataClassification` on every field (never `ToBeClassified`), and labels with suffix and `Comment`.
5. Add the object to the existing permission sets in the same change.
6. Add the captions to the translation files (see above).
7. Add a test codeunit in `test/` for every codeunit with business logic.
8. Update the [object inventory](../architecture/extension-structure.md#object-inventory-app).

**A new event**
1. Check that no standard or existing event already fits. Confirm standard symbols with `al_symbolsearch`.
2. Publish it as `[IntegrationEvent(false, false)]` in a public object. Once released its signature never changes.
3. Add a test that proves the event is raised, and update [events](../api/events.md).
4. Subscribers must not `Commit`, must exit on `Rec.IsTemporary()` for table events and must not show UI without `GuiAllowed()`.

## Related

- [`CLAUDE.md`](../../CLAUDE.md) and the `al-patterns` skill (`.claude/skills/al-patterns/SKILL.md`, local, not tracked in git)
- [CI/CD process](ci-cd.md)
- Feature docs: [FR-048](../features/FR-048-automated-build-pipeline.md), [FR-061](../features/FR-061-code-quality-compliance.md)
- Microsoft Learn: [Get started with AL](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-get-started), [AL-Go for GitHub overview](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/al-go/algo-overview)
