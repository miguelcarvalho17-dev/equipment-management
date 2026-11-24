# FR-061 Code Quality Compliance

> **Sandbox verification (2026-11-24):** verified in a Business Central sandbox by the project owner; no defects were reported. The detailed results are not recorded here, so statements below that say "not verified" or carry `TODO(verify)` predate this run.

## Purpose
The solution shall pass the Microsoft code analyzers: CodeCop, UICop and AppSourceCop (GitHub issue #102). The main app runs all three, locally and in CI. The test app runs CodeCop and UICop locally only; CI does not analyse it (see Test app analysis). PerTenantExtensionCop is not used, because the project delivers in AppSource mode. This feature changes no AL behaviour. It changes analyzer settings, adds an AppSourceCop configuration for the main app, fixes two findings in the test app and records what remains open.

Plan: `docs/plans/FR-061-code-quality-compliance.md` (approved).

## Status
- Branch and files: settings and two test codeunit fixes, not committed at the time of writing.
- No upgrade code, no event, no schema change, no ruleset change, no `app.json` or `test/app.json` change. App version stays 29.0.0.0.
- No user-visible behaviour changed.

## Verification status
- **Local compile (main app):** 0 errors. The only warnings are the exception-register rules listed below. Checked with the local `alc` compiler (version 30.0) against BC 29 symbols.
- **Local compile (test app):** 0 errors, 0 warnings, 0 info, with CodeCop and UICop. The `.app` is produced.
- **Review:** APPROVED.
- **CI (AL-Go Pull Request Build), first run (PR #132, run 43998572748):** the build failed on the test app. With test-app analysis on, AL-Go applied AppSourceCop to the test app and reported AS0015 and AS0054 as errors. Fixed by turning CI test-app analysis off (plan Amendment 2). Not verified: the main-app analyzer lines in the next PR build, and whether that build is green.
- **Tests:** not executed locally (no CLI runner, no sandbox). Not verified: the test suite in CI (V6).

## What changed
| File | Change |
|---|---|
| `app/.vscode/settings.json` | Code analysis on. Analyzers CodeCop, UICop and AppSourceCop. Ruleset `../.AL-Go/equipment.ruleset.json` |
| `test/.vscode/settings.json` | New. Same keys, but CodeCop and UICop only (no AppSourceCop) |
| `.AL-Go/settings.json` | `enableCodeAnalyzersOnTestApps: false`. CI analyses the main app only. (Set to `true` first; turned off after the PR #132 failure.) |
| `app/AppSourceCop.json` | New. Holds `mandatoryAffixes: ["EQM"]` only |
| `test/AppSourceCop.json` | Not created (an earlier untracked copy was deleted). The test app is not analysed by AppSourceCop locally |
| `test/src/EQMEquipmentAPITests.Codeunit.al` | Fix for CodeCop AA0210 (see Diagnostic inventory). Same records, same assertions |
| `test/src/EQMEquipmentPictureTests.Codeunit.al` | Fix for CodeCop AA0477 (see Diagnostic inventory). Same records, same assertions |
| `.AL-Go/equipment.ruleset.json` | Unchanged (byte-identical) |
| `app/app.json`, `test/app.json` | Unchanged |

No `#pragma` was used. No diagnostic was suppressed.

## Diagnostic inventory
### Before
The CI baseline is the latest green CI/CD run on `main`, main app only. Its analyzer lines are:

| Rule | Count | Reported on | Severity | Disposition |
|---|---|---|---|---|
| AS0051 | 5 | `app.json`: privacy statement, EULA, help, logo, context-sensitive help URL | warning | Exception register |
| AS0052 | 1 | `app.json`: url | warning | Exception register |
| AS0081 | 1 | `app.json`: `internalsVisibleTo` | warning | Exception register |
| AS0084 | 1 | `app.json`: ID range | warning | Exception register |
| AS0092 | 1 | `app.json`: Application Insights connection string | warning | Exception register |

The CI baseline has no AA* (CodeCop) and no AW* (UICop) diagnostics.

The test app was not analysed before this feature. A local CodeCop run on the test app before the fixes reported two info diagnostics:

| Rule | File | Line | Message | Fix |
|---|---|---|---|---|
| AA0477 | `EQMEquipmentPictureTests.Codeunit.al` | 6 | Using order | The two `using` lines were swapped (lines 5 and 6) |
| AA0210 | `EQMEquipmentAPITests.Codeunit.al` | 83 | Filter (`SetRange`) on `Description`, which has no key | The filter is now on `"No."` (`SeriesStartTok`). The test asserts `Description` with `AreEqual` instead |

Both fixes keep the same records and the same assertions.

### After
| App | Analyzers (local) | Result |
|---|---|---|
| Main app | CodeCop, UICop, AppSourceCop | 0 errors. Only the 9 warnings of the exception register (below) |
| Test app | CodeCop, UICop | 0 errors, 0 warnings, 0 info |

Info-level output of the main app was not part of the review handoff and is not recorded here.

The main app has no source-level AS* diagnostic. No app has an AA* or AW* diagnostic.

## Exception register
These diagnostics cannot be fixed in this demo portfolio. They are configuration or registration items. Each one has a release step that removes it.

| Rule | App | Where reported | Why it cannot be fixed now | Release step that removes it |
|---|---|---|---|---|
| AS0051 | main | `app/app.json` | Manifest URLs (privacy, EULA, help, url) need real values; `app.json` is on the stop list | Phase 3 |
| AS0052 | main | `app/app.json` | Logo / context-sensitive help values missing; same reason | Phase 3 |
| AS0081 | main | `app/app.json` | `internalsVisibleTo` is required by the test app | Release build without `internalsVisibleTo` |
| AS0084 | main | `app/app.json` | Demo ID range 50100-50149 is not a registered AppSource range | Phase 4 (register range and affix) |
| AS0092 | main | `app/app.json` | No Application Insights connection string | Phase 3 |
| AS0015 | test | `test/app.json(35,3)` | AppSourceCop does not analyse the test app locally, and CI does not analyse it (plan Amendment 2). `test/app.json` stays untouched. Fix is to add `TranslationFile` to `features` in `test/app.json`. PR #132 reported AS0015 as an error when CI analysed the test app | Phase 4, or a later user decision to restore test-app analysis in CI |
| AS0054 | test | `test/` (no `test/AppSourceCop.json`) | Reported in CI on PR #132 when AppSourceCop ran on the test app. Fix is to create `test/AppSourceCop.json` with a mandatory affix. Not created, because the test app is not analysed by AppSourceCop | Same step as AS0015 |

The CI log attributes the individual AS0051 and AS0052 findings to specific manifest properties. Per property: AS0051 covers the privacy statement, EULA, help, logo and context-sensitive help URL. AS0052 covers the url. The register rows above group these by reason.

The test app has no local entries in the register. CodeCop and UICop report nothing on it. CI does not analyse it (plan Amendment 2), so the CI log has no test-app lines.

**The ruleset must be removed before a real AppSource submission.** `.AL-Go/equipment.ruleset.json` lowers some rules to warnings for this demo. Its description says so. FR-061 does not make the app submission ready.

## Test app analysis
The test app is analysed locally by CodeCop and UICop only. AppSourceCop is not run on it locally. Reason: with AppSourceCop on, AS0015 (missing `TranslationFile` feature in `test/app.json`) is an error and stops the test app from packaging. `test/app.json` stays untouched by decision.

In CI, the test app is not analysed. `enableCodeAnalyzersOnTestApps` is `false`. The first PR build with it on (PR #132) failed: AL-Go applied AppSourceCop to the test app, which reported AS0015 and AS0054 as errors. The user chose to turn CI test-app analysis off rather than change `test/app.json` or the ruleset. Restoring it needs `TranslationFile` in `test/app.json` features and a `test/AppSourceCop.json`, then the setting back to `true`. This is Phase 4 or a later user decision.

## Not verified
- **CI run (V4):** answered for the test app. PR #132 (run 43998572748) showed that AL-Go applies AppSourceCop to the test app when test-app analysis is on, and that AS0015 and AS0054 are errors. Test-app analysis is now off. Not verified: that CodeCop, UICop and AppSourceCop run for the main app in the next PR build, and that the build is green.
- **Tests (V6):** the test suite was not executed locally. CI is the first run.
- **Open minor finding (m1):** in `EQMEquipmentAPITests.Codeunit.al`, the `RecordCount = 1` check now runs under a primary-key filter. The earlier check "exactly one record with that description" is gone. An optional fix is to reset, filter on `Description` and keep `RecordCount = 1`. Not changed in this feature.
- **Sandbox:** no sandbox checks apply to this feature. No behaviour changed.

## Events
None published or subscribed.

## Compatibility
Build and repository settings only. No object, field, page, permission or translation change. The translation file is unchanged, because no caption, ToolTip or label changed.

## Related
- `docs/features/FR-048-automated-build-pipeline.md`: the pipeline that runs the analyzers.
- `docs/help/FR-061-code-quality-compliance.md`: contributor help.
- `docs/TODO.md`: open items for AppSource readiness and the CI check (FR-061).
