# AppSource readiness

> Applies to Equipment Management 29.0.0.0 (not released). Facts are taken from the repository on branch feature/FR-060-developer-documentation; nothing is verified in a Business Central sandbox.

**Not ready for submission.** The manifest has no privacy statement, EULA, help, url or logo, the object ID range and the affix are not registered with Microsoft, the app is not signed, and nothing was published or tested in a Business Central environment.

This page maps every requirement of the Microsoft technical validation checklist to the state of this repository. The checklist was read on Microsoft Learn on 2026-11-22 ([Technical validation](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-checklist-submission)). The Learn page is the reference. The copy of the checklist in the project material is dated 2026-02-26 and is older (`docs/TODO.md`, "AppSource FAILs"). No separate AppSource validation ran; the statuses below come from reading the repository.

**In this article**
- [Checklist status](#checklist-status)
- [Release steps that close the open items](#release-steps-that-close-the-open-items)
- [How to self-validate](#how-to-self-validate)
- [Related](#related)

## Checklist status

Status values: **Met** (in the repository), **Partial**, **Open** (not done), **Not done** (needs an environment), **Not applicable**. "Met in code" means the repository satisfies the requirement, and no sandbox check has confirmed it.

| Checklist requirement (Microsoft Learn) | Status | Evidence | Next step |
|---|---|---|---|
| Develop the extension in Visual Studio Code | Met | AL project with `.vscode/settings.json` in `app/` and `test/` | None |
| `app.json` mandatory properties (`name`, `publisher`, `version` must match the offer) | Open | `privacyStatement`, `EULA`, `help`, `url` and `logo` are empty in `app/app.json`; `screenshots` is empty; `supportedLocales` and `contextSensitiveHelpUrl` are not set. No offer exists yet, so name, publisher and version are not compared | Set the values (needs real URLs and a logo file; stop list in `CLAUDE.md`, user decision). Create the offer in Partner Center |
| Dates use the format `yyyymmddD` | Met | No date literal in `app/src` (grep of `[0-9]{6,8}D`) | None |
| Remote services use `HttpRequest` only | Met | No `HttpClient` or `HttpRequest` in `app/src`; the app makes no HTTP call | Re-check when an integration is added |
| Only JavaScript control add-ins | Not applicable | No `controladdin` object in `app/src` | None |
| `.app` file digitally signed | Open | The AL-Go build call passes `signArtifacts: true` and reads the secrets `codeSignCertificateUrl` and `codeSignCertificatePassword`. The repository holds no evidence that they are configured, so no signed package is known | Configure signing and check the signed package ([Sign an APP package file](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-sign-extension)) |
| Application areas set on controls | Partial | All pages except the four API pages (50123 to 50126) set `ApplicationArea`. The FR-034 validation report noted the same four pages, and the grep on this branch still shows them without it. API pages show no UI; whether validation accepts this is not verified | Confirm with a validation run; add `ApplicationArea` only if it asks for it (FR-026 convention C3) |
| Permission sets created by the extension; no SUPER needed | Met in code | Five permission sets and one extension in `app/src/Permissions`; the structure is tested by codeunit 50162 (part of CI/CD run 44925652127, 569 passed). Enforcement for a non-SUPER user is not verified | Run the sandbox checks OP-SB1 to OP-SB8 and the FR-036 scenarios (`docs/TODO.md`) |
| Publish, sync, install, uninstall and reinstall in a Business Central environment | Not done | `al_publish` is not used by agents; CI publishes to a container only for tests | Do it in a sandbox, including a reinstall over retained data (FR-044) |
| Thoroughly test in a Business Central environment | Not done | Tests run only in the AL-Go container: CI/CD run 44925652127 on `main`, 569 tests, 569 passed. No manual sandbox test of any feature | Walk through the sandbox checks in `docs/TODO.md` |
| Do not use `OnBeforeCompanyOpen` or `OnAfterCompanyOpen` | Met | `grep -rn "OnBeforeCompanyOpen\|OnAfterCompanyOpen" app/src` returns no match (run on 2026-11-22) | None |
| Proper upgrade code from version to version | Met | Install codeunit 50104, upgrade codeunit 50134, steps in 50139 with upgrade tags (FR-044, FR-054). Every release after 29.0.0.0 needs a step | Add a step for each data change before a release |
| Web service pages and codeunits generate no UI that raises an exception in the caller | Met in code | FR-026 decision: confirmations default to Yes without UI (`ConfirmManagement.GetResponseOrDefault` in the equipment table); `GuiAllowed()` guards the notification and demo data code. The API pages raise an error when the feature is off, which is a normal error response. Not exercised through HTTP | Sandbox checks of the API (`docs/TODO.md`, FR-026 to FR-028) |
| Affix registered and used | Partial | `EQM` is on every object name and every added member, and `app/AppSourceCop.json` enforces it (`mandatoryAffixes`). It is not registered with Microsoft | Register the affix for the publisher name |
| Object ID range registered and used | Open | 50100 to 50149 is a demo range; AS0084 is lowered to a warning in `.AL-Go/equipment.ruleset.json` | Request a range, change `idRanges`, renumber, remove the ruleset entry (stop list) |
| Automated testing (recommended) | Met | Test app with 569 tests; run 44925652127 passed. FR-047 coverage targets are report-only (`enforce` false) | Close the coverage gaps (FR-047 phase 2) |
| `DataClassification` on all fields, not `ToBeClassified` | Met | No `ToBeClassified` in `app/src`; every table and field classified (FR-058); test codeunit 50163 is part of CI/CD run 44925652127 | None |
| Profile object instead of inserting into the Profiles table | Met | `profile "EQM EQUIPMENT MANAGER"` in `app/src/Dashboard`; no use of the `All Profile` table | None |
| `addfirst` and `addlast` for placing actions | Partial | Actions use `addlast` (Employee Card, `Navigation` and `Processing`) and the FactBox uses `addfirst`. One layout field in pageextension 50101 uses `addafter(Name)` | Decide whether the field needs another anchor; the checklist names actions |
| Not a runtime package | Not verified | CI builds normal packages with `AL-Go`; no runtime package step exists | Check the delivered file |
| Translation files used | Met in code | `TranslationFile` feature, `.g.xlf` plus pt-PT and es-ES (FR-055). Native-speaker review is open. The test app has no `TranslationFile` feature (AS0015 for the test app) | Native review; see test-app item below |
| `application` property set | Met | `"application": "29.0.0.0"`; no dependency on Base Application or System Application | None |
| Unique `AppId` | Met in repo | `e6c30407-ec71-4f48-a790-70da80abc992` | Confirm in Partner Center that it is unique |
| AppSourceCop clean | Partial | FR-061: 0 errors on the main app, and warnings for the exception register AS0051, AS0052, AS0081, AS0084 and AS0092. The ruleset lowers AS0051, AS0052 and AS0084 to warnings and must be removed before submission. No baseline exists until the first release, and FR-062 (breaking change validation) is not built | Remove the ruleset; close the manifest items; create the first release |
| Telemetry `applicationInsightsConnectionString` (AS0092) | Open | Not set in `app/app.json` | Set it (stop list) |
| `resourceExposurePolicy` reviewed | Open | `allowDebugging`, `allowDownloadingSource` and `includeSourceInSymbolFile` are all `true` | Review and decide |
| Analyzers on the test app in CI | Off | `enableCodeAnalyzersOnTestApps` is `false` in `.AL-Go/settings.json` after PR #132 failed (AS0015, AS0054). CodeCop and UICop run on the test app locally | Add `TranslationFile` to `test/app.json` and a `test/AppSourceCop.json`, then switch the setting back (user decision) |

## Release steps that close the open items

The steps are tracked in [`docs/TODO.md`](../TODO.md), section "AppSource FAILs", and in the feature docs:

- Manifest properties, `supportedLocales` and the Application Insights connection string: Phase 3 of the exception register in [FR-061](../features/FR-061-code-quality-compliance.md).
- Register the affix and a real ID range, remove the CI ruleset, restore test-app analysis: Phase 4 of the same register.
- Review of `resourceExposurePolicy`: listed in `docs/TODO.md` with no phase assigned.
- Version, release creation and upgrade checklist: [FR-049](../features/FR-049-release-management.md). No release exists yet.
- Pipeline and analyzers: [FR-048](../features/FR-048-automated-build-pipeline.md).
- Digital signature and the match with the Partner Center offer (release steps).

## How to self-validate

- **`Run-AlValidation`** from `BcContainerHelper` runs the same technical validation as the Marketplace. It needs Docker and Windows, so it does not run on macOS. See the Learn page above.
- **AL-Go pull request builds** compile the app, run CodeCop, UICop and AppSourceCop on the main app, and run the tests (see [CI/CD](../setup/ci-cd.md)). They are not the Marketplace validation and have no baseline.
- Before a submission, re-read the Learn checklist: it changes over time.

## Related

- [CI/CD process](../setup/ci-cd.md), [Testing strategy](testing-strategy.md)
- [`docs/TODO.md`](../TODO.md)
- Feature docs: [FR-048](../features/FR-048-automated-build-pipeline.md), [FR-049](../features/FR-049-release-management.md), [FR-061](../features/FR-061-code-quality-compliance.md)
- Microsoft Learn: [Technical validation](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-checklist-submission), [AppSourceCop analyzer](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/appsourcecop)
