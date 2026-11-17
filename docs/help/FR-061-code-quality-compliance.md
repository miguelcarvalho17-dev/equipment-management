# Code quality checks (contributor help)

This article is for people who change this repository. It is not an end-user article. It explains which code analyzers run on the app and the test app, and which warnings are known and accepted for now.

## Which analyzers run
| Folder | Local (VS Code) | CI (AL-Go, Pull Request Build) |
|---|---|---|
| `app` (main app) | CodeCop, UICop, AppSourceCop | CodeCop, UICop, AppSourceCop |
| `test` (test app) | CodeCop, UICop | CodeCop, UICop. Whether AppSourceCop also runs in CI is not verified yet |

The settings are in `app/.vscode/settings.json` and `test/.vscode/settings.json`. Both point at the ruleset `.AL-Go/equipment.ruleset.json`. The CI setting is `enableCodeAnalyzersOnTestApps` in `.AL-Go/settings.json`. The AppSourceCop check for the EQM affix is in `app/AppSourceCop.json`.

Do not add `${AppSourceCop}` to `test/.vscode/settings.json`. With it on, the test app does not produce a `.app` because `test/app.json` lacks the `TranslationFile` feature (AS0015).

## What a clean result looks like
- No errors.
- No AA* (CodeCop) or AW* (UICop) warnings from your code.
- No AS* warnings from your code.
- The only warnings on the main app are the known ones listed below.

Treat any other warning as a defect. Fix it in the code. Do not add a `#pragma` or change the ruleset to hide it.

## Known warnings (exception register)
These warnings come from the app manifest and the AppSource registration, not from code. They stay until the release steps in `docs/features/FR-061-code-quality-compliance.md` are done.

| Warning | Where | Why it stays |
|---|---|---|
| AS0051 | `app/app.json` (privacy statement, EULA, help, logo, context-sensitive help URL) | Needs real URLs and a logo |
| AS0052 | `app/app.json` (url) | Needs the real product URL |
| AS0081 | `app/app.json` (`internalsVisibleTo`) | The test app needs it |
| AS0084 | `app/app.json` (ID range) | The 50100-50149 range is a demo range |
| AS0092 | `app/app.json` (Application Insights) | No connection string yet |

The ruleset `.AL-Go/equipment.ruleset.json` lowers some of these to warnings. Its description says it must be removed before a real AppSource submission. A clean build here does not mean the app is ready for submission.

## Check the result
1. Open the pull request and read the "Pull Request Build" log under the **Actions** tab.
2. Check that the analyzers ran for both apps, and that only the known warnings appear.
3. If AS0015 appears as an error, the build is red. Do not change the ruleset. Tell the maintainer; they decide whether to add `TranslationFile` to `test/app.json`.

TODO(verify): the first CI run after the push has not been checked. Record the result in the feature doc.

## Test app
The test app runs CodeCop and UICop. Test code must follow the same rules as the app code. Two findings were fixed in the test app: a `using` order and a filter on a field without a key. Neither changed what the tests check.

Open minor item: one API test now checks the record count under a primary-key filter. This is not an analyzer warning and is not changed here.
