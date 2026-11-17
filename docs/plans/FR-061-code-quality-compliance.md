# FR-061 Code Quality Compliance: plan

> Status: approved (Option A chosen by the user; reviewer finding B1 resolved by user decision: AppSourceCop is not run on the test app locally; pipeline continues without a separate plan approval).

Request (verbatim): "FR-061 Code Quality Compliance"

GitHub issue #102: The solution shall pass CodeCop, UICop and AppSourceCop. Business value: demonstrates AppSource readiness. PerTenantExtensionCop is intentionally left out because the project delivers in AppSource mode.

Target: AppSource. Decision from the user: Option A. Amendment (B1): AppSourceCop runs locally on the main app only. The test app runs CodeCop and UICop.

## Amendment 2 (CI finding)
The first AL-Go Pull Request Build (PR #132, run 43998572748) failed on the test app. With `enableCodeAnalyzersOnTestApps` and `enableAppSourceCop` both true, AL-Go applies AppSourceCop to the test app. It reported two errors: AS0015 (`TranslationFile` missing from `test/app.json` features) and AS0054 (no `test/AppSourceCop.json`, so no mandatory affix is configured). This answers V4 for the question of whether AL-Go applies AppSourceCop to the test app: it does.

User decision: CI analysis of the test app is turned off. `.AL-Go/settings.json` has `"enableCodeAnalyzersOnTestApps": false`. `test/app.json` and `test/AppSourceCop.json` stay as they are (no change, file not created).

Effects:
- CI analyses the main app only: CodeCop, UICop and AppSourceCop.
- The test app is analysed locally by CodeCop and UICop only, as before. This is the same as before FR-061 for CI.
- Step 3 (setting `true`), the Step 11 test-app check, Risk 2, Risk 3 and the CI parts of the analyzer-scope decision are superseded by this amendment.

Restoring CI coverage of the test app needs `TranslationFile` in `test/app.json` features and `test/AppSourceCop.json`. This is Phase 4 or a later user decision. After that, `enableCodeAnalyzersOnTestApps` goes back to `true`.

## Request summary
Make the main app pass CodeCop, UICop and AppSourceCop, and the test app pass CodeCop and UICop. Both apps must have zero analyzer errors and zero warnings that come from source code, locally and in CI. Configuration and registration diagnostics that cannot be fixed in a demo portfolio go into a named, documented exception register.

## Definition of done
- [ ] `app/.vscode/settings.json` turns code analysis on (`al.enableCodeAnalysis: true`), lists `${CodeCop}`, `${UICop}` and `${AppSourceCop}`, and points `al.ruleSetPath` at the existing `.AL-Go/equipment.ruleset.json`. `test/.vscode/settings.json` has the same keys but lists only `${CodeCop}` and `${UICop}` (no `${AppSourceCop}`), and has the same `al.ruleSetPath`.
- [ ] `.AL-Go/settings.json` has `"enableCodeAnalyzersOnTestApps": false` (Amendment 2). CI analyses the main app only.
- [ ] `app/AppSourceCop.json` exists, holding only `mandatoryAffixes: ["EQM"]`. `test/AppSourceCop.json` does not exist.
- [ ] `app/` compiles with 0 errors. Its only warnings are exception-register rules (AS0051, AS0052, AS0081, AS0084, AS0092).
- [ ] `test/` compiles with 0 errors and 0 warnings and produces a `.app`. CodeCop and UICop report nothing, so the test app has no local entries in the exception register. AS0015 does not appear locally because AppSourceCop does not analyse the test app.
- [ ] No app has an AA* (CodeCop) or AW* (UICop) diagnostic. The main app has no source-level AS* diagnostic. The test app is not analysed by AppSourceCop locally.
- [ ] No `#pragma`, no new or changed ruleset rule, no change to `app.json` or `test/app.json`; `.AL-Go/equipment.ruleset.json` is byte-identical.
- [ ] AL behaviour is unchanged: nothing renamed, retyped or removed; no test changes what it asserts.
- [ ] The AL-Go PR build after the Amendment 2 fix shows CodeCop, UICop and AppSourceCop running for "Equipment Management" with only exception-register diagnostics, and the build is green. No analyzers run for "Equipment Management Tests" (Amendment 2). The first run (PR #132) is recorded under V4.
- [ ] Docs exist and `repo_checks.py` passes: this plan, `docs/features/FR-061-code-quality-compliance.md` (diagnostic inventory and exception register), `docs/help/FR-061-code-quality-compliance.md`, a `## FR-061 Code Quality Compliance` section in `CHANGELOG.md`, and `docs/TODO.md` line 172 updated.
- [ ] `app/Translations/Equipment Management.g.xlf` is regenerated only if caption, ToolTip or label text changed.

## Out of scope
- Manifest values in `app.json` (privacyStatement, EULA, help, url, logo, contextSensitiveHelpUrl, applicationInsightsConnectionString). Need real URLs and an Application Insights resource; `app.json` edits are on the stop list. Phase 3.
- A registered ID range and affix (AS0084). Release step needing Microsoft registration.
- Removing `internalsVisibleTo` (AS0081). Would break the test app.
- Adding the `TranslationFile` feature to `test/app.json` (AS0015). `test/app.json` stays untouched by user decision; this is a release step (phase 4) or a later user decision if test-app analysis in CI is restored (Amendment 2).
- Running AppSourceCop on the test app locally (user decision, B1).
- Any change to ruleset content or the analyzer set of the target.
- `failOn: "newWarning"` in AL-Go. Phase 2.
- An AppSourceCop baseline. No release exists yet.
- Test-quality findings that are not analyzer diagnostics.
- Editing AL-Go workflow YAML (system files).

## Objects
This plan creates no AL objects. No IDs allocated. Steps 6 and 7 may produce source fixes inside existing objects; the developer lists every touched file. Test-app source fixes for AA0210 and AA0477 are already done in `test/src/EQMEquipmentAPITests.Codeunit.al` and `test/src/EQMEquipmentPictureTests.Codeunit.al` (see step 7).

| Type | Name | New/Changed | File |
|---|---|---|---|
| VS Code settings | app folder settings | Changed | `app/.vscode/settings.json` |
| VS Code settings | test folder settings | New (CodeCop + UICop only) | `test/.vscode/settings.json` |
| AL-Go settings | project settings | Changed | `.AL-Go/settings.json` |
| AppSourceCop config | app | New | `app/AppSourceCop.json` |
| AppSourceCop config | test app | Not created (deleted if present) | `test/AppSourceCop.json` |
| Test codeunit | EQM Equipment API Tests | Changed (AA0210 fix, done) | `test/src/EQMEquipmentAPITests.Codeunit.al` |
| Test codeunit | EQM Equipment Picture Tests | Changed (AA0477 fix, done) | `test/src/EQMEquipmentPictureTests.Codeunit.al` |
| Docs | plan, feature doc, help, changelog, TODO, FR-048 docs | New/Changed | `docs/...`, `CHANGELOG.md` |

## Events and standard symbols
None used. The AL MCP server failed to connect during planning, so `al_symbolsearch`, `al_getnextobjectid`, `al_compile` and `al_getdiagnostics` were not available.

## Steps
0. Main agent, read-only (`gh`): get the CI analyzer baseline for the main app from the latest successful `CICD.yaml` run on `main`, extract lines matching `(warning|error) (AA|AW|AS|AL)[0-9]{4}`, and give the list to the developer and docs agent. No files change.
1. `app/.vscode/settings.json`: replace the content with `"al.enableCodeAnalysis": true`, `"al.codeAnalyzers": ["${CodeCop}", "${UICop}", "${AppSourceCop}"]`, `"al.ruleSetPath": "../.AL-Go/equipment.ruleset.json"`, keeping the existing 4-space indent. Learn documents `al.enableCodeAnalysis` with default `false`; ALTool reads only these three keys from `.vscode/settings.json`.
2. `test/.vscode/settings.json`: exactly three keys, 4-space indent: `"al.enableCodeAnalysis": true`, `"al.codeAnalyzers": ["${CodeCop}", "${UICop}"]` and `"al.ruleSetPath": "../.AL-Go/equipment.ruleset.json"`. Remove the `"${AppSourceCop}"` entry from the current file. Do not touch `test/.vscode/launch.json` or `test/.vscode/rad.json`. Why: with AppSourceCop on, AS0015 (missing `TranslationFile` feature in `test/app.json`) is reported as an error, alc produces no `.app`, and `test/app.json` must not change (user decision, B1).
3. `.AL-Go/settings.json`: add `"enableCodeAnalyzersOnTestApps": true` as the last property, after `"enableAppSourceCop": true`. Validate with `python3 -m json.tool`. Superseded by Amendment 2: the value is `false`.
4. `app/AppSourceCop.json` (new), exact content `{ "mandatoryAffixes": [ "EQM" ] }` (multi-line formatting accepted). No other property.
5. `test/AppSourceCop.json`: delete the file (it exists untracked from an earlier run). Do not create it again. Effect:
   - Locally nothing reads it, because AppSourceCop no longer analyses the test app.
   - In CI, if AL-Go applies AppSourceCop to the test app, the only loss is the EQM affix check there. Its absence cannot add diagnostics. It also does not stop AS0015 (see Risk 2). Amendment 2: in CI it does cause AS0054 when AppSourceCop runs on the test app, which is why CI no longer analyses the test app.
   - The main app keeps `app/AppSourceCop.json` (Option A).
6. `app/`: compile and read diagnostics (AL MCP, or the local alc fallback). Tabulate every diagnostic (rule, severity, file:line, message) and tag it exception-register or defect. Fix every defect with one coherent edit per object file:
   - AA0137 / AA0228 (unused variable or local procedure): remove it.
   - AA0021 / AA0072 / AA0074 / AA0470 (order, naming, label suffix, placeholder Comment): rename or reorder local variables or labels, or add the Comment. Regenerate the XLIFF; AS0125 at Info level is expected.
   - Missing ToolTip, Caption, ApplicationArea or DataClassification: add the property in the existing style of the object.
   - AA0139, AA0205 or similar: minimal fix that keeps behaviour, e.g. `CopyStr(..., 1, MaxStrLen(...))`.
   - Return BLOCKED if a fix would:
     - rename, retype or remove an object, field, public procedure, event, enum value or permission set (the AS0011/AS0079 affix case included);
     - change `app.json`;
     - add a pragma or ruleset rule;
     - or change behaviour.
   - Never suppress a diagnostic.
   Repeat until only exception-register diagnostics remain.
7. `test/`: same procedure after `app/` compiles, with CodeCop and UICop only.
   - **Already done:** the AA0210 and AA0477 source fixes in `test/src/EQMEquipmentAPITests.Codeunit.al` and `test/src/EQMEquipmentPictureTests.Codeunit.al`. Keep them; do not redo them. The developer lists each changed line (rule, file:line, before and after) in the handoff. The reviewer confirms that neither change alters what a test asserts or the data it creates.
   - **Then:** compile `test/` again. The target is 0 errors, 0 warnings and a produced `.app`. Any further CodeCop or UICop defect is fixed under the same rules as step 6. Fixes must not change what a test asserts or the data it creates.
8. If any caption, ToolTip or label text changed, build `app/` so `app/Translations/Equipment Management.g.xlf` is regenerated and include it in the diff.
9. Docs (al-docs):
   - Feature doc, containing:
     - the diagnostic inventory before and after, including the two test-app fixes AA0210 and AA0477;
     - the exception register exactly as in the "Exception register" section below;
     - the statement that the test app is analysed locally by CodeCop and UICop only.
   - A short contributor help article.
   - The `## FR-061 Code Quality Compliance` changelog section (version stays 29.0.0.0).
   - Update `docs/TODO.md` line 172 and mention FR-061 near lines 165 and 169.
   - Update the FR-048 feature doc and help, which say analyzers run on the main app only. They should now say: main app CodeCop + UICop + AppSourceCop in CI and locally; test app CodeCop + UICop locally only; CI does not analyse the test app (Amendment 2).
10. Plan header `> Status:` must not contain DRAFT or "waiting for approval" once approved (repo check 3).
11. After the user asks to push, the main agent reads the PR build log as in step 0. It confirms:
    - CodeCop, UICop and AppSourceCop ran for "Equipment Management";
    - CodeCop and UICop ran for "Equipment Management Tests";
    - only exception-register diagnostics appear.
    Amendment 2: the test app is no longer analysed in CI, so the test-app check no longer applies. The PR #132 result (AS0015 and AS0054 as errors) is recorded in the feature doc.

## Exception register
| Rule | App | Where reported | Why it cannot be fixed now | Release step that removes it |
|---|---|---|---|---|
| AS0051 | main | `app/app.json` | Manifest URLs (privacy, EULA, help, url) need real values; `app.json` is on the stop list | Phase 3 |
| AS0052 | main | `app/app.json` | Logo / context-sensitive help values missing; same reason | Phase 3 |
| AS0081 | main | `app/app.json` | `internalsVisibleTo` is required by the test app | Release build without `internalsVisibleTo` |
| AS0084 | main | `app/app.json` | Demo ID range 50100-50149 is not a registered AppSource range | Phase 4 (register range and affix) |
| AS0092 | main | `app/app.json` | No Application Insights connection string | Phase 3 |
| AS0015 | test | `test/app.json(35,3)` | AppSourceCop does not analyse the test app locally (user decision, B1), and CI no longer analyses it (Amendment 2, after PR #132 reported AS0015 as an error). `test/app.json` stays untouched. Fix is to add `TranslationFile` to `features` in `test/app.json` | Phase 4, or a later user decision to restore test-app analysis in CI |
| AS0054 | test | `test/` (no `test/AppSourceCop.json`) | Reported in CI on PR #132 when AppSourceCop ran on the test app. Fix is to create `test/AppSourceCop.json` with a mandatory affix. Not created because the test app is not analysed by AppSourceCop locally (B1) | Same step as AS0015 (Phase 4, or the later decision above) |

The test app has no local entries in the register: CodeCop and UICop report nothing on it after step 7. CI does not analyse the test app (Amendment 2), so no CI diagnostics on it are listed. If test-app analysis is restored in CI, check the rules the CI log reports for `test/app.json` and add them here. The earlier test-manifest entries (AS0051, AS0052, AS0084, AS0092 on `test/app.json`) are not listed, because the test app is not analysed by AppSourceCop.

The ruleset's description says it must be removed before a real AppSource submission. The register repeats this, so FR-061 is not read as "submission ready".

## Tests
No business rule changes, so no new AL test codeunit. Verification by build:
- V1 clean main app: after steps 1 to 6, compiling `app/` gives 0 errors and only exception-register warnings.
- V2 clean test app: after step 7, compiling `test/` (CodeCop + UICop, no AppSourceCop) gives 0 errors, 0 warnings, and produces the test `.app`. To show the analyzers really ran, the step 7 handoff must show that CodeCop had reported AA0210 and AA0477 on the test app before the fixes.
- V3 analyzers really run on the main app (negative control): at least AS0084 must be reported for `app/`. If no AS diagnostic appears, the result does not count as clean.
- V4 CI covers the main app: the Pull Request Build log shows the analyzers for "Equipment Management" (CodeCop, UICop, AppSourceCop) with only exception-register diagnostics, and the build is green. Test-app analysis in CI is off (Amendment 2). Result of the first run: PR #132, run 43998572748, build failed on the test app. AL-Go applied AppSourceCop to it and reported AS0015 and AS0054 as errors. Still pending: the main-app analyzer lines and a green build in the next PR build after the fix.
- V5 no suppression: no `#pragma`; ruleset, `app.json` and `test/app.json` unchanged; `test/.vscode/settings.json` has no `${AppSourceCop}`; `test/AppSourceCop.json` absent.
- V6 behaviour preserved: existing test suite in CI (codeunits 50162 and 50178 to 50193) has 0 failures. This covers the AA0210/AA0477 edits in `EQMEquipmentAPITests` and `EQMEquipmentPictureTests`. Locally: `Not verified: tests not executed (no CLI runner)`.

## Assumptions
- Assumed the source was already almost clean under CodeCop and UICop because earlier feature docs report 0 warnings. This was unproven because `al.enableCodeAnalysis` was never set. For the test app it proved wrong: AA0210 and AA0477 were found and fixed.
- AL-Go applies `rulesetFile` to test apps too. Not verified: CI no longer analyses the test app (Amendment 2), so this cannot be checked in CI.
- `al.ruleSetPath` accepts `../` outside the project folder.
- Assumed AL-Go may or may not run AppSourceCop on test apps when both `enableAppSourceCop` and `enableCodeAnalyzersOnTestApps` are true. Settled by PR #132 (run 43998572748): AL-Go does run AppSourceCop on the test app in that case.
- The issue's "DELIVERY_MODE" means the CLAUDE.md Target row (AppSource).

## DECISIONS
- FR-061 analyzer scope | Analyzers on both app and test app (locally and in CI via `enableCodeAnalyzersOnTestApps`) over main app only. CI part superseded by the next line (Amendment 2) | Reversible: yes
- FR-061 CI test-app analysis (Amendment 2, user decision) | `enableCodeAnalyzersOnTestApps` is `false`. CI analyses the main app only. Restoring needs `TranslationFile` in `test/app.json` and `test/AppSourceCop.json`, then the setting back to `true` | Reversible: yes
- FR-061 test-app AppSourceCop locally (B1, user decision) | Test app runs CodeCop + UICop only locally, over adding `TranslationFile` to `test/app.json`, because `test/app.json` stays untouched and AS0015 at error severity otherwise stops the test app from packaging | Reversible: yes
- FR-061 local severity parity | `al.ruleSetPath` points at the existing `.AL-Go/equipment.ruleset.json` for both apps | Reversible: yes
- FR-061 enable code analysis explicitly | `al.enableCodeAnalysis: true` in folder settings, because the default is false and the AL MCP server reads only folder settings | Reversible: yes
- FR-061 regression gate | Defer `failOn: "newWarning"` to phase 2 | Reversible: yes
- FR-061 manifest diagnostics | Documented exception register over placeholder URLs in `app.json` | Reversible: yes
- FR-061 AppSourceCop.json | User chose Option A: `app/AppSourceCop.json` with `mandatoryAffixes: ["EQM"]`. Amended for B1: delete `test/AppSourceCop.json` rather than keep it, because nothing reads it locally and keeping it would suggest AppSourceCop analyses the test app. In CI the only effect is no EQM affix check on the test app, if AL-Go runs AppSourceCop there | Reversible: yes

## Risks
1. Neither app was compiled during planning, so the real defect list is unknown. If steps 6 and 7 find more than about 30 source defects, split into a follow-up phase per folder.
2. Happened, resolved by Amendment 2. PR #132 (run 43998572748) failed on the test app: with `enableCodeAnalyzersOnTestApps` and `enableAppSourceCop` both true, AL-Go applied AppSourceCop and AS0015 and AS0054 were errors. The user turned CI test-app analysis off. The ruleset was not changed and `test/app.json` was not changed. Restoring test-app analysis in CI needs the user's decision on `"TranslationFile"` in `features` in `test/app.json` (on the stop list) and on `test/AppSourceCop.json`.
3. Deleting `test/AppSourceCop.json` means AS0054 is reported whenever AppSourceCop runs on the test app. This happened in PR #132. CI no longer analyses the test app (Amendment 2), so nothing fails now. Locally nothing runs AppSourceCop on the test app. `test/AppSourceCop.json` must exist again before CI analyses the test app.
4. Label renames for AA0074 change XLIFF trans-unit IDs (AS0125, Info). The reviewer checks the `.g.xlf` diff contains only renamed IDs.
5. Affix fixes (AS0011/AS0079) on existing members would be renames. Escalate; never do silently.
6. The AA0210 and AA0477 fixes in the two test codeunits were done before this amendment. The reviewer checks they keep the same filters, the same records created and the same assertions. V6 in CI is the behavioural check.
7. Mismatches: the issue mentions "DELIVERY_MODE" (no longer in CLAUDE.md); CLAUDE.md mentions an `AppSourceCop.json` baseline that did not exist; `DECISIONS.md` does not exist yet; FR-048 docs say analyzers run on the main app only.
8. The ruleset's description says it must be removed before a real AppSource submission. The exception register must repeat this so FR-061 is not read as "submission ready".

## Later phases
- Phase 2: `failOn: "newWarning"` in `.AL-Go/settings.json` after the first green main-app build (Amendment 2: CI analyses the main app only).
- Phase 3: real URLs, logo and Application Insights connection string in the `app.json` manifest to clear AS0051, AS0052, AS0092.
- Phase 4 (release): register the ID range and affix, update `idRanges`, remove the ruleset and `rulesetFile`, add the AppSourceCop baseline, add `TranslationFile` to `test/app.json` features (AS0015), and add `test/AppSourceCop.json` (AS0054). Then set `enableCodeAnalyzersOnTestApps` back to `true` so CI analyses the test app again (Amendment 2).
