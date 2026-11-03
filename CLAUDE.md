# Business Central extension project

## Mode (change this one line when you switch)
DELIVERY_MODE: AppSource
<!-- Switch to "PTE" when you move to per-tenant extensions. Agents and skills read this line. -->

## Project facts (fill in)
- App name / publisher / affix: Equipment Management / Miguel Carvalho / "EQM" prefix on all objects and fields
- Target BC version / runtime: BC 29 (application 29.0.0.0), runtime 18.0
- Object ID range: app 50100-50149, test app 50150-50199 (demo range for the portfolio; AppSource would need a registered range)
- Apps: `/app` (main), `/test` (test app). Test app depends on the main app.
- Documentation: feature docs in docs/features/, user help in docs/help/ (AppSource), changelog in CHANGELOG.md
- Symbols: .alpackages (download in VS Code for the target version)
- BASEAPP_SOURCE_PATH: <optional: local path to base app source, if you have it>
- Build command: AL: Package in VS Code (run per folder: app, then test)
- Test run command: AL Test Runner / run test codeunits from the test app in a sandbox
- Analyzers on: CodeCop, UICop, plus AppSourceCop (AppSource) or PerTenantExtensionCop (PTE)

## Workflow
create feature branch (local + remote, see Git branching) -> [event-finder, if standard behavior is touched] -> planner -> (human approves plan) -> developer -> reviewer -> tester -> documenter -> [appsource-validator, AppSource mode only].
Handoffs happen through `docs/plans/<feature>.md`. Subagents do not share chat context,
so everything they need must be in that file or in the repo.

## Git branching
- `main` is protected on GitHub: no direct commits or pushes, pull requests only (applies to admins too).
- Never commit to `main`. Before any change, work on a branch cut from an up-to-date `main`:
  `feature/<id>-<short-name>` (e.g. `feature/FR-002-equipment-assignment`), `fix/<short-name>`, or `chore/<short-name>`.
- Create the branch first, before any planning, event search or other work on a feature: name it after the feature, cut it from an up-to-date `main`, and create it both locally and on GitHub (`git checkout -b <branch>` then `git push -u origin <branch>`). Pushing this empty branch is the one push allowed without asking; it is what makes the feature branch exist remotely from the start.
- Merge into `main` only through a pull request. Do not merge or push to `main` yourself; open the PR and leave the merge to the user.
- Commit and push only when the user asks.
- Once a branch is merged into `main`, delete it locally and on GitHub (`git branch -d <branch>` and `git push origin --delete <branch>`), after updating local `main` with `git checkout main && git pull`.

## Hard rules (all agents)
- Never modify base application objects. Extend only through extensions and events.
- Never invent object IDs. Take the next free ID inside the range above.
- Treat compiler and analyzer warnings as defects; fix them, don't suppress them.
- If a task is ambiguous or the plan is missing, stop and ask instead of guessing.
- Read `.claude/skills/al-conventions/SKILL.md` before writing or reviewing AL.
